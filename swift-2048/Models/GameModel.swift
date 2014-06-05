//
//  GameModel.swift
//  swift-2048
//
//  Created by Austin Zheng on 6/3/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import UIKit

protocol GameModelProtocol {
  func scoreChanged(score: Int)
  func moveOneTile(from: (Int, Int), to: (Int, Int), value: Int)
  func moveTwoTiles(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int)
  func insertTile(location: (Int, Int), value: Int)
}

// Represents directions supported by the game model
enum MoveDirection {
  case Up
  case Down
  case Left
  case Right
}

// Represents a move command
struct MoveCommand {
  var direction: MoveDirection
  var completion: (Bool) -> ()
  init(d: MoveDirection, c: (Bool) -> ()) {
    direction = d
    completion = c
  }
}

// Represents a 'move order'
enum MoveOrder {
  case SingleMoveOrder(source: Int, destination: Int, value: Int, wasMerge: Bool)
  case DoubleMoveOrder(firstSource: Int, secondSource: Int, destination: Int, value: Int)
}

// Represents an object in the tile grid
enum TileObject {
  case Empty
  case Tile(value: Int)
}

// Represents an action applied to a tile; used to generate move orders
enum ActionToken {
  case NoAction(source: Int, value: Int)
  case Move(source: Int, value: Int)
  case SingleCombine(source: Int, value: Int)
  case DoubleCombine(source: Int, second: Int, value: Int)

  // Get the 'value', regardless of the specific type
  func getValue() -> Int {
    switch self {
    case let .NoAction(_, v): return v
    case let .Move(_, v): return v
    case let .SingleCombine(_, v): return v
    case let .DoubleCombine(_, _, v): return v
    }
  }
  // Get the 'source', regardless of the specific type
  func getSource() -> Int {
    switch self {
    case let .NoAction(s, _): return s
    case let .Move(s, _): return s
    case let .SingleCombine(s, _): return s
    case let .DoubleCombine(s, _, _): return s
    }
  }
}

class GameModel: NSObject {
  let dimension: Int
  let threshold: Int

  var score: Int = 0 {
  didSet {
    self.delegate.scoreChanged(score)
  }
  }
//  var gameboard: TileObject[][] = TileObject[][]()
  var gameboard_temp: TileObject[]

  let delegate: GameModelProtocol

  var queue: MoveCommand[]
  var timer: NSTimer

  let maxCommands = 100
  let queueDelay = 0.3

  init(dimension d: Int, threshold t: Int, delegate: GameModelProtocol) {
    self.dimension = d
    self.threshold = t
    self.delegate = delegate
    self.queue = MoveCommand[]()
    self.timer = NSTimer()

    // Initialize the gameboard. Not sure how to do this more efficiently
//    for i in 0..dimension {
//      self.gameboard.append(TileObject[](count:dimension, repeatedValue:TileObject.Empty))
//    }
    self.gameboard_temp = TileObject[](count: (d*d), repeatedValue:TileObject.Empty)
    NSLog("DEBUG: gameboard_temp has a count of \(self.gameboard_temp.count)")
    super.init()
  }

  func reset() {
    self.score = 0
    self.queue.removeAll(keepCapacity: true)
    self.timer.invalidate()
  }

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

  func temp_getFromGameboard(#x: Int, y: Int) -> TileObject {
    let idx = x*self.dimension + y
    return self.gameboard_temp[idx]
  }

  func temp_setOnGameboard(#x: Int, y: Int, obj: TileObject) {
    self.gameboard_temp[x*self.dimension + y] = obj
  }

  //------------------------------------------------------------------------------------------------------------------//

  func insertTile(pos: (Int, Int), value: Int) {
    let (x, y) = pos
    // TODO: hack
    switch temp_getFromGameboard(x: x, y: y) {
//    switch gameboard[x][y] {
    case .Empty:
      // TODO: hack
      temp_setOnGameboard(x: x, y: y, obj: TileObject.Tile(value: value))
//      gameboard[x][y] = TileObject.Tile(value: value)
      self.delegate.insertTile(pos, value: value)
    case .Tile:
      break
    }
  }

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

  func gameboardEmptySpots() -> (Int, Int)[] {
    var buffer = Array<(Int, Int)>()
    for i in 0..dimension {
      for j in 0..dimension {
        // TODO: hack
        switch temp_getFromGameboard(x: i, y: j) {
//        switch self.gameboard[i][j] {
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
      // TODO: hack
      switch temp_getFromGameboard(x: x, y: y+1) {
//      switch gameboard[x][y+1] {
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
      // TODO: hack
      switch temp_getFromGameboard(x: x+1, y: y) {
//      switch gameboard[x+1][y] {
      case let .Tile(v):
        return v == value
      default:
        return false
      }
    }

    // Run through all the tiles and check for possible moves
    for i in 0..dimension {
      for j in 0..dimension {
        // TODO: hack
        switch temp_getFromGameboard(x: i, y: j) {
//        switch gameboard[i][j] {
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
    for i in 0..dimension {
      for j in 0..dimension {
        // Look for a tile with the winning score or greater
        // TODO: hack
        switch temp_getFromGameboard(x: i, y: j) {
//        switch gameboard[i][j] {
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

  // Perform move
  func performMove(direction: MoveDirection) -> Bool {
    // Prepare the generator closure
    let coordinateGenerator: (Int) -> (Int, Int)[] = { (iteration: Int) -> (Int, Int)[] in
      let buffer = Array<(Int, Int)>(count:self.dimension, repeatedValue: (0, 0))
      for i in 0..self.dimension {
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
    for i in 0..dimension {
      // Get the list of coords
      let coords = coordinateGenerator(i)

      // Get the corresponding list of tiles
      let tiles = coords.map() { (c: (Int, Int)) -> TileObject in
        let (x, y) = c
        // TODO: hack
        return self.temp_getFromGameboard(x: x, y: y)
//        return self.gameboard[x][y]
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
          // TODO: hack
          temp_setOnGameboard(x: sx, y: sy, obj: TileObject.Empty)
          temp_setOnGameboard(x: dx, y: dy, obj: TileObject.Tile(value: v))
//          gameboard[sx][sy] = TileObject.Empty
//          gameboard[dx][dy] = TileObject.Tile(value: v)
          delegate.moveOneTile(coords[s], to: coords[d], value: v)
        case let MoveOrder.DoubleMoveOrder(s1, s2, d, v):
          // Perform a simultaneous two-tile move
          let (s1x, s1y) = coords[s1]
          let (s2x, s2y) = coords[s2]
          let (dx, dy) = coords[d]
          score += v
          // TODO: hack
          temp_setOnGameboard(x: s1x, y: s1y, obj: TileObject.Empty)
          temp_setOnGameboard(x: s2x, y: s2y, obj: TileObject.Empty)
          temp_setOnGameboard(x: dx, y: dy, obj: TileObject.Tile(value: v))
//          gameboard[s1x][s1y] = TileObject.Empty
//          gameboard[s2x][s2y] = TileObject.Empty
//          gameboard[dx][dy] = TileObject.Tile(value: v)
          delegate.moveTwoTiles((coords[s1], coords[s2]), to: coords[d], value: v)
        }
      }
    }
    return atLeastOneMove
  }

  //------------------------------------------------------------------------------------------------------------------//

  // Remove interstital space (e.g. |[2][-][-][4]| becomes |[2][4]|)
  func condense(group: TileObject[]) -> ActionToken[] {
    var tokenBuffer = ActionToken[]()
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

  // Collapse adjacent tiles of equal value
  func collapse(group: ActionToken[]) -> ActionToken[] {
    func quiescentTileStillQuiescent(inputPosition: Int, outputLength: Int, originalPosition: Int) -> Bool {
      // Return whether or not a 'NoAction' token still represents an unmoved tile
      return (inputPosition == outputLength) && (originalPosition == inputPosition)
    }

    var tokenBuffer = ActionToken[]()
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

  // Convert all action tokens into move orders
  func convert(group: ActionToken[]) -> MoveOrder[] {
    var moveBuffer = MoveOrder[]()
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

  // Given an array of TileObjects, perform a collapse and create an array of move orders that can be fed to the view
  func merge(group: TileObject[]) -> MoveOrder[] {
    return convert(collapse(condense(group)))
  }
}
