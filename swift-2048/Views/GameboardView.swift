//
//  GameboardView.swift
//  swift-2048
//
//  Created by Austin Zheng on 6/3/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import UIKit

class GameboardView : UIView {
  var dimension: Int
  var tileWidth: CGFloat
  var tilePadding: CGFloat
  var cornerRadius: CGFloat
  var tiles: Dictionary<NSIndexPath, TileView>

  let provider = AppearanceProvider()

  let tilePopStartScale: CGFloat = 0.1
  let tilePopMaxScale: CGFloat = 1.1
  let tilePopDelay: NSTimeInterval = 0.05
  let tileExpandTime: NSTimeInterval = 0.18
  let tileContractTime: NSTimeInterval = 0.08

  let tileMergeStartScale: CGFloat = 1.0
  let tileMergeExpandTime: NSTimeInterval = 0.08
  let tileMergeContractTime: NSTimeInterval = 0.08

  let perSquareSlideDuration: NSTimeInterval = 0.08

  init(dimension d: Int, tileWidth width: CGFloat, tilePadding padding: CGFloat, cornerRadius radius: CGFloat, backgroundColor: UIColor, foregroundColor: UIColor) {
    assert(d > 0)
    dimension = d
    tileWidth = width
    tilePadding = padding
    cornerRadius = radius
    tiles = Dictionary()
    let sideLength = padding + CGFloat(dimension)*(width + padding)
    super.init(frame: CGRectMake(0, 0, sideLength, sideLength))
    layer.cornerRadius = radius
    setupBackground(backgroundColor: backgroundColor, tileColor: foregroundColor)
  }

  /// Reset the gameboard.
  func reset() {
    for (key, tile) in tiles {
      tile.removeFromSuperview()
    }
    tiles.removeAll(keepCapacity: true)
  }

  /// Return whether a given position is valid. Used for bounds checking.
  func positionIsValid(pos: (Int, Int)) -> Bool {
    let (x, y) = pos
    return (x >= 0 && x < dimension && y >= 0 && y < dimension)
  }

  func setupBackground(backgroundColor bgColor: UIColor, tileColor: UIColor) {
    backgroundColor = bgColor
    var xCursor = tilePadding
    var yCursor: CGFloat
    let bgRadius = (cornerRadius >= 2) ? cornerRadius - 2 : 0
    for i in 0..<dimension {
      yCursor = tilePadding
      for j in 0..<dimension {
        // Draw each tile
        let background = UIView(frame: CGRectMake(xCursor, yCursor, tileWidth, tileWidth))
        background.layer.cornerRadius = bgRadius
        background.backgroundColor = tileColor
        addSubview(background)
        yCursor += tilePadding + tileWidth
      }
      xCursor += tilePadding + tileWidth
    }
  }

  /// Update the gameboard by inserting a tile in a given location. The tile will be inserted with a 'pop' animation.
  func insertTile(pos: (Int, Int), value: Int) {
    assert(positionIsValid(pos))
    let (row, col) = pos
    let x = tilePadding + CGFloat(col)*(tileWidth + tilePadding)
    let y = tilePadding + CGFloat(row)*(tileWidth + tilePadding)
    let r = (cornerRadius >= 2) ? cornerRadius - 2 : 0
    let tile = TileView(position: CGPointMake(x, y), width: tileWidth, value: value, radius: r, delegate: provider)
    tile.layer.setAffineTransform(CGAffineTransformMakeScale(tilePopStartScale, tilePopStartScale))

    addSubview(tile)
    bringSubviewToFront(tile)
    tiles[NSIndexPath(forRow: row, inSection: col)] = tile

    // Add to board
    UIView.animateWithDuration(tileExpandTime, delay: tilePopDelay, options: UIViewAnimationOptions.TransitionNone,
      animations: { () -> Void in
        // Make the tile 'pop'
        tile.layer.setAffineTransform(CGAffineTransformMakeScale(self.tilePopMaxScale, self.tilePopMaxScale))
      },
      completion: { (finished: Bool) -> Void in
        // Shrink the tile after it 'pops'
        UIView.animateWithDuration(self.tileContractTime, animations: { () -> Void in
          tile.layer.setAffineTransform(CGAffineTransformIdentity)
        })
      })
  }

  /// Update the gameboard by moving a single tile from one location to another. If the move is going to collapse two
  /// tiles into a new tile, the tile will 'pop' after moving to its new location.
  func moveOneTile(from: (Int, Int), to: (Int, Int), value: Int) {
    assert(positionIsValid(from) && positionIsValid(to))
    let (fromRow, fromCol) = from
    let (toRow, toCol) = to
    let fromKey = NSIndexPath(forRow: fromRow, inSection: fromCol)
    let toKey = NSIndexPath(forRow: toRow, inSection: toCol)

    // Get the tiles
    assert(tiles[fromKey] != nil)
    let tile = tiles[fromKey]!
    let endTile = tiles[toKey]

    // Make the frame
    var finalFrame = tile.frame
    finalFrame.origin.x = tilePadding + CGFloat(toCol)*(tileWidth + tilePadding)
    finalFrame.origin.y = tilePadding + CGFloat(toRow)*(tileWidth + tilePadding)

    // Update board state
    tiles.removeValueForKey(fromKey)
    tiles[toKey] = tile

    // Animate
    let shouldPop = endTile != nil
    UIView.animateWithDuration(perSquareSlideDuration,
      delay: 0.0,
      options: UIViewAnimationOptions.BeginFromCurrentState,
      animations: { () -> Void in
        // Slide tile
        tile.frame = finalFrame
      },
      completion: { (finished: Bool) -> Void in
        tile.value = value
        endTile?.removeFromSuperview()
        if !shouldPop || !finished {
          return
        }
        tile.layer.setAffineTransform(CGAffineTransformMakeScale(self.tileMergeStartScale, self.tileMergeStartScale))
        // Pop tile
        UIView.animateWithDuration(self.tileMergeExpandTime,
          animations: { () -> Void in
            tile.layer.setAffineTransform(CGAffineTransformMakeScale(self.tilePopMaxScale, self.tilePopMaxScale))
          },
          completion: { (finished: Bool) -> () in
            // Contract tile to original size
            UIView.animateWithDuration(self.tileMergeContractTime,
              animations: { () -> Void in
                tile.layer.setAffineTransform(CGAffineTransformIdentity)
              })
          })
      })
  }

  /// Update the gameboard by moving two tiles from their original locations to a common destination. This action always
  /// represents tile collapse, and the combined tile 'pops' after both tiles move into position.
  func moveTwoTiles(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int) {
    assert(positionIsValid(from.0) && positionIsValid(from.1) && positionIsValid(to))
    let (fromRowA, fromColA) = from.0
    let (fromRowB, fromColB) = from.1
    let (toRow, toCol) = to
    let fromKeyA = NSIndexPath(forRow: fromRowA, inSection: fromColA)
    let fromKeyB = NSIndexPath(forRow: fromRowB, inSection: fromColB)
    let toKey = NSIndexPath(forRow: toRow, inSection: toCol)
    
    assert(tiles[fromKeyA] != nil)
    assert(tiles[fromKeyB] != nil)
    let tileA = tiles[fromKeyA]!
    let tileB = tiles[fromKeyB]!

    // Make the frame
    var finalFrame = tileA.frame
    finalFrame.origin.x = tilePadding + CGFloat(toCol)*(tileWidth + tilePadding)
    finalFrame.origin.y = tilePadding + CGFloat(toRow)*(tileWidth + tilePadding)

    // Update the state
    let oldTile = tiles[toKey]  // TODO: make sure this doesn't cause issues
    oldTile?.removeFromSuperview()
    tiles.removeValueForKey(fromKeyA)
    tiles.removeValueForKey(fromKeyB)
    tiles[toKey] = tileA

    UIView.animateWithDuration(perSquareSlideDuration,
      delay: 0.0,
      options: UIViewAnimationOptions.BeginFromCurrentState,
      animations: { () -> Void in
        // Slide tiles
        tileA.frame = finalFrame
        tileB.frame = finalFrame
      },
      completion: { (finished: Bool) -> Void in
        tileA.value = value
        tileB.removeFromSuperview()
        if !finished {
          return
        }
        tileA.layer.setAffineTransform(CGAffineTransformMakeScale(self.tileMergeStartScale, self.tileMergeStartScale))
        // Pop tile
        UIView.animateWithDuration(self.tileMergeExpandTime,
          animations: { () -> Void in
            tileA.layer.setAffineTransform(CGAffineTransformMakeScale(self.tilePopMaxScale, self.tilePopMaxScale))
          },
          completion: { (finished: Bool) -> Void in
            // Contract tile to original size
            UIView.animateWithDuration(self.tileMergeContractTime,
              animations: { () -> Void in
                tileA.layer.setAffineTransform(CGAffineTransformIdentity)
              })
          })
      })
  }
  
}