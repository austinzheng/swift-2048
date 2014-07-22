//
//  NumberTileGame.swift
//  swift-2048
//
//  Created by Austin Zheng on 6/3/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import UIKit

/// A view controller representing the swift-2048 game. It serves mostly to tie a GameModel and a GameboardView
/// together. Data flow works as follows: user input reaches the view controller and is forwarded to the model. Move
/// orders calculated by the model are returned to the view controller and forwarded to the gameboard view, which
/// performs any animations to update its state.
class NumberTileGameViewController : UIViewController, GameModelProtocol {
  // How many tiles in both directions the gameboard contains
  var dimension: Int
  // The value of the winning tile
  var threshold: Int

  var board: GameboardView?
  var model: GameModel?

  var scoreView: ScoreViewProtocol?

  // Width of the gameboard
  let boardWidth: CGFloat = 230.0
  // How much padding to place between the tiles
  let thinPadding: CGFloat = 3.0
  let thickPadding: CGFloat = 6.0

  // Amount of space to place between the different component views (gameboard, score view, etc)
  let viewPadding: CGFloat = 10.0

  // Amount that the vertical alignment of the component views should differ from if they were centered
  let verticalViewOffset: CGFloat = 0.0

  init(dimension d: Int, threshold t: Int) {
    dimension = d > 2 ? d : 2
    threshold = t > 8 ? t : 8
    super.init(nibName: nil, bundle: nil)
    model = GameModel(dimension: dimension, threshold: threshold, delegate: self)
    view.backgroundColor = UIColor.whiteColor()
    setupSwipeControls()
  }

  func setupSwipeControls() {
    let upSwipe = UISwipeGestureRecognizer(target: self, action: Selector("up:"))
    upSwipe.numberOfTouchesRequired = 1
    upSwipe.direction = UISwipeGestureRecognizerDirection.Up
    view.addGestureRecognizer(upSwipe)

    let downSwipe = UISwipeGestureRecognizer(target: self, action: Selector("down:"))
    downSwipe.numberOfTouchesRequired = 1
    downSwipe.direction = UISwipeGestureRecognizerDirection.Down
    view.addGestureRecognizer(downSwipe)

    let leftSwipe = UISwipeGestureRecognizer(target: self, action: Selector("left:"))
    leftSwipe.numberOfTouchesRequired = 1
    leftSwipe.direction = UISwipeGestureRecognizerDirection.Left
    view.addGestureRecognizer(leftSwipe)

    let rightSwipe = UISwipeGestureRecognizer(target: self, action: Selector("right:"))
    rightSwipe.numberOfTouchesRequired = 1
    rightSwipe.direction = UISwipeGestureRecognizerDirection.Right
    view.addGestureRecognizer(rightSwipe)
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
    let vcHeight = view.bounds.size.height
    let vcWidth = view.bounds.size.width

    // This nested function provides the x-position for a component view
    func xPositionToCenterView(v: UIView) -> CGFloat {
      let viewWidth = v.bounds.size.width
      let tentativeX = 0.5*(vcWidth - viewWidth)
      return tentativeX >= 0 ? tentativeX : 0
    }
    // This nested function provides the y-position for a component view
    func yPositionForViewAtPosition(order: Int, views: [UIView]) -> CGFloat {
      assert(views.count > 0)
      assert(order >= 0 && order < views.count)
      let viewHeight = views[order].bounds.size.height
      let totalHeight = CGFloat(views.count - 1)*viewPadding + views.map({ $0.bounds.size.height }).reduce(verticalViewOffset, { $0 + $1 })
      let viewsTop = 0.5*(vcHeight - totalHeight) >= 0 ? 0.5*(vcHeight - totalHeight) : 0

      // Not sure how to slice an array yet
      var acc: CGFloat = 0
      for i in 0..<order {
        acc += viewPadding + views[i].bounds.size.height
      }
      return viewsTop + acc
    }

    // Create the score view
    let scoreView = ScoreView(backgroundColor: UIColor.blackColor(),
      textColor: UIColor.whiteColor(),
      font: UIFont(name: "HelveticaNeue-Bold", size: 16.0),
      radius: 6)
    scoreView.score = 0

    // Create the gameboard
    let padding: CGFloat = dimension > 5 ? thinPadding : thickPadding
    let v1 = boardWidth - padding*(CGFloat(dimension + 1))
    let width: CGFloat = CGFloat(floorf(CFloat(v1)))/CGFloat(dimension)
    let gameboard = GameboardView(dimension: dimension,
      tileWidth: width,
      tilePadding: padding,
      cornerRadius: 6,
      backgroundColor: UIColor.blackColor(),
      foregroundColor: UIColor.darkGrayColor())

    // Set up the frames
    let views = [scoreView, gameboard]

    var f = scoreView.frame
    f.origin.x = xPositionToCenterView(scoreView)
    f.origin.y = yPositionForViewAtPosition(0, views)
    scoreView.frame = f

    f = gameboard.frame
    f.origin.x = xPositionToCenterView(gameboard)
    f.origin.y = yPositionForViewAtPosition(1, views)
    gameboard.frame = f


    // Add to game state
    view.addSubview(gameboard)
    board = gameboard
    view.addSubview(scoreView)
    self.scoreView = scoreView

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
      let alertView = UIAlertView()
      alertView.title = "Victory"
      alertView.message = "You won!"
      alertView.addButtonWithTitle("Cancel")
      alertView.show()
      // TODO: At this point we should stall the game until the user taps 'New Game' (which hasn't been implemented yet)
      return
    }

    // Now, insert more tiles
    let randomVal = Int(arc4random_uniform(10))
    m.insertTileAtRandomLocation(randomVal == 1 ? 4 : 2)

    // At this point, the user may lose
    if m.userHasLost() {
      // TODO: alert delegate we lost
      NSLog("You lost...")
      let alertView = UIAlertView()
      alertView.title = "Defeat"
      alertView.message = "You lost..."
      alertView.addButtonWithTitle("Cancel")
      alertView.show()
    }
  }

  // Commands
  @objc(up:)
  func upCommand(r: UIGestureRecognizer!) {
    assert(model != nil)
    let m = model!
    m.queueMove(MoveDirection.Up,
      completion: { (changed: Bool) -> () in
        if changed {
          self.followUp()
        }
      })
  }

  @objc(down:)
  func downCommand(r: UIGestureRecognizer!) {
    assert(model != nil)
    let m = model!
    m.queueMove(MoveDirection.Down,
      completion: { (changed: Bool) -> () in
        if changed {
          self.followUp()
        }
      })
  }

  @objc(left:)
  func leftCommand(r: UIGestureRecognizer!) {
    assert(model != nil)
    let m = model!
    m.queueMove(MoveDirection.Left,
      completion: { (changed: Bool) -> () in
        if changed {
          self.followUp()
        }
      })
  }

  @objc(right:)
  func rightCommand(r: UIGestureRecognizer!) {
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
    if (!scoreView) {
      return
    }
    let s = scoreView!
    s.scoreChanged(newScore: score)
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
