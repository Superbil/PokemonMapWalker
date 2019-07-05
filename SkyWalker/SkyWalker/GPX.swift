//
//  GPX.swift
//  SkyWalker
//
//

import Foundation
import CoreLocation

extension DateFormatter {
    static var iso8601 : DateFormatter {
        get {
            let df = DateFormatter()
            df.locale = Locale.current
            df.timeZone = TimeZone.current
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            return df
        }
    }
}

extension CLLocation {
    convenience init(coordinate: CLLocationCoordinate2D, timestamp: Date) {
        self.init(coordinate: coordinate,
                  altitude: kCLDistanceFilterNone,
                  horizontalAccuracy: kCLDistanceFilterNone,
                  verticalAccuracy: kCLDistanceFilterNone,
                  timestamp: timestamp)
    }
}

class GPXMaker {

    var locations: [CLLocation]

    init(locations l: [CLLocation]) {
        locations = l
    }

    var document: XMLDocument {
        get {
            return createDocument(withLocations: locations)
        }
    }

    func createDocument(withLocations locations: [CLLocation]) -> XMLDocument {
        var list: [XMLNode] = []
        for l in locations {
            let lon = XMLNode(kind: .attribute)
            lon.name = "lon"
            lon.stringValue = String(l.coordinate.longitude)

            let lat = XMLNode(kind: .attribute)
            lat.name = "lat"
            lat.stringValue = String(l.coordinate.latitude)

            var childrens: [XMLNode] = []
            let date = l.timestamp
            let dateElement = XMLNode(kind: .element)
            dateElement.name = "time"
            dateElement.stringValue = DateFormatter.iso8601.string(from: date)
            childrens.append(dateElement)

            let wpt = XMLElement()
            wpt.name = "wpt"
            wpt.attributes = [lon, lat]
            wpt.setChildren(childrens)

            list.append(wpt)
        }

        let gpx = XMLElement()
        gpx.name = "gpx"
        gpx.setChildren(list)
        let d = XMLDocument(rootElement: gpx)
        return d
    }
}
