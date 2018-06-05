//
//  GameModel.swift
//  swift-2048
//
//  Created by Austin Zheng on 6/3/14.
//  Copyright (c) 2014 Austin Zheng. Released under the terms of the MIT license.
//

import UIKit

/// A protocol that establishes a way for the game model to communicate with its parent view controller.
protocol GameModelProtocol : class {
  func scoreChanged(to score: Int)
  func moveOneTile(from: (Int, Int), to: (Int, Int), value: Int)
  func moveTwoTiles(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int)
  func insertTile(at location: (Int, Int), withValue value: Int)
}

/// A class representing the game state and game logic for swift-2048. It is owned by a NumberTileGame view controller.
class GameModel : NSObject {
  let dimension : Int
  let threshold : Int

  var score : Int = 0 {
    didSet {
      delegate.scoreChanged(to: score)
    }
  }
  var gameboard: SquareGameboard<TileObject>
    
  var highScore = UserDefaults().integer(forKey: "HIGHSCORE")

  var continueGame = false // Won the game but want to continue
    
  unowned let delegate : GameModelProtocol

  var queue: [MoveCommand]
  var timer: Timer

  let maxCommands = 100
  let queueDelay = 0.3

  init(dimension d: Int, threshold t: Int, delegate: GameModelProtocol) {
    dimension = d
    threshold = t
    self.delegate = delegate
    queue = [MoveCommand]()
    timer = Timer()
    gameboard = SquareGameboard(dimension: d, initialValue: .empty)
    super.init()
  }

  /// Reset the game state.
  func reset() {
    score = 0
    gameboard.setAll(to: .empty)
    queue.removeAll(keepingCapacity: true)
    timer.invalidate()
  }

  /// Order the game model to perform a move (because the user swiped their finger). The queue enforces a delay of a few
  /// milliseconds between each move.
  func queueMove(direction: MoveDirection, onCompletion: @escaping (Bool) -> ()) {
    guard queue.count <= maxCommands else {
      // Queue is wedged. This should actually never happen in practice.
      return
    }
    queue.append(MoveCommand(direction: direction, completion: onCompletion))
    if !timer.isValid {
      // Timer isn't running, so fire the event immediately
      timerFired(timer)
    }
  }

  //------------------------------------------------------------------------------------------------------------------//

  /// Inform the game model that the move delay timer fired. Once the timer fires, the game model tries to execute a
  /// single move that changes the game state.
  @objc func timerFired(_: Timer) {
    if queue.count == 0 {
      return
    }
    // Go through the queue until a valid command is run or the queue is empty
    var changed = false
    while queue.count > 0 {
      let command = queue[0]
      queue.remove(at: 0)
      changed = performMove(direction: command.direction)
      command.completion(changed)
      if changed {
        // If the command doesn't change anything, we immediately run the next one
        break
      }
    }
    if changed {
      timer = Timer.scheduledTimer(timeInterval: queueDelay,
        target: self,
        selector:
        #selector(GameModel.timerFired(_:)),
        userInfo: nil,
        repeats: false)
    }
  }

  //------------------------------------------------------------------------------------------------------------------//

  /// Insert a tile with a given value at a position upon the gameboard.
  func insertTile(at location: (Int, Int), value: Int) {
    let (x, y) = location
    if case .empty = gameboard[x, y] {
      gameboard[x, y] = TileObject.tile(value)
      delegate.insertTile(at: location, withValue: value)
    }
  }

  /// Insert a tile with a given value at a random open position upon the gameboard.
  func insertTileAtRandomLocation(withValue value: Int) {
    let openSpots = gameboardEmptySpots()
    if openSpots.isEmpty {
      // No more open spots; don't even bother
      return
    }
    // Randomly select an open spot, and put a new tile there
    let idx = Int(arc4random_uniform(UInt32(openSpots.count-1)))
    let (x, y) = openSpots[idx]
    insertTile(at: (x, y), value: value)
  }

  /// Return a list of tuples describing the coordinates of empty spots remaining on the gameboard.
  func gameboardEmptySpots() -> [(Int, Int)] {
    var buffer : [(Int, Int)] = []
    for i in 0..<dimension {
      for j in 0..<dimension {
        if case .empty = gameboard[i, j] {
          buffer += [(i, j)]
        }
      }
    }
    return buffer
  }

  //------------------------------------------------------------------------------------------------------------------//

  func tileBelowHasSameValue(location: (Int, Int), value: Int) -> Bool {
    let (x, y) = location
    guard y != dimension - 1 else {
      return false
    }
    if case let .tile(v) = gameboard[x, y+1] {
      return v == value
    }
    return false
  }

  func tileToRightHasSameValue(location: (Int, Int), value: Int) -> Bool {
    let (x, y) = location
    guard x != dimension - 1 else {
      return false
    }
    if case let .tile(v) = gameboard[x+1, y] {
      return v == value
    }
    return false
  }

  func userHasLost() -> Bool {
    guard gameboardEmptySpots().isEmpty else {
      // Player can't lose before filling up the board
      return false
    }

    // Run through all the tiles and check for possible moves
    for i in 0..<dimension {
      for j in 0..<dimension {
        switch gameboard[i, j] {
        case .empty:
          assert(false, "Gameboard reported itself as full, but we still found an empty tile. This is a logic error.")
        case let .tile(v):
          if tileBelowHasSameValue(location: (i, j), value: v) ||
            tileToRightHasSameValue(location: (i, j), value: v)
          {
            return false
          }
        }
      }
    }
    return true
  }

  func userHasWon() -> (Bool, (Int, Int)?) {
    for i in 0..<dimension {
      for j in 0..<dimension {
        // Look for a tile with the winning score or greater
        if case let .tile(v) = gameboard[i, j], v >= threshold {
          return (true, (i, j))
        }
      }
    }
    return (false, nil)
  }

  //------------------------------------------------------------------------------------------------------------------//

  // Perform all calculations and update state for a single move.
  func performMove(direction: MoveDirection) -> Bool {
    // Prepare the generator closure. This closure differs in behavior depending on the direction of the move. It is
    // used by the method to generate a list of tiles which should be modified. Depending on the direction this list
    // may represent a single row or a single column, in either direction.
    let coordinateGenerator: (Int) -> [(Int, Int)] = { (iteration: Int) -> [(Int, Int)] in
      var buffer = Array<(Int, Int)>(repeating: (0, 0), count: self.dimension)
      for i in 0..<self.dimension {
        switch direction {
        case .up: buffer[i] = (i, iteration)
        case .down: buffer[i] = (self.dimension - i - 1, iteration)
        case .left: buffer[i] = (iteration, i)
        case .right: buffer[i] = (iteration, self.dimension - i - 1)
        }
      }
      return buffer
    }

    var atLeastOneMove = false
    for i in 0..<dimension {
      // Get the list of coords
      let coords = coordinateGenerator(i)

      // Get the corresponding list of tiles
      let tiles = coords.map() { (c: (Int, Int)) -> TileObject in
        let (x, y) = c
        return self.gameboard[x, y]
      }

      // Perform the operation
      let orders = merge(tiles)
      atLeastOneMove = orders.count > 0 ? true : atLeastOneMove

      // Write back the results
      for object in orders {
        switch object {
        case let MoveOrder.singleMoveOrder(s, d, v, wasMerge):
          // Perform a single-tile move
          let (sx, sy) = coords[s]
          let (dx, dy) = coords[d]
          if wasMerge {
            score += v
            if score > highScore{
                UserDefaults.standard.set(score, forKey: "HIGHSCORE")
            }

          }
          gameboard[sx, sy] = TileObject.empty
          gameboard[dx, dy] = TileObject.tile(v)
          delegate.moveOneTile(from: coords[s], to: coords[d], value: v)
        case let MoveOrder.doubleMoveOrder(s1, s2, d, v):
          // Perform a simultaneous two-tile move
          let (s1x, s1y) = coords[s1]
          let (s2x, s2y) = coords[s2]
          let (dx, dy) = coords[d]
          score += v
          gameboard[s1x, s1y] = TileObject.empty
          gameboard[s2x, s2y] = TileObject.empty
          gameboard[dx, dy] = TileObject.tile(v)
          delegate.moveTwoTiles(from: (coords[s1], coords[s2]), to: coords[d], value: v)
        }
      }
    }
    return atLeastOneMove
  }

  //------------------------------------------------------------------------------------------------------------------//

  /// When computing the effects of a move upon a row of tiles, calculate and return a list of ActionTokens
  /// corresponding to any moves necessary to remove interstital space. For example, |[2][ ][ ][4]| will become
  /// |[2][4]|.
  func condense(_ group: [TileObject]) -> [ActionToken] {
    var tokenBuffer = [ActionToken]()
    for (idx, tile) in group.enumerated() {
      // Go through all the tiles in 'group'. When we see a tile 'out of place', create a corresponding ActionToken.
      switch tile {
      case let .tile(value) where tokenBuffer.count == idx:
        tokenBuffer.append(ActionToken.noAction(source: idx, value: value))
      case let .tile(value):
        tokenBuffer.append(ActionToken.move(source: idx, value: value))
      default:
        break
      }
    }
    return tokenBuffer;
  }

  class func quiescentTileStillQuiescent(inputPosition: Int, outputLength: Int, originalPosition: Int) -> Bool {
    // Return whether or not a 'NoAction' token still represents an unmoved tile
    return (inputPosition == outputLength) && (originalPosition == inputPosition)
  }

  /// When computing the effects of a move upon a row of tiles, calculate and return an updated list of ActionTokens
  /// corresponding to any merges that should take place. This method collapses adjacent tiles of equal value, but each
  /// tile can take part in at most one collapse per move. For example, |[1][1][1][2][2]| will become |[2][1][4]|.
  func collapse(_ group: [ActionToken]) -> [ActionToken] {


    var tokenBuffer = [ActionToken]()
    var skipNext = false
    for (idx, token) in group.enumerated() {
      if skipNext {
        // Prior iteration handled a merge. So skip this iteration.
        skipNext = false
        continue
      }
      switch token {
      case .singleCombine:
        assert(false, "Cannot have single combine token in input")
      case .doubleCombine:
        assert(false, "Cannot have double combine token in input")
      case let .noAction(s, v)
        where (idx < group.count-1
          && v == group[idx+1].getValue()
          && GameModel.quiescentTileStillQuiescent(inputPosition: idx, outputLength: tokenBuffer.count, originalPosition: s)):
        // This tile hasn't moved yet, but matches the next tile. This is a single merge
        // The last tile is *not* eligible for a merge
        let next = group[idx+1]
        let nv = v + group[idx+1].getValue()
        skipNext = true
        tokenBuffer.append(ActionToken.singleCombine(source: next.getSource(), value: nv))
      case let t where (idx < group.count-1 && t.getValue() == group[idx+1].getValue()):
        // This tile has moved, and matches the next tile. This is a double merge
        // (The tile may either have moved prevously, or the tile might have moved as a result of a previous merge)
        // The last tile is *not* eligible for a merge
        let next = group[idx+1]
        let nv = t.getValue() + group[idx+1].getValue()
        skipNext = true
        tokenBuffer.append(ActionToken.doubleCombine(source: t.getSource(), second: next.getSource(), value: nv))
      case let .noAction(s, v) where !GameModel.quiescentTileStillQuiescent(inputPosition: idx, outputLength: tokenBuffer.count, originalPosition: s):
        // A tile that didn't move before has moved (first cond.), or there was a previous merge (second cond.)
        tokenBuffer.append(ActionToken.move(source: s, value: v))
      case let .noAction(s, v):
        // A tile that didn't move before still hasn't moved
        tokenBuffer.append(ActionToken.noAction(source: s, value: v))
      case let .move(s, v):
        // Propagate a move
        tokenBuffer.append(ActionToken.move(source: s, value: v))
      default:
        // Don't do anything
        break
      }
    }
    return tokenBuffer
  }

  /// When computing the effects of a move upon a row of tiles, take a list of ActionTokens prepared by the condense()
  /// and convert() methods and convert them into MoveOrders that can be fed back to the delegate.
  func convert(_ group: [ActionToken]) -> [MoveOrder] {
    var moveBuffer = [MoveOrder]()
    for (idx, t) in group.enumerated() {
      switch t {
      case let .move(s, v):
        moveBuffer.append(MoveOrder.singleMoveOrder(source: s, destination: idx, value: v, wasMerge: false))
      case let .singleCombine(s, v):
        moveBuffer.append(MoveOrder.singleMoveOrder(source: s, destination: idx, value: v, wasMerge: true))
      case let .doubleCombine(s1, s2, v):
        moveBuffer.append(MoveOrder.doubleMoveOrder(firstSource: s1, secondSource: s2, destination: idx, value: v))
      default:
        // Don't do anything
        break
      }
    }
    return moveBuffer
  }

  /// Given an array of TileObjects, perform a collapse and create an array of move orders.
  func merge(_ group: [TileObject]) -> [MoveOrder] {
    // Calculation takes place in three steps:
    // 1. Calculate the moves necessary to produce the same tiles, but without any interstital space.
    // 2. Take the above, and calculate the moves necessary to collapse adjacent tiles of equal value.
    // 3. Take the above, and convert into MoveOrders that provide all necessary information to the delegate.
    return convert(collapse(condense(group)))
  }
}
