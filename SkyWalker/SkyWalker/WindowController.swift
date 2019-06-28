//
//  WindowController.swift
//  SkyWalker
//
//

import Cocoa

class WindowController : NSWindowController {
  
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
