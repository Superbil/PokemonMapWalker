//
//  ViewController.swift
//  SkyWalker
//
//

import Cocoa
import MapKit
import Dispatch

class ViewController: NSViewController {

    let headingDelta: CLLocationDirection = 0.2
    let moveDelta: CLLocationDegrees = 0.000001

    var heading: CLLocationDirection = 0.0
    var centerCoordinate = CLLocationCoordinate2D()

    let locationManager = CLLocationManager()

    var keyDownList = Set<Int>(minimumCapacity: 10)
    var keyHandlerDispatched: Bool = false

    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.showsBuildings = true
            mapView.mapType = .standard
            mapView.showsCompass = true
        }
    }
    @IBOutlet weak var resultLabel: NSTextField! {
        didSet {
            resultLabel.stringValue = ""
        }
    }

    var falcon: Falcon?
    let mapBuilder: MapBuilder = MapBuilder(fileName: "R2-D2.gpx")

    override func viewDidLoad() {
        super.viewDidLoad()

        // Get user location
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()

        do {
            falcon = try Falcon()
        } catch {
            debugPrint("Init Falcon failed")
        }

        jumpTo(location: kCLLocationCoordinate2DInvalid)
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
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
    }

    func executeStatus(_ result: Bool) {
        if Settings.showMessage == false {
            DispatchQueue.main.async {
                self.resultLabel.stringValue = ""
            }
            return
        }

        DispatchQueue.main.async {
            self.resultLabel.textColor = result ? .green : .red
            self.resultLabel.stringValue = result ? "Success" : "Failed"
        }
    }

    func jumpTo(location: CLLocationCoordinate2D) {
        if Settings.runScript == false {
            return
        }

        if CLLocationCoordinate2DIsValid(location) == false {
            do {
                try falcon?.resetJump()
            } catch {
                debugPrint("Can't reset")
                self.executeStatus(false)
            }
            return
        }

        mapBuilder.drawPoint(location) {
            guard let falcon = self.falcon else { return }

            do {
                try falcon.jumpToLightSpeed()
                self.executeStatus(true)
            } catch {
                self.executeStatus(false)
            }
        }
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

    func handleKeyDown(event: NSEvent) {
        guard
            let characters = event.charactersIgnoringModifiers,
            let keyValue = characters.unicodeScalars.first?.value
            else {
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

        default:
            return
        }
        dispatchKeyHandler()
    }

    func handleKeyUp(event: NSEvent) {
        guard
            let characters = event.charactersIgnoringModifiers,
            let keyValue = characters.unicodeScalars.first?.value
            else {
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

        default:
            break;
        }
    }

    func moveUp() {
        let scaleFactor = 1500.0 / mapView.camera.altitude
        centerCoordinate.longitude += (moveDelta * sin(heading*Double.pi/180.0) / scaleFactor)
        centerCoordinate.latitude += (moveDelta * cos(heading*Double.pi/180.0) / scaleFactor)
        updateCamera()

        jumpTo(location: centerCoordinate)
    }

    func moveDown() {
        let scaleFactor = 1500.0 / mapView.camera.altitude
        centerCoordinate.longitude -= (moveDelta * sin(heading*Double.pi/180.0) / scaleFactor)
        centerCoordinate.latitude -= (moveDelta * cos(heading*Double.pi/180.0) / scaleFactor)
        updateCamera()

        jumpTo(location: centerCoordinate)
    }

    func moveLeft() {
        heading -= headingDelta
        updateCamera()

        jumpTo(location: centerCoordinate)
    }

    func moveRight() {
        heading += headingDelta
        updateCamera()

        jumpTo(location: centerCoordinate)
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateTo newLocation: CLLocation, from oldLocation: CLLocation) {
        locationManager.stopUpdatingLocation()

        centerCoordinate = newLocation.coordinate

        updateCamera(mapInitialized: false)

        if let url = mapBuilder.gpxFileURL {
            let folderURL = url.deletingLastPathComponent
            NSWorkspace.shared.open(folderURL())
        }
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if (abs(mapView.centerCoordinate.latitude - centerCoordinate.latitude) > 0.00001
            || abs(mapView.centerCoordinate.longitude - centerCoordinate.longitude) > 0.00001) {
            centerCoordinate = mapView.centerCoordinate

            updateCamera()

            jumpTo(location: centerCoordinate)
        }
    }
}
