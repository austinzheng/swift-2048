//
//  GameModel.swift
//  swift-2048
//
//  Created by Austin Zheng on 6/3/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import UIKit

// Represents a 'move order'
enum MoveOrder {
  case SingleMoveOrder(source: Int, destination: Int, value: Int)
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

  var score: Int
  var gameboard: TileObject[][]

  init(dimension: Int, threshold: Int) {
    self.dimension = dimension
    self.threshold = threshold
    // TODO: delegate

    score = 0
    // Initialize the gameboard. Not sure how to do this more efficiently
    gameboard = TileObject[][]()
    for i in 0...dimension {
      gameboard.append(TileObject[](count:dimension, repeatedValue:TileObject.Empty))
    }
    super.init()
  }

  func reset() {
    // TODO: reset
    self.score = 0
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
        moveBuffer.append(MoveOrder.SingleMoveOrder(source: s, destination: idx, value: v))
      case let .SingleCombine(s, v):
        moveBuffer.append(MoveOrder.SingleMoveOrder(source: s, destination: idx, value: v))
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
