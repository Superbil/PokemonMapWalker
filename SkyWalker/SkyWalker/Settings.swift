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
    private static let showGPXFolderKey = "Show gpx folder"

    open class func defaultValue() {
        let ud = UserDefaults.standard
        if ud.object(forKey: self.runScriptKey) == nil {
            ud.set(true, forKey: Settings.runScriptKey)
        }
        if ud.object(forKey: self.showMessageKey) == nil {
            ud.set(false, forKey: Settings.showMessageKey)
        }
        if ud.object(forKey: self.showGPXFolderKey) == nil {
            ud.set(true, forKey: self.showGPXFolderKey)
        }
    }

    open class var runScript: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: self.runScriptKey)
        }
        get {
            return UserDefaults.standard.bool(forKey: self.runScriptKey)
        }
    }

    open class var showMessage: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: self.showMessageKey)
        }
        get {
            return UserDefaults.standard.bool(forKey: self.showMessageKey)
        }
    }

    open class var showGPXFolder: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: self.showGPXFolderKey)
        }
        get {
            return UserDefaults.standard.bool(forKey: self.showGPXFolderKey)
        }
    }
}
