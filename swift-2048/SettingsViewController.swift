//
//  SettingsViewController.swift
//  swift-2048
//
//  Created by Chris Stott on 2017-03-19.
//
//

import UIKit

class SettingsViewController: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // NOTE: I set deployment target to 10.0
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { (_) in
            SettingsModel.getSettings()
        }
    }
    
}

