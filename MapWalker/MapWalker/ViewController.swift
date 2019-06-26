//
//  ViewController.swift
//  MapWalker
//
//  Created by Brian Wang on 8/7/16.
//  Copyright © 2016 MapWalker. All rights reserved.
//

import Cocoa
import MapKit
import Dispatch

class ViewController: NSViewController, MKMapViewDelegate, CLLocationManagerDelegate {

  let headingDelta: CLLocationDirection = 0.2
  let moveDelta: CLLocationDegrees = 0.000001

  var heading: CLLocationDirection = 0.0
  var centerCoordinate = CLLocationCoordinate2D()

  let locationManager = CLLocationManager()

  var keyDownList = Set<Int>(minimumCapacity: 10)
  var keyHandlerDispatched:Bool = false

  let makeGpxQueue: DispatchQueue = DispatchQueue.init(label: "com.example.MyQueue1")
  let runGpxQueue: DispatchQueue = DispatchQueue.init(label: "com.example.MyQueue2")
  var scriptExecutionQueued: Bool = false
  var makeGpxFileQueued: Bool = false
  var applyGpxScript: NSAppleScript!

  var gpxFileURL: URL = NSURL(string: "MapWalker.gpx")! as URL

  @IBOutlet weak var mapView: MKMapView!

  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.

    prepareApplyGpxScript()

    // Get user location
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.startUpdatingLocation()

    mapView.showsBuildings = true
    mapView.mapType = .standard
    mapView.isRotateEnabled = false
    mapView.isPitchEnabled = false

    if let l = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first {
      let lURL = NSURL(fileURLWithPath: l, isDirectory: true)
      let aURL = lURL.appendingPathComponent("MapWalker")!
      let fURL = aURL.appendingPathComponent("MapWalker.gpx")
      gpxFileURL = fURL.absoluteURL
    }
  }

  override var representedObject: Any? {
    didSet {
    // Update the view, if already loaded.
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateTo newLocation: CLLocation, from oldLocation: CLLocation) {
    locationManager.stopUpdatingLocation()

    centerCoordinate = newLocation.coordinate
    /*
    let viewRegion = MKCoordinateRegionMake(centerCoordinate, MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
    let adjustedRegion = mapView.regionThatFits(viewRegion)
    mapView.setRegion(adjustedRegion, animated: true)
 */
    updateCamera(mapInitialized: false)
    makeGpxFile()
    let folderUrl = gpxFileURL.deletingLastPathComponent
//    NSWorkspace.shared.open(folderUrl())
  }

  func updateCamera(mapInitialized:Bool = true) {
    var distance = 500.0
    if mapInitialized {
        distance = mapView.camera.altitude / cos(Double.pi*(Double(mapView.camera.pitch)/180.0))
    }
    let camera = MKMapCamera(lookingAtCenter: centerCoordinate,
                             fromDistance: distance,
                             pitch: 45,
                             heading: heading)
    mapView.camera = camera
    postMakeGpxFileTask()
  }

  func synchronized(lock:AnyObject, closure: () -> ()) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
  }

  func prepareApplyGpxScript() {
    guard let path = Bundle.main.path(forResource: "ApplyGPX", ofType: "scpt") else {
      assertionFailure("Script not found.")
      return
    }
    let url = NSURL(fileURLWithPath: path)
    var errorDict:NSDictionary?
    self.applyGpxScript = NSAppleScript(contentsOf: url as URL, error: &errorDict)
    if errorDict != nil {
        debugPrint("Error creating AppleScript: \(errorDict?.description ?? "")")
      return
    }
  }

  func postApplyGpxScriptTask() {
    synchronized(lock: self) {
      if !scriptExecutionQueued {
        scriptExecutionQueued = true
        runGpxQueue.async {
          self.executeApplyGpxScript()
        }
      }
    }
  }

  func executeApplyGpxScript() {
    var errorDict:NSDictionary? = nil
    applyGpxScript.executeAndReturnError(&errorDict)
    if errorDict != nil {
      debugPrint("Error executing AppleScript: \(errorDict?.description ?? "")")
    }
    scriptExecutionQueued = false
  }

  func postMakeGpxFileTask() {
    synchronized(lock: self) {
      if !makeGpxFileQueued {
        makeGpxFileQueued = true
        makeGpxQueue.async {
          self.makeGpxFile()
        }
      }
    }
  }

  func makeGpxFile() {
    let folderUrl: URL = gpxFileURL.deletingLastPathComponent()
    var isDirectory = ObjCBool(true)
    if FileManager.default.fileExists(atPath: folderUrl.relativePath, isDirectory: &isDirectory) == false {
      debugPrint("Create folder: \(folderUrl.absoluteString)")
      do {
        try FileManager.default.createDirectory(at: folderUrl, withIntermediateDirectories: true, attributes: nil)
      } catch {
        debugPrint("Create folder failed")
      }
    }

    let fileContent = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><gpx version=\"1.0\"><name>Example gpx</name><wpt lat=\"\(centerCoordinate.latitude)\" lon=\"\(centerCoordinate.longitude)\"><name>WP</name></wpt></gpx>"
    do {
      try fileContent.write(to: gpxFileURL, atomically: true, encoding: String.Encoding.utf8)
      debugPrint("written GPX file with Location (\(centerCoordinate.latitude), \(centerCoordinate.longitude))")
      self.postApplyGpxScriptTask()
    } catch {
      // do nothing
      debugPrint("error writing file")
    }
    makeGpxFileQueued = false
  }

  func keyHandler() {
    if keyDownList.count == 0 {
      keyHandlerDispatched = false
      return
    }

    if (keyDownList.contains(NSUpArrowFunctionKey)) {
      moveUp()
    }
    if (keyDownList.contains(NSDownArrowFunctionKey)) {
      moveDown()
    }
    if (keyDownList.contains(NSLeftArrowFunctionKey)) {
      moveLeft()
    }
    if (keyDownList.contains(NSRightArrowFunctionKey)) {
      moveRight()
    }
    DispatchQueue.main.async {
      self.keyHandler()
    }
  }

  func dispatchKeyHandler() {
    if keyHandlerDispatched {
      return
    }
    keyHandlerDispatched = true
    DispatchQueue.main.async {
      self.keyHandler()
    }
  }

  func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    if (abs(mapView.centerCoordinate.latitude - centerCoordinate.latitude) > 0.00001
       || abs(mapView.centerCoordinate.longitude - centerCoordinate.longitude) > 0.00001) {
      centerCoordinate = mapView.centerCoordinate
      updateCamera()
    }
  }

  func handleKeyDown(event: NSEvent) {
    guard let characters = event.charactersIgnoringModifiers else {
      return
    }
    guard let keyValue = characters.unicodeScalars.first?.value else {
      return
    }
    switch (Int(keyValue)) {
    case NSUpArrowFunctionKey:
      keyDownList.insert(NSUpArrowFunctionKey)
    case NSDownArrowFunctionKey:
      keyDownList.insert(NSDownArrowFunctionKey)
    case NSLeftArrowFunctionKey:
      keyDownList.insert(NSLeftArrowFunctionKey)
    case NSRightArrowFunctionKey:
      keyDownList.insert(NSRightArrowFunctionKey)

    case Int((String("w").unicodeScalars.first?.value)!):
      keyDownList.insert(NSUpArrowFunctionKey)
    case Int((String("s").unicodeScalars.first?.value)!):
      keyDownList.insert(NSDownArrowFunctionKey)
    case Int((String("a").unicodeScalars.first?.value)!):
      keyDownList.insert(NSLeftArrowFunctionKey)
    case Int((String("d").unicodeScalars.first?.value)!):
      keyDownList.insert(NSRightArrowFunctionKey)

    case Int((String("=").unicodeScalars.first?.value)!):
      keyDownList.insert(Int((String("=").unicodeScalars.first?.value)!))
    case Int((String("-").unicodeScalars.first?.value)!):
      keyDownList.insert(Int((String("+").unicodeScalars.first?.value)!))
    default:
      return
    }
    dispatchKeyHandler()
  }

  func handleKeyUp(event: NSEvent) {
    guard let characters = event.charactersIgnoringModifiers else {
      return
    }
    guard let keyValue = characters.unicodeScalars.first?.value else {
      return
    }
    switch (Int(keyValue)) {
    case NSUpArrowFunctionKey:
      keyDownList.remove(NSUpArrowFunctionKey)
    case NSDownArrowFunctionKey:
      keyDownList.remove(NSDownArrowFunctionKey)
    case NSLeftArrowFunctionKey:
      keyDownList.remove(NSLeftArrowFunctionKey)
    case NSRightArrowFunctionKey:
      keyDownList.remove(NSRightArrowFunctionKey)

    case Int((String("w").unicodeScalars.first?.value)!):
      keyDownList.remove(NSUpArrowFunctionKey)
    case Int((String("s").unicodeScalars.first?.value)!):
      keyDownList.remove(NSDownArrowFunctionKey)
    case Int((String("a").unicodeScalars.first?.value)!):
      keyDownList.remove(NSLeftArrowFunctionKey)
    case Int((String("d").unicodeScalars.first?.value)!):
      keyDownList.remove(NSRightArrowFunctionKey)

    case Int((String("=").unicodeScalars.first?.value)!):
      keyDownList.remove(Int((String("=").unicodeScalars.first?.value)!))
    case Int((String("-").unicodeScalars.first?.value)!):
      keyDownList.remove(Int((String("+").unicodeScalars.first?.value)!))
    default:
        break;
    }
  }

  func moveUp() {
    let scaleFactor = 1500.0 / mapView.camera.altitude
    centerCoordinate.longitude += moveDelta * sin(Double(heading)*Double.pi/180.0) / scaleFactor
    centerCoordinate.latitude += moveDelta * cos(Double(heading)*Double.pi/180.0) / scaleFactor
    updateCamera()
  }

  func moveDown() {
    let scaleFactor = 1500.0 / mapView.camera.altitude
    centerCoordinate.longitude -= moveDelta * sin(Double(heading)*Double.pi/180.0) / scaleFactor
    centerCoordinate.latitude -= moveDelta * cos(Double(heading)*Double.pi/180.0) / scaleFactor
    updateCamera()
  }

  func moveLeft() {
    heading -= headingDelta
    updateCamera()
  }

  func moveRight() {
    heading += headingDelta
    updateCamera()
  }
}
