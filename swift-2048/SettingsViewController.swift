//
//  SettingsViewController.swift
//  swift-2048
//
//  Created by Chris Stott on 2017-03-19.
//
//

import UIKit

class SettingsViewController: UIViewController {
    
    func processSetting() {
        [0][1]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SettingsModel.getSettingsAsync(viewController: self)
    }
    
}

