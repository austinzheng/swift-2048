//
//  AuxiliaryModels.swift
//  swift-2048
//
//  Created by Austin Zheng on 6/5/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

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

// A struct representing a square gameboard
struct SquareGameboard<T> {
  let dimension: Int
  var boardArray: Array<T>

  init(dimension d: Int, initialValue: T) {
    dimension = d
    boardArray = T[](count:d*d, repeatedValue:initialValue)
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
}
