//
//  SettingsModel.swift
//  swift-2048
//
//  Created by Chris Stott on 2017-03-19.
//
//

import Foundation

class SettingsModel {
    class func getSettingsAsync(completion: @escaping (_: String) -> Void) {
        
        // NOTE: I set deployment target to 10.0
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { (_) in
            completion("settings");
        }
    }
}
