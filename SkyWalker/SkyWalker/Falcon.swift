//
//  Falcon.swift
//  SkyWalker
//
//

import Foundation
import Carbon

enum FalconError: Error {

    case noScript(name: String)
    case engineEmpty
    case noAuth
    case executeFailed(errors: NSDictionary)

    func errorMessage() -> String {
        switch self {
        case .noScript(let name):
            return "\(name).scpt not found."
        case .engineEmpty:
            return "applyGpxScript is null"
        case .noAuth:
            return "Require Auth"
        case .executeFailed(let errors):
            return errors.description
        }
    }
}

class Falcon {

  public var projectName: String = "LocationSimulation"
  public var menuItemName: String = "R2-D2"

  private var applyGpxScript: NSAppleScript?

  init() throws {
    let name = "ApplyGPX"
    guard let path = Bundle.main.path(forResource: name, ofType: "scpt") else {
      assertionFailure("\(name).scpt not found.")
      throw FalconError.noScript(name: name)
    }
    let url = NSURL(fileURLWithPath: path)
    var errors: NSDictionary?
    guard let script = NSAppleScript(contentsOf: url as URL, error: &errors) else {
      assertionFailure("\(name).scpt script init failed.")
      throw FalconError.noScript(name: name)
    }
    self.applyGpxScript = script
  }

  private func selectLocation(projectName: String, simulateLocation: String) throws {
    guard let script = applyGpxScript else {
      debugPrint("applyGpxScript is null")
      throw FalconError.engineEmpty
    }

    let handler = NSAppleEventDescriptor(string: "selectLocation")

    let parameters = NSAppleEventDescriptor(listDescriptor: ())
    parameters.insert(NSAppleEventDescriptor(string: projectName), at: 1)
    parameters.insert(NSAppleEventDescriptor(string: simulateLocation), at: 2)

    var psn = ProcessSerialNumber(highLongOfPSN: UInt32(0), lowLongOfPSN: UInt32(kCurrentProcess))
    let target = NSAppleEventDescriptor(descriptorType: typeProcessSerialNumber, bytes: &psn, length: MemoryLayout<ProcessSerialNumber>.size)
    let event = NSAppleEventDescriptor.appleEvent(withEventClass: AEEventClass(kASAppleScriptSuite),
                                                  eventID: AEEventID(kASSubroutineEvent),
                                                  targetDescriptor: target,
                                                  returnID: AEReturnID(kAutoGenerateReturnID),
                                                  transactionID: AETransactionID(kAnyTransactionID))

    event.setParam(handler, forKeyword: AEKeyword(keyASSubroutineName))
    event.setParam(parameters, forKeyword: AEKeyword(keyDirectObject))

    var errors: NSDictionary?
    script.executeAppleEvent(event, error: &errors)
    if let errors = errors {
        debugPrint("Error executing AppleScript: \(errors.description)")
        debugPrint(errors[NSAppleScript.errorMessage] as! String)
        let errorNumber = errors[NSAppleScript.errorNumber] as! NSNumber
        if errorNumber.intValue == -25211 {
            throw FalconError.noAuth
        }
        throw FalconError.executeFailed(errors: errors)
    }
  }

  func jumpToLightSpeed() throws {
      try selectLocation(projectName: projectName, simulateLocation: menuItemName)
  }

  func resetJump() throws {
    // Nil is special keyword to select location `Don't simulate Location`
    try selectLocation(projectName: projectName, simulateLocation: "Nil")
  }
}
