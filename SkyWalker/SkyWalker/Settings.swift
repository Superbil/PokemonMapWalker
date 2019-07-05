//
//  Settings.swift
//
//
//  Created by Superbil on 2019/7/6.
//  Copyright © 2019 SkyWalker. All rights reserved.
//

import Foundation

class Settings {

    private static let runScriptKey = "Run Script"
    private static let showMessageKey = "Show Message"

    open class var runScript: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: Settings.runScriptKey)
        }
        get {
            return UserDefaults.standard.bool(forKey: Settings.runScriptKey)
        }
    }

    open class var showMessage: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: Settings.showMessageKey)
        }
        get {
            return UserDefaults.standard.bool(forKey: Settings.showMessageKey)
        }
    }
}
