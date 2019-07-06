//
//  WindowController.swift
//  SkyWalker
//
//

import Cocoa

class WindowController : NSWindowController {

    override func windowDidLoad() {
        guard let menu = NSApp.menu else {
            return
        }
        let debugMenu = menu.item(withTitle: "Debug")
        if let showFolderMenu = debugMenu?.submenu?.item(withTag: 0) {
            showFolderMenu.state = Settings.showGPXFolder ? .on : .off
        }
        if let runScriptMenu = debugMenu?.submenu?.item(withTag: 1) {
            runScriptMenu.state = Settings.runScript ? .on : .off
        }
        if let showLabelMenu = debugMenu?.submenu?.item(withTag: 2) {
            showLabelMenu.state = Settings.showMessage ? .on : .off
        }
    }

    @IBAction func runScriptAction(with menu: NSMenuItem)  {
        let old = Settings.runScript
        menu.state = !old ? .on : .off
        Settings.runScript = !old
    }

    @IBAction func showMessageAction(with menu: NSMenuItem) {
        let old = Settings.showMessage
        menu.state = !old ? .on : .off
        Settings.showMessage = !old
    }

    @IBAction func showGPXFolderAction(with menu: NSMenuItem) {
        let old = Settings.showGPXFolder
        menu.state = !old ? .on : .off
        Settings.showGPXFolder = !old
    }

    override func keyDown(with event: NSEvent) {
        if let viewController = contentViewController as? ViewController {
            viewController.handleKeyDown(event: event)
            return
        }
        super.keyDown(with: event)
    }

    override func keyUp(with event: NSEvent) {
        if let viewController = contentViewController as? ViewController {
            viewController.handleKeyUp(event: event)
            return
        }
        super.keyUp(with: event)
    }
}
