//
//  GPX.swift
//  SkyWalker
//
//

import Foundation
import CoreLocation

struct GPX {
    var location: CLLocationCoordinate2D
    var date: Date?
}

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

class GPXMaker {

    var locations: [GPX]

    init(locations list: [GPX]) {
        locations = list
    }

    var document: XMLDocument {
        get {
            return createDocument(withLocations: locations)
        }
    }

    func createDocument(withLocations locations: [GPX]) -> XMLDocument {
        var list: [XMLNode] = []
        for l in locations {
            let lon = XMLNode(kind: .attribute)
            lon.name = "lon"
            lon.stringValue = String(l.location.longitude)

            let lat = XMLNode(kind: .attribute)
            lat.name = "lat"
            lat.stringValue = String(l.location.latitude)

            var childrens: [XMLNode] = []
            if let date = l.date {
                let dateElement = XMLNode(kind: .element)
                dateElement.name = "time"
                dateElement.stringValue = DateFormatter.iso8601.string(from: date)
                childrens.append(dateElement)
            }

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
