import Foundation
import MapKit

public class Node: NSObject, MKAnnotation {
    
    public enum NodeType {
        case root(children: [Node])
        case node(parent: Node, children: [Node])
        case leaf(parent: Node, annotation: MKAnnotation)
    }
    
    private var annotation: MKAnnotation?
    var mapRect: MKMapRect
    private var mapPoint: MKMapPoint
    
    public dynamic var coordinate: CLLocationCoordinate2D
    
    private var parent: Node?
    private var children: [Node] = []
    private var depth: Int
    
    public var type: NodeType {
        switch (parent, children) {
        case (nil, let children):
            return .root(children: children)
        case (let parent?, let children) where children.isEmpty:
            return .leaf(parent: parent, annotation: annotation!)
        case (let parent?, let children):
            return .node(parent: parent, children: children)
        }
    }
    
    public var annotations: [MKAnnotation] {
        switch type {
        case .leaf(_, let annotation):
            return [annotation]
        case .root(let children), .node(_, let children):
            return children.flatMap { $0.annotations }
        }
    }
    
    public convenience init(annotations: [MKAnnotation]) {
        let markers = annotations.map { Marker(annotation: $0) }
        self.init(markers: markers)
    }
    
    init(markers: [Marker], depth: Int = 0) {
        self.depth = depth
        if markers.count == 1, let marker = markers.first {
            self.annotation = marker.annotation
            self.mapPoint = marker.mapPoint
            self.coordinate = MKCoordinateForMapPoint(mapPoint)
            self.mapRect = MKMapRect(origin: marker.mapPoint, size: .zero)
            super.init()
        } else {
            let (mapPoint, mapRect, children) = Marker.divide(markers: markers)
            self.mapPoint = mapPoint
            self.coordinate = MKCoordinateForMapPoint(mapPoint)
            self.mapRect = mapRect
            self.children = children.map {
                Node(markers: $0, depth: depth + 1)
            }
            super.init()
            // reference parent after self init
            self.children.forEach { $0.parent = self }
        }
    }
    
    func isParent(node: Node) -> Bool {
        guard let parent = node.parent else { return false }
        if parent == self {
            return true
        } else {
            return isParent(node: parent)
        }
    }
    
    func depthAndNodes(mapRect: MKMapRect, maximum: Int) -> (depth: Int, insideNodes: [Node], outsideNodes: [Node]) {
        
        var insideNodes: [Node] = [self]
        var outsideNodes = [Node]()
        
        var previousInside = [Node]()
        var previousOutside = [Node]()
        
        var nextInsideNodes = [Node]()
        var nextOutsideNodes = [Node]()
        
        // init depth to its node's
        var depth = self.depth
        
        // keep track of root/node nodes left
        var areNodesLeft = true
        
        // compute next level nodes
        while (insideNodes.count <= maximum && !insideNodes.isEmpty && areNodesLeft) {
            
            depth += 1
            
            // Save previous state
            previousInside = insideNodes
            previousOutside = outsideNodes
            
            nextInsideNodes = []
            nextOutsideNodes = []
            
            areNodesLeft = false
            
            for insideNode in insideNodes {
                switch insideNode.type {
                case .leaf:
                    // since this method is always called on a root/node node,
                    // only leaf nodes contained in the desired mapRect can be present in nodes
                    // so it is not necessary to check it here
                    nextInsideNodes.append(insideNode)
                case .node(_, let children), .root(let children):
                    for child in children {
                        switch child.type {
                        case .root, .node:
                            // if the root/node node intersects with the current mapRect
                            // then keep it as inside, toggle the flag
                            // else keep it as outside
                            if MKMapRectIntersectsRect(mapRect, child.mapRect) {
                                nextInsideNodes.append(child)
                                areNodesLeft = true
                            } else {
                                nextOutsideNodes.append(child)
                            }
                        case .leaf:
                            // if the child node is contained in current mapRect
                            // then keep it as inside
                            // else keep it as outside
                            if MKMapRectContainsPoint(mapRect, child.mapPoint) {
                                nextInsideNodes.append(child)
                            } else {
                                nextOutsideNodes.append(child)
                            }
                        }
                    }
                }
            }
            
            for outsideNode in outsideNodes {
                switch outsideNode.type {
                case .leaf:
                    nextOutsideNodes.append(outsideNode)
                case .node(_, let children), .root(let children):
                    nextOutsideNodes += children
                }
            }
            
            insideNodes = nextInsideNodes
            outsideNodes = nextOutsideNodes
        }
        
        if insideNodes.count > maximum {
            insideNodes = previousInside
            outsideNodes = previousOutside
            if depth > 0 {
                depth -= 1
            }
        }
        
        return (depth, insideNodes, outsideNodes)
    }
}
