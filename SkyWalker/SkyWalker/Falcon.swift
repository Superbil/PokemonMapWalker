//
//  Falcon.swift
//  SkyWalker
//
//

import Foundation
import Carbon

class Falcon {

  public var projectName: String = "LocationSimulation"
  public var menuItemName: String = "R2-D2"

  private var applyGpxScript: NSAppleScript?

  init() {
    let name = "ApplyGPX"
    guard let path = Bundle.main.path(forResource: name, ofType: "scpt") else {
      assertionFailure("\(name).scpt not found.")
      return
    }
    let url = NSURL(fileURLWithPath: path)
    var errors: NSDictionary?
    guard let script = NSAppleScript(contentsOf: url as URL, error: &errors) else {
      assertionFailure("\(name).scpt script init failed.")
      return
    }
    self.applyGpxScript = script
  }

  private func selectLocation(projectName: String, simulateLocation: String) {
    guard let script = applyGpxScript else {
      debugPrint("applyGpxScript is null")
      return
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
    }
  }

  func jumpToLightSpeed() {
    selectLocation(projectName: projectName, simulateLocation: menuItemName)
  }
}
