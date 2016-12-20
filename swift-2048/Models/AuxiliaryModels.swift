//
//  AuxiliaryModels.swift
//  swift-2048
//
//  Created by Austin Zheng on 6/5/14.
//  Copyright (c) 2014 Austin Zheng. Released under the terms of the MIT license.
//

import Foundation

/// An enum representing directions supported by the game model.
enum MoveDirection {
  case up, down, left, right
}

/// An enum representing a movement command issued by the view controller as the result of the user swiping.
struct MoveCommand {
  let direction : MoveDirection
  let completion : (Bool) -> ()
}

/// An enum representing a 'move order'. This is a data structure the game model uses to inform the view controller
/// which tiles on the gameboard should be moved and/or combined.
enum MoveOrder {
  case singleMoveOrder(source: Int, destination: Int, value: Int, wasMerge: Bool)
  case doubleMoveOrder(firstSource: Int, secondSource: Int, destination: Int, value: Int)
}

/// An enum representing either an empty space or a tile upon the board.
enum TileObject {
  case empty
  case tile(Int)
}

/// An enum representing an intermediate result used by the game logic when figuring out how the board should change as
/// the result of a move. ActionTokens are transformed into MoveOrders before being sent to the delegate.
enum ActionToken {
  case noAction(source: Int, value: Int)
  case move(source: Int, value: Int)
  case singleCombine(source: Int, value: Int)
  case doubleCombine(source: Int, second: Int, value: Int)

  // Get the 'value', regardless of the specific type
  func getValue() -> Int {
    switch self {
    case let .noAction(_, v): return v
    case let .move(_, v): return v
    case let .singleCombine(_, v): return v
    case let .doubleCombine(_, _, v): return v
    }
  }
  // Get the 'source', regardless of the specific type
  func getSource() -> Int {
    switch self {
    case let .noAction(s, _): return s
    case let .move(s, _): return s
    case let .singleCombine(s, _): return s
    case let .doubleCombine(s, _, _): return s
    }
  }
}

/// A struct representing a square gameboard. Because this struct uses generics, it could conceivably be used to
/// represent state for many other games without modification.
struct SquareGameboard<T> {
  let dimension : Int
  var boardArray : [T]

  init(dimension d: Int, initialValue: T) {
    dimension = d
    boardArray = [T](repeating: initialValue, count: d*d)
  }

  subscript(row: Int, col: Int) -> T {
    get {
      assert(row >= 0 && row < dimension)
      assert(col >= 0 && col < dimension)
      return boardArray[row*dimension + col]
    }
    set {
      assert(row >= 0 && row < dimension)
      assert(col >= 0 && col < dimension)
      boardArray[row*dimension + col] = newValue
    }
  }

  // We mark this function as 'mutating' since it changes its 'parent' struct.
  mutating func setAll(_ item: T) {
    for i in 0..<dimension {
      for j in 0..<dimension {
        self[i, j] = item
      }
    }
  }
}
