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

  func makeGpxFile(withPoint atPoint: CLLocationCoordinate2D, block: (() -> Void)?) {
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

    let ls = [GPX(location: atPoint, date: Date())]
    let gpx = GPXMaker(locations: ls)

    do {
      let data = gpx.document.xmlData
      try data.write(to: gpxFileURL)
      debugPrint("written GPX with Location (\(atPoint.latitude), \(atPoint.longitude))")
    } catch {
      debugPrint("error writing file")
      return
    }

    if let block = block {
      block()
    }
  }

  public func drawPoint(_ point: CLLocationCoordinate2D, block: (() -> Void)?) {
    makeGpxQueue.async(flags: .barrier) {
      self.makeGpxFile(withPoint: point, block: block)
    }
  }
}
