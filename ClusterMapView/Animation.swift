import Foundation
import MapKit

class Animation {
    
    struct MovingNode {
        var node: Node
        let coordinate: CLLocationCoordinate2D
        
        init(node: Node) {
            self.node = node
            self.coordinate = node.coordinate
        }
    }
    
    var node: Node
    var children: [MovingNode]
    var mapView: MKMapView
    
    init(node: Node, children: [Node], mapView: MKMapView) {
        self.node = node
        self.children = children.map { MovingNode(node: $0) }
        self.mapView = mapView
    }
    
    func prepare() {}
    func execute() {}
    func clean() {}
}
