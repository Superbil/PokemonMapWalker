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

    let fileContent = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><gpx version=\"1.0\"><name>Example gpx</name><wpt lat=\"\(atPoint.latitude)\" lon=\"\(atPoint.longitude)\"><name>WP</name></wpt></gpx>"
    do {
      try fileContent.write(to: gpxFileURL, atomically: true, encoding: String.Encoding.utf8)
      debugPrint("written GPX with Location (\(atPoint.latitude), \(atPoint.longitude))")
      if let block = block {
        block()
      }
    } catch {
      // do nothing
      debugPrint("error writing file")
    }
  }

  public func drawPoint(_ point: CLLocationCoordinate2D, block: (() -> Void)?) {
    makeGpxQueue.async(flags: .barrier) {
      self.makeGpxFile(withPoint: point, block: block)
    }
  }
}
