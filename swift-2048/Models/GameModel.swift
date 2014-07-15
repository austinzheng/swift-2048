//
//  GameModel.swift
//  swift-2048
//
//  Created by Austin Zheng on 6/3/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import UIKit

/// A protocol that establishes a way for the game model to communicate with its parent view controller.
@class_protocol protocol GameModelProtocol {
  func scoreChanged(score: Int)
  func moveOneTile(from: (Int, Int), to: (Int, Int), value: Int)
  func moveTwoTiles(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int)
  func insertTile(location: (Int, Int), value: Int)
}

/// A class representing the game state and game logic for swift-2048. It is owned by a NumberTileGame view controller.
class GameModel: NSObject {
  let dimension: Int
  let threshold: Int

  var score: Int = 0 {
  didSet {
    delegate.scoreChanged(score)
  }
  }
  var gameboard: SquareGameboard<TileObject>

  // This really should be unowned/weak. But there is currently a bug that causes the app to crash whenever the delegate
  //  is accessed unless the delegate type is a specific class (rather than a protocol).
  let delegate: GameModelProtocol

  var queue: [MoveCommand]
  var timer: NSTimer

  let maxCommands = 100
  let queueDelay = 0.3

  init(dimension d: Int, threshold t: Int, delegate: GameModelProtocol) {
    dimension = d
    threshold = t
    self.delegate = delegate
    queue = [MoveCommand]()
    timer = NSTimer()
    gameboard = SquareGameboard(dimension: d, initialValue: .Empty)
    super.init()
  }

  /// Reset the game state.
  func reset() {
    score = 0
    gameboard.setAll(.Empty)
    queue.removeAll(keepCapacity: true)
    timer.invalidate()
  }

  /// Order the game model to perform a move (because the user swiped their finger). The queue enforces a delay of a few
  /// milliseconds between each move.
  func queueMove(direction: MoveDirection, completion: (Bool) -> ()) {
    if queue.count > maxCommands {
      // Queue is wedged. This should actually never happen in practice.
      return
    }
    let command = MoveCommand(d: direction, c: completion)
    queue.append(command)
    if (!timer.valid) {
      // Timer isn't running, so fire the event immediately
      timerFired(timer)
    }
  }

  //------------------------------------------------------------------------------------------------------------------//

  /// Inform the game model that the move delay timer fired. Once the timer fires, the game model tries to execute a
  /// single move that changes the game state.
  func timerFired(timer: NSTimer) {
    if queue.count == 0 {
      return
    }
    // Go through the queue until a valid command is run or the queue is empty
    var changed = false
    while queue.count > 0 {
      let command = queue[0]
      queue.removeAtIndex(0)
      changed = performMove(command.direction)
      command.completion(changed)
      if changed {
        // If the command doesn't change anything, we immediately run the next one
        break
      }
    }
    if changed {
      self.timer = NSTimer.scheduledTimerWithTimeInterval(queueDelay,
        target: self,
        selector:
        Selector("timerFired:"),
        userInfo: nil,
        repeats: false)
    }
  }

  //------------------------------------------------------------------------------------------------------------------//

  /// Insert a tile with a given value at a position upon the gameboard.
  func insertTile(pos: (Int, Int), value: Int) {
    let (x, y) = pos
    switch gameboard[x, y] {
    case .Empty:
      gameboard[x, y] = TileObject.Tile(value: value)
      delegate.insertTile(pos, value: value)
    case .Tile:
      break
    }
  }

  /// Insert a tile with a given value at a random open position upon the gameboard.
  func insertTileAtRandomLocation(value: Int) {
    let openSpots = gameboardEmptySpots()
    if openSpots.count == 0 {
      // No more open spots; don't even bother
      return
    }
    // Randomly select an open spot, and put a new tile there
    let idx = Int(arc4random_uniform(UInt32(openSpots.count-1)))
    let (x, y) = openSpots[idx]
    insertTile((x, y), value: value)
  }

  /// Return a list of tuples describing the coordinates of empty spots remaining on the gameboard.
  func gameboardEmptySpots() -> [(Int, Int)] {
    var buffer = Array<(Int, Int)>()
    for i in 0..<dimension {
      for j in 0..<dimension {
        switch gameboard[i, j] {
        case .Empty:
          buffer += (i, j)
        case .Tile:
          break
        }
      }
    }
    return buffer
  }

  func gameboardFull() -> Bool {
    return gameboardEmptySpots().count == 0
  }

  //------------------------------------------------------------------------------------------------------------------//

  func userHasLost() -> Bool {
    if !gameboardFull() {
      // Player can't lose before filling up the board
      return false
    }

    func tileBelowHasSameValue(loc: (Int, Int), value: Int) -> Bool {
      let (x, y) = loc
      if y == dimension-1 {
        return false
      }
      switch gameboard[x, y+1] {
      case let .Tile(v):
        return v == value
      default:
        return false
      }
    }

    func tileToRightHasSameValue(loc: (Int, Int), value: Int) -> Bool {
      let (x, y) = loc
      if x == dimension-1 {
        return false
      }
      switch gameboard[x+1, y] {
      case let .Tile(v):
        return v == value
      default:
        return false
      }
    }

    // Run through all the tiles and check for possible moves
    for i in 0..<dimension {
      for j in 0..<dimension {
        switch gameboard[i, j] {
        case .Empty:
          assert(false, "Gameboard reported itself as full, but we still found an empty tile. This is a logic error.")
        case let .Tile(v):
          if tileBelowHasSameValue((i, j), v) || tileToRightHasSameValue((i, j), v) {
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
        switch gameboard[i, j] {
        case let .Tile(v) where v >= threshold:
          return (true, (i, j))
        default:
          continue
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
      var buffer = Array<(Int, Int)>(count:self.dimension, repeatedValue: (0, 0))
        for i in 0..<self.dimension {
          switch direction {
            case .Up: buffer[i] = (i, iteration)
            case .Down: buffer[i] = (self.dimension - i - 1, iteration)
            case .Left: buffer[i] = (iteration, i)
            case .Right: buffer[i] = (iteration, self.dimension - i - 1)
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
        case let MoveOrder.SingleMoveOrder(s, d, v, wasMerge):
          // Perform a single-tile move
          let (sx, sy) = coords[s]
          let (dx, dy) = coords[d]
          if wasMerge {
            score += v
          }
          gameboard[sx, sy] = TileObject.Empty
          gameboard[dx, dy] = TileObject.Tile(value: v)
          delegate.moveOneTile(coords[s], to: coords[d], value: v)
        case let MoveOrder.DoubleMoveOrder(s1, s2, d, v):
          // Perform a simultaneous two-tile move
          let (s1x, s1y) = coords[s1]
          let (s2x, s2y) = coords[s2]
          let (dx, dy) = coords[d]
          score += v
          gameboard[s1x, s1y] = TileObject.Empty
          gameboard[s2x, s2y] = TileObject.Empty
          gameboard[dx, dy] = TileObject.Tile(value: v)
          delegate.moveTwoTiles((coords[s1], coords[s2]), to: coords[d], value: v)
        }
      }
    }
    return atLeastOneMove
  }

  //------------------------------------------------------------------------------------------------------------------//

  /// When computing the effects of a move upon a row of tiles, calculate and return a list of ActionTokens
  /// corresponding to any moves necessary to remove interstital space. For example, |[2][ ][ ][4]| will become
  /// |[2][4]|.
  func condense(group: [TileObject]) -> [ActionToken] {
    var tokenBuffer = [ActionToken]()
    for (idx, tile) in enumerate(group) {
      // Go through all the tiles in 'group'. When we see a tile 'out of place', create a corresponding ActionToken.
      switch tile {
      case let .Tile(value) where tokenBuffer.count == idx:
        tokenBuffer.append(ActionToken.NoAction(source: idx, value: value))
      case let .Tile(value):
        tokenBuffer.append(ActionToken.Move(source: idx, value: value))
      default:
        break
      }
    }
    return tokenBuffer;
  }

  /// When computing the effects of a move upon a row of tiles, calculate and return an updated list of ActionTokens
  /// corresponding to any merges that should take place. This method collapses adjacent tiles of equal value, but each
  /// tile can take part in at most one collapse per move. For example, |[1][1][1][2][2]| will become |[2][1][4]|.
  func collapse(group: [ActionToken]) -> [ActionToken] {
    func quiescentTileStillQuiescent(inputPosition: Int, outputLength: Int, originalPosition: Int) -> Bool {
      // Return whether or not a 'NoAction' token still represents an unmoved tile
      return (inputPosition == outputLength) && (originalPosition == inputPosition)
    }

    var tokenBuffer = [ActionToken]()
    var skipNext = false
    for (idx, token) in enumerate(group) {
      if skipNext {
        // Prior iteration handled a merge. So skip this iteration.
        skipNext = false
        continue
      }
      switch token {
      case .SingleCombine:
        assert(false, "Cannot have single combine token in input")
      case .DoubleCombine:
        assert(false, "Cannot have double combine token in input")
      case let .NoAction(s, v)
        where (idx < group.count-1
          && v == group[idx+1].getValue()
          && quiescentTileStillQuiescent(idx, tokenBuffer.count, s)):
        // This tile hasn't moved yet, but matches the next tile. This is a single merge
        // The last tile is *not* eligible for a merge
        let next = group[idx+1]
        let nv = v + group[idx+1].getValue()
        skipNext = true
        tokenBuffer.append(ActionToken.SingleCombine(source: next.getSource(), value: nv))
      case let t where (idx < group.count-1 && t.getValue() == group[idx+1].getValue()):
        // This tile has moved, and matches the next tile. This is a double merge
        // (The tile may either have moved prevously, or the tile might have moved as a result of a previous merge)
        // The last tile is *not* eligible for a merge
        let next = group[idx+1]
        let nv = t.getValue() + group[idx+1].getValue()
        skipNext = true
        tokenBuffer.append(ActionToken.DoubleCombine(source: t.getSource(), second: next.getSource(), value: nv))
      case let .NoAction(s, v) where !quiescentTileStillQuiescent(idx, tokenBuffer.count, s):
        // A tile that didn't move before has moved (first cond.), or there was a previous merge (second cond.)
        tokenBuffer.append(ActionToken.Move(source: s, value: v))
      case let .NoAction(s, v):
        // A tile that didn't move before still hasn't moved
        tokenBuffer.append(ActionToken.NoAction(source: s, value: v))
      case let .Move(s, v):
        // Propagate a move
        tokenBuffer.append(ActionToken.Move(source: s, value: v))
      default:
        // Don't do anything
        break
      }
    }
    return tokenBuffer
  }

  /// When computing the effects of a move upon a row of tiles, take a list of ActionTokens prepared by the condense()
  /// and convert() methods and convert them into MoveOrders that can be fed back to the delegate.
  func convert(group: [ActionToken]) -> [MoveOrder] {
    var moveBuffer = [MoveOrder]()
    for (idx, t) in enumerate(group) {
      switch t {
      case let .Move(s, v):
        moveBuffer.append(MoveOrder.SingleMoveOrder(source: s, destination: idx, value: v, wasMerge: false))
      case let .SingleCombine(s, v):
        moveBuffer.append(MoveOrder.SingleMoveOrder(source: s, destination: idx, value: v, wasMerge: true))
      case let .DoubleCombine(s1, s2, v):
        moveBuffer.append(MoveOrder.DoubleMoveOrder(firstSource: s1, secondSource: s2, destination: idx, value: v))
      default:
        // Don't do anything
        break
      }
    }
    return moveBuffer
  }

  /// Given an array of TileObjects, perform a collapse and create an array of move orders.
  func merge(group: [TileObject]) -> [MoveOrder] {
    // Calculation takes place in three steps:
    // 1. Calculate the moves necessary to produce the same tiles, but without any interstital space.
    // 2. Take the above, and calculate the moves necessary to collapse adjacent tiles of equal value.
    // 3. Take the above, and convert into MoveOrders that provide all necessary information to the delegate.
    return convert(collapse(condense(group)))
  }
}
