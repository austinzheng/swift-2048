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
        
        SettingsModel.getSettingsAsync(completion: {
            (result: String) in
            print(result)
            [0][1]
        })
    }
    
}

