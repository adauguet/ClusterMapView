import Foundation

class GroupAnimation: Animation {
    
    override func execute() {
        for child in children {
            child.node.coordinate = node.coordinate
        }
    }
    
    override func clean() {
        mapView.addAnnotation(node)
        for child in children {
            mapView.removeAnnotation(child.node)
            child.node.coordinate = child.coordinate
        }
    }
}
