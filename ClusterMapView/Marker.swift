import Foundation
import MapKit

class Marker {
    
    let annotation: MKAnnotation
    let mapPoint: MKMapPoint
        
    init(annotation: MKAnnotation) {
        self.annotation = annotation
        self.mapPoint = MKMapPointForCoordinate(annotation.coordinate)
    }
    
    // principal components analysis
    static func divide(markers: [Marker]) -> (mapPoint: MKMapPoint, mapRect: MKMapRect, children: [[Marker]]) {
        
        let precision = 1E04
        
        var XSum: Double = 0.0
        var YSum: Double = 0.0
        
        for marker in markers {
            XSum += marker.mapPoint.x
            YSum += marker.mapPoint.y
        }
        
        let XMean = XSum / Double(markers.count)
        let YMean = YSum / Double(markers.count)
        
        // compute coefficients
        
        var sumXsquared: Double = 0.0
        var sumYsquared: Double = 0.0
        var sumXY: Double = 0.0
        
        for marker in markers {
            let x = marker.mapPoint.x - XMean
            let y = marker.mapPoint.y - YMean
            sumXsquared += x * x
            sumYsquared += y * y
            sumXY += x * y
        }
        
        var x: Double = 0.0
        var y: Double = 0.0
        
        if (fabs(sumXY)/Double(markers.count) > precision) {
            x = sumXY
            let lambda = 0.5 * ((sumXsquared + sumYsquared) + sqrt((sumXsquared + sumYsquared) * (sumXsquared + sumYsquared) + 4 * sumXY * sumXY))
            y = lambda - sumXsquared
        } else {
            x = sumXsquared > sumYsquared ? 1.0 : 0.0
            y = sumXsquared > sumYsquared ? 0.0 : 1.0
        }
        
        var leftMarkers = [Marker]()
        var rightMarkers = [Marker]()
        
        if (fabs(sumXsquared) / Double(markers.count) < precision || fabs(sumYsquared) / Double(markers.count) < precision) {
            let index = markers.count / 2
            leftMarkers = Array(markers[0..<index])
            rightMarkers = Array(markers[index..<markers.count])
        } else {
            for marker in markers {
                if (marker.mapPoint.x - XMean) * x + (marker.mapPoint.y - YMean) * y > 0.0 {
                    leftMarkers.append(marker)
                } else {
                    rightMarkers.append(marker)
                }
            }
        }
        
        // compute map point
        let mapPoint = MKMapPoint(x: XMean, y: YMean)
        
        // compute map rect
        let mapRect = MKMapRect(mapPoints: markers.map { $0.mapPoint })
        
        return (mapPoint, mapRect, [leftMarkers, rightMarkers])
    }
}
