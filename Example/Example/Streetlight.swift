import Foundation
import MapKit

public class Streetlight: NSObject, MKAnnotation {
    var name: String
    public var coordinate: CLLocationCoordinate2D
    
    public init?(json: [String : Any]) {
        guard
            let name = json["name"] as? String,
            let coordinate = json["coordinates"] as? [String : Any],
            let latitude = coordinate["latitude"] as? Double,
            let longitude = coordinate["longitude"] as? Double else { return nil }
        self.name = name
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
