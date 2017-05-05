import Foundation

class SplitAnimation: Animation {
    
    override func prepare() {
        for child in children {
            child.node.coordinate = node.coordinate
            mapView.addAnnotation(child.node)
        }
        mapView.removeAnnotation(node)
    }
    
    override func execute() {
        for child in children {
            child.node.coordinate = child.coordinate
        }
    }
}
