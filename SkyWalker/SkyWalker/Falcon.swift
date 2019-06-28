//
//  Falcon.swift
//  SkyWalker
//
//

import Foundation
import Carbon

class Falcon {

  private var applyGpxScript: NSAppleScript!

  init() {
    let name = "ApplyGPX"
    guard let path = Bundle.main.path(forResource: name, ofType: "scpt") else {
      assertionFailure("\(name).scpt Script not found.")
      return
    }
    let url = NSURL(fileURLWithPath: path)
    var errors: NSDictionary?
    self.applyGpxScript = NSAppleScript(contentsOf: url as URL, error: &errors)
    if let errors = errors {
      debugPrint("Error creating AppleScript: \(errors.description)")
    }
  }

  func jumpToLightSpeed() {
    if applyGpxScript.isCompiled == false {
      debugPrint("applyGpxScript is not compiled")
      return
    }
    var errorDict: NSDictionary?
    applyGpxScript.executeAndReturnError(&errorDict)
    if errorDict != nil {
      debugPrint("Error executing AppleScript: \(errorDict?.description ?? "")")
    }
  }
}
