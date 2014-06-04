//
//  NumberTileGame.swift
//  swift-2048
//
//  Created by Austin Zheng on 6/3/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import UIKit

class NumberTileGameViewController : UIViewController, GameModelProtocol {
  var dimension: Int
  var threshold: Int

  var board: GameboardView?
  var model: GameModel?

  init(dimension d: NSInteger, threshold t: NSInteger) {
    self.dimension = d > 2 ? d : 2
    self.threshold = t > 8 ? t : 8
    super.init(nibName: nil, bundle: nil)
    model = GameModel(dimension: dimension, threshold: threshold, delegate: self)
    self.view.backgroundColor = UIColor.whiteColor()
    setupSwipeControls()
  }

  func setupSwipeControls() {
    let upSwipe = UISwipeGestureRecognizer(target: self, action: Selector("upCommand"))
    upSwipe.numberOfTouchesRequired = 1
    upSwipe.direction = UISwipeGestureRecognizerDirection.Up
    self.view.addGestureRecognizer(upSwipe)

    let downSwipe = UISwipeGestureRecognizer(target: self, action: Selector("downCommand"))
    downSwipe.numberOfTouchesRequired = 1
    downSwipe.direction = UISwipeGestureRecognizerDirection.Down
    self.view.addGestureRecognizer(downSwipe)

    let leftSwipe = UISwipeGestureRecognizer(target: self, action: Selector("leftCommand"))
    leftSwipe.numberOfTouchesRequired = 1
    leftSwipe.direction = UISwipeGestureRecognizerDirection.Left
    self.view.addGestureRecognizer(leftSwipe)

    let rightSwipe = UISwipeGestureRecognizer(target: self, action: Selector("rightCommand"))
    rightSwipe.numberOfTouchesRequired = 1
    rightSwipe.direction = UISwipeGestureRecognizerDirection.Right
    self.view.addGestureRecognizer(rightSwipe)
  }


  // View Controller
  override func viewDidLoad()  {
    super.viewDidLoad()
    setupGame()
  }

  func reset() {
    assert(board != nil && model != nil)
    let b = board!
    let m = model!
    b.reset()
    m.reset()
    m.insertTileAtRandomLocation(2)
    m.insertTileAtRandomLocation(2)
  }

  func setupGame() {
    var totalHeight: CGFloat = 0
    // TODO: set up other stuff

    // Set up the gameboard
    let padding: CGFloat = dimension > 5 ? 3.0 : 6.0
    let v1 = CGFloat(230.0) - padding*(CGFloat(dimension + 1))
    let width: CGFloat = CGFloat(floorf(CFloat(v1)))/CGFloat(dimension)
    let gameboard = GameboardView(dimension: dimension, tileWidth: width, tilePadding: padding, cornerRadius: 6, backgroundColor: UIColor.blackColor(), foregroundColor: UIColor.darkGrayColor())

    totalHeight += gameboard.bounds.size.height
    var currentTop = 0.5*(self.view.bounds.size.height-totalHeight)

    var f = gameboard.frame
    f.origin.x = 0.5*(self.view.bounds.size.width - f.size.width)
    f.origin.y = currentTop
    gameboard.frame = f
    self.view.addSubview(gameboard)
    self.board = gameboard

    assert(model != nil)
    let m = model!
    m.insertTileAtRandomLocation(2)
    m.insertTileAtRandomLocation(2)
  }

  // Misc
  func followUp() {
    assert(model != nil)
    let m = model!
    let (userWon, winningCoords) = m.userHasWon()
    if userWon {
      // TODO: alert delegate we won
      NSLog("You won!")
      // Alert views are currently broken, for some reason.
//      UIAlertView(title: "Victory!", message: "You won!", delegate: nil, cancelButtonTitle: "OK").show()
//      return
    }

    // Now, insert more tiles
    let randomVal = Int(arc4random_uniform(10))
    m.insertTileAtRandomLocation(randomVal == 1 ? 4 : 2)

    // At this point, the user may lose
    if m.userHasLost() {
      // TODO: alert delegate we lost
      NSLog("You lost...")
      // Alert views are currently broken, for some reason.
//      let v = UIAlertView(title: "Defeat!", message: "You lost...", delegate: nil, cancelButtonTitle: "OK")
//      v.show()
    }
  }

  // Commands
  func upCommand() {
    assert(model != nil)
    let m = model!
    m.queueMove(MoveDirection.Up,
      completion: { (changed: Bool) -> () in
        if changed {
          self.followUp()
        }
      })
  }

  func downCommand() {
    assert(model != nil)
    let m = model!
    m.queueMove(MoveDirection.Down,
      completion: { (changed: Bool) -> () in
        if changed {
          self.followUp()
        }
      })
  }

  func leftCommand() {
    assert(model != nil)
    let m = model!
    m.queueMove(MoveDirection.Left,
      completion: { (changed: Bool) -> () in
        if changed {
          self.followUp()
        }
      })
  }

  func rightCommand() {
    assert(model != nil)
    let m = model!
    m.queueMove(MoveDirection.Right,
      completion: { (changed: Bool) -> () in
        if changed {
          self.followUp()
        }
      })
  }


  // Protocol

  func scoreChanged(score: Int) {
    // Do nothing for now
  }

  func moveOneTile(from: (Int, Int), to: (Int, Int), value: Int) {
    assert(board != nil)
    let b = board!
    b.moveOneTile(from, to: to, value: value)
  }

  func moveTwoTiles(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int) {
    assert(board != nil)
    let b = board!
    b.moveTwoTiles(from, to: to, value: value)
  }

  func insertTile(location: (Int, Int), value: Int) {
    assert(board != nil)
    let b = board!
    b.insertTile(location, value: value)
  }
}
