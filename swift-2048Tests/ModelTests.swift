//
//  ModelTests.swift
//  swift-2048
//
//  Created by Austin Zheng on 6/3/14.
//  Copyright (c) 2014 Austin Zheng. Released under the terms of the MIT license.
//

import XCTest
@testable import swift_2048

class ModelTests: XCTestCase, GameModelProtocol {

  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
    
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }

  // Would be better to just make the merge and associated methods static.
  func scoreChanged(_ score: Int) { }
  func moveOneTile(_ from: (Int, Int), to: (Int, Int), value: Int) { }
  func moveTwoTiles(_ from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int) { }
  func insertTile(_ location: (Int, Int), value: Int) { }

  // --------- TEST CONDENSE --------- //

  func testCondense1() {
    let m = GameModel(dimension: 5, threshold: 2048, delegate: self)
    var group = [TileObject.tile(1),
      TileObject.tile(2),
      TileObject.tile(4),
      TileObject.tile(8),
      TileObject.tile(1)]
    XCTAssert(group.count == 5, "Group should have 5 members before anything happens")
    let output = m.condense(group)

    // Check the output
    XCTAssert(output.count == 5, "Output should have 5 merge tiles")
    for (idx, object) in output.enumerated() {
      let c = group[idx]
      switch c {
      case .empty:
        // This shouldn't happen; all of the tiles in 'group' should be real tiles
        XCTFail("Input was bad!")
      case let .tile(desiredV):
        // Now we can check the values
        switch object {
        case let .noAction(s, v) where (s == idx && v == desiredV):
          continue
        default:
          XCTFail("Output \(idx) had the wrong type, value, or source")
        }
      }
    }
  }

  func testCondense1b() {
    let m = GameModel(dimension: 5, threshold: 2048, delegate: self)
    let group = [TileObject.tile(1),
      TileObject.empty,
      TileObject.tile(4),
      TileObject.empty,
      TileObject.tile(1)]
    XCTAssert(group.count == 5, "Group should have 5 members before anything happens")
    let output = m.condense(group)

    // Check the output
    XCTAssert(output.count == 3, "Output should have 3 merge tiles")
    for (idx, _) in output.enumerated() {
      let c = output[idx]
      switch c {
      case .singleCombine:
        XCTFail("Output \(idx) was a single combine merge tile, but condense should never produce those!")
      case .doubleCombine:
        XCTFail("Output \(idx) was a double combine merge tile, but condense should never produce those!")
      case let .noAction(s, v):
        if (idx == 0) {
          if (s != 0 || v != 1 ) {
            XCTFail("Output \(idx) was a no action merge tile, but the source or value were wrong!")
          }
        }
        else {
          XCTFail("Output \(idx) was a no action merge tile, but shouldn't have been!")
        }
      case let .move(s, v):
        if (idx == 1) {
          if (s != 2 || v != 4) {
            XCTFail("Output \(idx) was a move merge tile, but the source or value was wrong.")
          }
        }
        else if (idx == 2) {
          if (s != 4 || v != 1) {
            XCTFail("Output \(idx) was a move merge tile, but the source or value was wrong.")
          }
        }
        else {
          XCTFail("Output \(idx) was a move merge tile, but shouldn't have been!!")
        }
      }
    }
  }

  func testCondense1c() {
    let m = GameModel(dimension: 5, threshold: 2048, delegate: self)
    let group = [TileObject.tile(1),
      TileObject.tile(4),
      TileObject.empty,
      TileObject.empty,
      TileObject.tile(1),
      TileObject.empty]
    XCTAssert(group.count == 6, "Group should have 6 members before anything happens")
    let output = m.condense(group)

    // Check the output
    XCTAssert(output.count == 3, "Output should have 3 merge tiles")
    for (idx, _) in output.enumerated() {
      let c = output[idx]
      switch c {
      case .singleCombine:
        XCTFail("Output \(idx) was a single combine merge tile, but condense should never produce those!")
      case .doubleCombine:
        XCTFail("Output \(idx) was a double combine merge tile, but condense should never produce those!")
      case let .noAction(s, v):
        if (idx == 0) {
          if (s != 0 || v != 1 ) {
            XCTFail("Output \(idx) was a no action merge tile, but the source or value were wrong!")
          }
        }
        else if (idx == 1) {
          if (s != 1 || v != 4) {
            XCTFail("Output \(idx) was a no action merge tile, but the source or value were wrong!")
          }
        }
        else {
          XCTFail("Output \(idx) was a no action merge tile, but shouldn't have been!")
        }
      case let .move(s, v):
        if (idx == 2) {
          if (s != 4 || v != 1) {
            XCTFail("Output \(idx) was a move merge tile, but the source or value was wrong.")
          }
        }
        else {
          XCTFail("Output \(idx) was a move merge tile, but shouldn't have been!")
        }
      }
    }
  }

  func testCondense1d() {
    let m = GameModel(dimension: 5, threshold: 2048, delegate: self)
    let group = [TileObject.empty,
      TileObject.empty,
      TileObject.tile(1),
      TileObject.tile(4),
      TileObject.empty,
      TileObject.empty,
      TileObject.tile(1),
      TileObject.empty]
    XCTAssert(group.count == 8, "Group should have 8 members before anything happens")
    let output = m.condense(group)

    // Check the output
    XCTAssert(output.count == 3, "Output should have 3 merge tiles")
    for (idx, _) in output.enumerated() {
      let c = output[idx]
      switch c {
      case .singleCombine:
        XCTFail("Output \(idx) was a single combine merge tile, but condense should never produce those!")
      case .doubleCombine:
        XCTFail("Output \(idx) was a double combine merge tile, but condense should never produce those!")
      case .noAction:
        XCTFail("Output \(idx) was a no action merge tile, but shouldn't have been!")
      case let .move(s, v):
        if (idx == 0) {
          XCTAssert(s == 2 && v == 1, "Output \(idx) was a move merge tile, but the source or value was wrong.")
        }
        else if (idx == 1) {
          XCTAssert(s == 3 && v == 4, "Output \(idx) was a move merge tile, but the source or value was wrong.")
        }
        else if (idx == 2) {
          XCTAssert(s == 6 && v == 1, "Output \(idx) was a move merge tile, but the source or value was wrong.")
        }
        else {
          XCTFail("Output \(idx) was a move merge tile, but only outputs 1 and 2 should have been merge tiles!")
        }
      }
    }
  }

  func testCondense4() {
    let m = GameModel(dimension: 5, threshold: 2048, delegate: self)
    let group = [TileObject.tile(2),
      TileObject.tile(2),
      TileObject.tile(16),
      TileObject.empty,
      TileObject.tile(1)]
    let output = m.condense(group)
    XCTAssert(output.count == 4, "Output had \(output.count) merge tiles, should have had 4")
  }

  // --------- TEST COLLAPSE --------- //

  func testCollapse1() {
    let m = GameModel(dimension: 5, threshold: 2048, delegate: self)
    let group = [ActionToken.noAction(source: 0, value: 4),
      ActionToken.noAction(source: 1, value: 2),
      ActionToken.noAction(source: 2, value: 4),
      ActionToken.noAction(source: 3, value: 2)]
    let output = m.collapse(group)
    XCTAssert(output.count == 4, "Output should have had 4 items, but had \(output.count) items")
  }

  // --------- TEST CONVERT --------- //

  // (nothing for now)

  // --------- TEST MERGE --------- //

  func testMerge1() {
    // Scenario: no movement at all
    let m = GameModel(dimension: 5, threshold: 2048, delegate: self)
    let group = [TileObject.tile(1),
      TileObject.tile(2),
      TileObject.tile(4),
      TileObject.tile(8),
      TileObject.tile(1)]
    XCTAssert(group.count == 5, "Group should have 5 members before anything happens")
    let orders = m.merge(group)
    XCTAssert(orders.count == 0, "No move orders should have happened, but output had \(orders.count) items")
  }

  func testMerge2() {
    // Scenario: some moves
    let m = GameModel(dimension: 5, threshold: 2048, delegate: self)
    let group = [TileObject.tile(1),
      TileObject.empty,
      TileObject.tile(4),
      TileObject.empty,
      TileObject.tile(1)]
    let orders = m.merge(group)
    XCTAssert(orders.count == 2, "There should have been 2 orders. Got \(orders.count) instead")
    // Verify orders
    for (idx, order) in orders.enumerated() {
      switch order {
      case let .singleMoveOrder(s, d, v, _):
        if (idx == 0) {
          XCTAssert(s == 2, "Got a single move order at \(idx), but source was wrong. Got \(s) instead of 2")
          XCTAssert(d == 1, "Got a single move order at \(idx), but destination was wrong. Got \(d) instead of 1")
          XCTAssert(v == 4, "Got a single move order at \(idx), but value was wrong. Got \(v) instead of 4")
        }
        else if (idx == 1) {
          XCTAssert(s == 4, "Got a single move order at \(idx), but source was wrong. Got \(s) instead of 4")
          XCTAssert(d == 2, "Got a single move order at \(idx), but destination was wrong. Got \(d) instead of 2")
          XCTAssert(v == 1, "Got a single move order at \(idx), but value was wrong. Got \(v) instead of 1")
        }
        else {
          XCTFail("Got a single move order at \(idx), but there shouldn't have been one")
        }
      case .doubleMoveOrder:
        XCTFail("No double move orders are valid for this test")
      }
    }
  }

  func testMerge3() {
    // Scenario: no moves, one merge at end
    let m = GameModel(dimension: 5, threshold: 2048, delegate: self)
    let group = [TileObject.tile(1),
      TileObject.tile(2),
      TileObject.tile(4),
      TileObject.tile(1),
      TileObject.tile(1)]
    let orders = m.merge(group)
    XCTAssert(orders.count == 1, "There should have been 1 order. Got \(orders.count) instead")
    // Verify orders
    for (idx, order) in orders.enumerated() {
      switch order {
      case let .singleMoveOrder(s, d, v, _):
        if (idx == 0) {
          XCTAssert(s == 4, "Got a single move order at \(idx), but source was wrong. Got \(s) instead of 4")
          XCTAssert(d == 3, "Got a single move order at \(idx), but destination was wrong. Got \(d) instead of 3")
          XCTAssert(v == 2, "Got a single move order at \(idx), but value was wrong. Got \(v) instead of 2")
        }
        else {
          XCTFail("Got a single move order at \(idx), but there shouldn't have been one")
        }
      case .doubleMoveOrder:
        XCTFail("No double move orders are valid for this test")
      }
    }
  }

  func testMerge4() {
    // Scenario: one move, one merge
    let m = GameModel(dimension: 5, threshold: 2048, delegate: self)
    let group = [TileObject.tile(2),
      TileObject.tile(2),
      TileObject.tile(16),
      TileObject.empty,
      TileObject.tile(1)]
    let orders = m.merge(group)
    XCTAssert(orders.count == 3, "There should have been 3 orders. Got \(orders.count) instead")
    // Verify orders
    for (idx, order) in orders.enumerated() {
      switch order {
      case let .singleMoveOrder(s, d, v, _):
        if (idx == 0) {
          XCTAssert(s == 1, "Got a single move order at \(idx), but source was wrong. Got \(s) instead of 1")
          XCTAssert(d == 0, "Got a single move order at \(idx), but destination was wrong. Got \(d) instead of 0")
          XCTAssert(v == 4, "Got a single move order at \(idx), but value was wrong. Got \(v) instead of 4")
        }
        else if (idx == 1) {
          XCTAssert(s == 2, "Got a single move order at \(idx), but source was wrong. Got \(s) instead of 2")
          XCTAssert(d == 1, "Got a single move order at \(idx), but destination was wrong. Got \(d) instead of 1")
          XCTAssert(v == 16, "Got a single move order at \(idx), but value was wrong. Got \(v) instead of 16")
        }
        else if (idx == 2) {
          XCTAssert(s == 4, "Got a single move order at \(idx), but source was wrong. Got \(s) instead of 4")
          XCTAssert(d == 2, "Got a single move order at \(idx), but destination was wrong. Got \(d) instead of 2")
          XCTAssert(v == 1, "Got a single move order at \(idx), but value was wrong. Got \(v) instead of 1")
        }
        else {
          XCTFail("Got a single move order at \(idx), but there shouldn't have been one")
        }
      case .doubleMoveOrder:
        XCTFail("No double move orders are valid for this test")
      }
    }
  }

  func testMerge5() {
    // Scenario: multi-merge with 3 equal tiles involved
    let m = GameModel(dimension: 5, threshold: 2048, delegate: self)
    let group = [TileObject.tile(2),
      TileObject.tile(2),
      TileObject.tile(2),
      TileObject.empty,
      TileObject.empty]
    let orders = m.merge(group)
    XCTAssert(orders.count == 2, "There should have been 2 orders. Got \(orders.count) instead")
    // Verify orders
    for (idx, order) in orders.enumerated() {
      switch order {
      case let .singleMoveOrder(s, d, v, _):
        if (idx == 0) {
          XCTAssert(s == 1, "Got a single move order at \(idx), but source was wrong. Got \(s) instead of 1")
          XCTAssert(d == 0, "Got a single move order at \(idx), but destination was wrong. Got \(d) instead of 0")
          XCTAssert(v == 4, "Got a single move order at \(idx), but value was wrong. Got \(v) instead of 4")
        }
        else if (idx == 1) {
          XCTAssert(s == 2, "Got a single move order at \(idx), but source was wrong. Got \(s) instead of 2")
          XCTAssert(d == 1, "Got a single move order at \(idx), but destination was wrong. Got \(d) instead of 1")
          XCTAssert(v == 2, "Got a single move order at \(idx), but value was wrong. Got \(v) instead of 2")
        }
        else {
          XCTFail("Got a single move order at \(idx), but there shouldn't have been one")
        }
      case .doubleMoveOrder:
        XCTFail("No double move orders are valid for this test")
      }
    }
  }

  func testMerge6() {
    // Scenario: multiple merges
    let m = GameModel(dimension: 5, threshold: 2048, delegate: self)
    let group = [TileObject.tile(2),
      TileObject.tile(2),
      TileObject.tile(2),
      TileObject.tile(16),
      TileObject.tile(16)]
    let orders = m.merge(group)
    XCTAssert(orders.count == 3, "There should have been 3 orders. Got \(orders.count) instead")
    // Verify orders
    for (idx, order) in orders.enumerated() {
      switch order {
      case let .singleMoveOrder(s, d, v, _):
        if (idx == 0) {
          XCTAssert(s == 1, "Got a single move order at \(idx), but source was wrong. Got \(s) instead of 1")
          XCTAssert(d == 0, "Got a single move order at \(idx), but destination was wrong. Got \(d) instead of 0")
          XCTAssert(v == 4, "Got a single move order at \(idx), but value was wrong. Got \(v) instead of 4")
        }
        else if (idx == 1) {
          XCTAssert(s == 2, "Got a single move order at \(idx), but source was wrong. Got \(s) instead of 2")
          XCTAssert(d == 1, "Got a single move order at \(idx), but destination was wrong. Got \(d) instead of 1")
          XCTAssert(v == 2, "Got a single move order at \(idx), but value was wrong. Got \(v) instead of 2")
        }
        else {
          XCTFail("Got a single move order at \(idx), but there shouldn't have been one")
        }
      case let .doubleMoveOrder(s1, s2, d, v):
        if (idx == 2) {
          XCTAssert(s1 == 3, "Got a double move order at \(idx), but source 1 was wrong. Got \(s1) instead of 3")
          XCTAssert(s2 == 4, "Got a double move order at \(idx), but source 2 was wrong. Got \(s2) instead of 4")
          XCTAssert(d == 2, "Got a double move order at \(idx), but destination was wrong. Got \(d) instead of 2")
          XCTAssert(v == 32, "Got a double move order at \(idx), but value was wrong. Got \(v) instead of 32")
        }
        else {
          XCTFail("Got a double move order at \(idx), but there shouldn't have been one")
        }
      }
    }
  }

  func testMerge7() {
    // Scenario: multiple spaces and merges
    let m = GameModel(dimension: 5, threshold: 2048, delegate: self)
    let group = [TileObject.empty,
      TileObject.tile(2),
      TileObject.tile(2),
      TileObject.tile(16),
      TileObject.tile(16)]
    let orders = m.merge(group)
    XCTAssert(orders.count == 2, "There should have been 2 orders. Got \(orders.count) instead")
    // Verify orders
    for (idx, order) in orders.enumerated() {
      switch order {
      case .singleMoveOrder:
        XCTFail("No single move orders are valid for this test")
      case let .doubleMoveOrder(s1, s2, d, v):
        if (idx == 0) {
          XCTAssert(s1 == 1, "Got a double move order at \(idx), but source 1 was wrong. Got \(s1) instead of 1")
          XCTAssert(s2 == 2, "Got a double move order at \(idx), but source 2 was wrong. Got \(s2) instead of 2")
          XCTAssert(d == 0, "Got a double move order at \(idx), but destination was wrong. Got \(d) instead of 0")
          XCTAssert(v == 4, "Got a double move order at \(idx), but value was wrong. Got \(v) instead of 4")
        }
        else if (idx == 1) {
          XCTAssert(s1 == 3, "Got a double move order at \(idx), but source 1 was wrong. Got \(s1) instead of 3")
          XCTAssert(s2 == 4, "Got a double move order at \(idx), but source 2 was wrong. Got \(s2) instead of 4")
          XCTAssert(d == 1, "Got a double move order at \(idx), but destination was wrong. Got \(d) instead of 1")
          XCTAssert(v == 32, "Got a double move order at \(idx), but value was wrong. Got \(v) instead of 32")
        }
        else {
          XCTFail("Got a double move order at \(idx), but there shouldn't have been one")
        }
      }
    }
  }

  func testMerge8() {
    // Scenario: multiple spaces and merges
    let m = GameModel(dimension: 5, threshold: 2048, delegate: self)
    let group = [TileObject.tile(4),
      TileObject.empty,
      TileObject.tile(4),
      TileObject.tile(32),
      TileObject.tile(32)]
    let orders = m.merge(group)
    XCTAssert(orders.count == 2, "There should have been 2 orders. Got \(orders.count) instead")
    // Verify orders
    for (idx, order) in orders.enumerated() {
      switch order {
      case let .singleMoveOrder(s, d, v, _):
        if (idx == 0) {
          XCTAssert(s == 2, "Got a single move order at \(idx), but source was wrong. Got \(s) instead of 2")
          XCTAssert(d == 0, "Got a single move order at \(idx), but destination was wrong. Got \(d) instead of 0")
          XCTAssert(v == 8, "Got a single move order at \(idx), but value was wrong. Got \(v) instead of 8")
        }
        else {
          XCTFail("Got a single move order at \(idx), but there shouldn't have been one")
        }
      case let .doubleMoveOrder(s1, s2, d, v):
        if (idx == 1) {
          XCTAssert(s1 == 3, "Got a double move order at \(idx), but source 1 was wrong. Got \(s1) instead of 3")
          XCTAssert(s2 == 4, "Got a double move order at \(idx), but source 2 was wrong. Got \(s2) instead of 4")
          XCTAssert(d == 1, "Got a double move order at \(idx), but destination was wrong. Got \(d) instead of 1")
          XCTAssert(v == 64, "Got a double move order at \(idx), but value was wrong. Got \(v) instead of 64")
        }
        else {
          XCTFail("Got a double move order at \(idx), but there shouldn't have been one")
        }
      }
    }
  }

  func testMerge9() {
    // Scenario: multiple moves with leading space
    let m = GameModel(dimension: 5, threshold: 2048, delegate: self)
    let group = [TileObject.empty,
      TileObject.empty,
      TileObject.tile(4),
      TileObject.empty,
      TileObject.tile(32)]
    let orders = m.merge(group)
    XCTAssert(orders.count == 2, "There should have been 2 orders. Got \(orders.count) instead")
    // Verify orders
    for (idx, order) in orders.enumerated() {
      switch order {
      case let .singleMoveOrder(s, d, v, _):
        if (idx == 0) {
          XCTAssert(s == 2, "Got a single move order at \(idx), but source was wrong. Got \(s) instead of 2")
          XCTAssert(d == 0, "Got a single move order at \(idx), but destination was wrong. Got \(d) instead of 0")
          XCTAssert(v == 4, "Got a single move order at \(idx), but value was wrong. Got \(v) instead of 4")
        }
        else if (idx == 1) {
          XCTAssert(s == 4, "Got a single move order at \(idx), but source was wrong. Got \(s) instead of 4")
          XCTAssert(d == 1, "Got a single move order at \(idx), but destination was wrong. Got \(d) instead of 1")
          XCTAssert(v == 32, "Got a single move order at \(idx), but value was wrong. Got \(v) instead of 32")
        }
        else {
          XCTFail("Got a single move order at \(idx), but there shouldn't have been one")
        }
      case .doubleMoveOrder:
        XCTFail("No double move orders are valid for this test")
      }
    }
  }

}
