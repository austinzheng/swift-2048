//
//  SettingsViewController.swift
//  swift-2048
//
//  Created by Chris Stott on 2017-03-19.
//
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // NOTE: I set deployment target to 10.0
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { (_) in
            self.getSettings()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return 3;
        } else {
            return 1;
        }
    }
    
    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 51
    }
    
    func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        
        //cell.titleLabel.text = "\(ListArray.objectAtIndex(indexPath.item))"
        
        cell?.textLabel?.text = "Hello"
        
        return cell!
    }
    
    private func getSettings() {
        [0][1]
    }
    
}

