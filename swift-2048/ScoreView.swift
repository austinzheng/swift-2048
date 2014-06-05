//
//  ScoreView.swift
//  swift-2048
//
//  Created by Ryan Bertrand on 6/4/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import UIKit

class ScoreView : UIView {
  var score: Int = 0 {
  didSet {
    //Update score label
    scoreLabel.text = "\(score)"
  }
  }
  
  var title: String = "" {
  didSet {
    //Update title label
    titleLabel.text = title
  }
  }
  
  var scoreLabel: UILabel
  var titleLabel: UILabel
  
  
  init(frame: CGRect) {
    var fortyPercentOfHeight = frame.size.height * 0.40
    var tenPercentOfHeight = frame.size.height * 0.10
    
    titleLabel = UILabel(frame: CGRectMake(0, tenPercentOfHeight, frame.size.width, fortyPercentOfHeight))
    titleLabel.textAlignment = NSTextAlignment.Center
    titleLabel.minimumScaleFactor = 0.5
    titleLabel.textColor = UIColor(red: 238/255, green: 226/255, blue: 212/255, alpha: 1.0)
    titleLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
    
    scoreLabel = UILabel(frame: CGRectMake(0, fortyPercentOfHeight, frame.size.width, frame.size.height * 0.60))
    scoreLabel.textAlignment = NSTextAlignment.Center
    scoreLabel.minimumScaleFactor = 0.5
    scoreLabel.textColor = UIColor.whiteColor()
    scoreLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 21)
    
    super.init(frame: frame)
    
    self.addSubview(scoreLabel)
    self.addSubview(titleLabel)
    
    self.layer.cornerRadius = 10
    self.backgroundColor = UIColor(red: 187/255, green: 173/255, blue: 160/255, alpha: 1.0)
  }
}