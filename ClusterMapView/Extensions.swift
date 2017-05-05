import Foundation
import MapKit

public extension MKMapRect {
    init(mapPoints: [MKMapPoint]) {
        var mapRect = MKMapRectNull
        mapPoints.forEach {
            let pointRect = MKMapRect(origin: $0, size: .zero)
            if MKMapRectIsNull(mapRect) {
                mapRect = pointRect
            } else {
                mapRect = MKMapRectUnion(mapRect, pointRect)
            }
        }
        self.origin = mapRect.origin
        self.size = mapRect.size
    }
}

public extension MKMapSize {
    static var zero = MKMapSize(width: 0.0, height: 0.0)
}
