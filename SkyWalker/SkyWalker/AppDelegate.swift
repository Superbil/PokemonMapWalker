//
//  AppDelegate.swift
//  SkyWalker
//
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    private func applicationDidFinishLaunching(notification: NSNotification) {
        Settings.defaultValue()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

}

