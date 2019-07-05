//
//  MapBuilder.swift
//  SkyWalker
//
//

import Foundation
import CoreLocation

class MapBuilder {

    public var gpxFileName: String?
    public var gpxFileURL: URL?

    init(fileName: String) {
        self.gpxFileName = fileName

        var fileURL: URL = NSURL(string: fileName)! as URL
        if let l = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first {
            let lURL = NSURL(fileURLWithPath: l, isDirectory: true)
            let projectName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
            let aURL = lURL.appendingPathComponent(projectName)!
            let fURL = aURL.appendingPathComponent(fileName)
            fileURL = fURL.absoluteURL
            self.gpxFileURL = fileURL
        }
    }

    private let makeGpxQueue: DispatchQueue = DispatchQueue(label: "makeGpxQueue")

    func makeGpxFile(gpxs: [GPX], block: (() -> Void)?) {
        guard let gpxFileURL = gpxFileURL else {
            assertionFailure("Must setup gpxFileURL")
            return
        }

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

        let gpx = GPXMaker(locations: gpxs)

        do {
            let data = gpx.document.xmlData
            try data.write(to: gpxFileURL)
        } catch {
            debugPrint("error writing file")
            return
        }

        if let block = block {
            block()
        }
    }

    private func makePointIn(center: CLLocationCoordinate2D, distance: CLLocationDistance = 10) -> CLLocationCoordinate2D {

        let lat = center.latitude
        let lon = center.longitude
        let radius = distance / 1000

        let cr = CLCircularRegion(center: center, radius: radius, identifier: "cr")

        var foundLocation: CLLocationCoordinate2D = center
        var checkLocation = false

        let r = radius / 1000
        while checkLocation == false {
            let rlat = Double.random(in: lat - r ... lat + r)
            let rLon = Double.random(in: lon - r ... lon + r)
            let newLocation = CLLocationCoordinate2D(latitude: rlat, longitude: rLon)
            if cr.contains(newLocation) && CLLocationCoordinate2DIsValid(newLocation) {
                checkLocation = true
                foundLocation = newLocation
                break
            }
        }

        return foundLocation
    }

    public func drawPoint(_ point: CLLocationCoordinate2D, block: (() -> Void)?) {

        let startDate = Date()
        var gpxs: [GPX] = []
        gpxs.append(GPX(location: point, date: startDate))

        for i in 1...3 {
            let l = self.makePointIn(center: point)

            let calender = Calendar.current
            let nextDate = calender.date(byAdding: .second, value: i, to: startDate)

            gpxs.append(GPX(location: l, date: nextDate))
        }

        makeGpxQueue.async(flags: .barrier) {
            self.makeGpxFile(gpxs: gpxs, block: block)
        }
    }
}
