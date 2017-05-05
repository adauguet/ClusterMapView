import MapKit

public protocol ClusterMapViewDelegate: MKMapViewDelegate {
    var numberOfVisibleClusters: Int { get }
    
    var animationDuration: Double { get }
    
    func mapViewDidFinishClustering(_ mapView: MKMapView)
    
    func mapViewDidFinishAnimating(_ mapView: MKMapView)
}

public class ClusterMapView: MKMapView, MKMapViewDelegate {
    
    private var root: Node?
    private var depth: Int?
    private var isAnimating = false
    private var shouldComputeClusters = false
    
    public var clusterMapViewDelegate: ClusterMapViewDelegate? {
        didSet {
            self.delegate = self
        }
    }
    
    private func sortedNodes(mapRect: MKMapRect) -> (insideNodes: [Node], outsideNodes: [Node]) {
        var insideNodes = [Node]()
        var outsideNodes = [Node]()
        for annotation in self.annotations {
            if let node = annotation as? Node {
                if MKMapRectIntersectsRect(mapRect, node.mapRect) {
                    insideNodes.append(node)
                } else {
                    outsideNodes.append(node)
                }
            }
        }
        return (insideNodes, outsideNodes)
    }
    
    // MARK: - MKMapViewDelegate
    
    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        for annotation in selectedAnnotations {
            deselectAnnotation(annotation, animated: true)
        }
        if isAnimating {
            shouldComputeClusters = true
        } else {
            isAnimating = true
            displayAnnotations(animated: true)
            isAnimating = false
        }
        clusterMapViewDelegate?.mapView?(mapView, regionDidChangeAnimated: animated)
    }
    
    public func setAnnotations(_ annotations: [MKAnnotation]) {
        root = Node(annotations: annotations)
        clusterMapViewDelegate?.mapViewDidFinishClustering(self)
        displayAnnotations(animated: true)
    }
    
    // MARK: - Clusters manipulations and animations (the great part)
    
    private func displayAnnotations(animated: Bool) {
        
        // Check that the root cluster is instanciated for the map, i.e. if there is any annotations to manage.
        guard let root = root else { return }
        
        // If the transition is not animated, just set the mapRect to MKMapRectNull.
        // This way, all annotations will be outside, and no animations will be instanciated.
        let mapRect = animated ? visibleMapRect : MKMapRectNull
        
        // Get the maximum number of annotations.
        let maximum: Int = clusterMapViewDelegate?.numberOfVisibleClusters ?? 32
        
        // Compute desired depth with corresponding inside/outside annotations.
        let (depth, newInsideNodes, newOutsideNodes) = root.depthAndNodes(mapRect: mapRect, maximum: maximum)
        
        // Depth is not set at first call: just add all desired annotations.
        guard let actualDepth = self.depth else {
            
            // Add all annotations
            super.addAnnotations(newInsideNodes + newOutsideNodes)
            
            // Set actual depth
            self.depth = depth
            return
        }
        
        print("actualDepth: \(actualDepth)", "depth: \(depth)")
        
        // If the desired depth equals the actual depth, just return.
        // If the desired depth is superior to the actual depth, nodes are going to divide.
        // If the desired depth is inferior to the actual depth, nodes are going to regroup.
        var animations: [Animation] = []
        if depth == actualDepth { return }
        
        // get inside/outside nodes
        // an inside node can be outside the visible map rect if its map rect intersects
        let (insideNodes, outsideNodes) = sortedNodes(mapRect: mapRect)
        
        if depth > actualDepth { // divide nodes
            
            var newInsideNodesSet = Set(newInsideNodes)
            
            // for each inside node, look for children in new inside nodes
            // do not affect leaf inside nodes
            for insideNode in insideNodes {
                switch insideNode.type {
                case .leaf:
                    break
                case .node, .root:
                    var children: [Node] = []
                    for newInsideNode in newInsideNodesSet {
                        if insideNode.isParent(node: newInsideNode) {
                            children.append(newInsideNode)
                            newInsideNodesSet.remove(newInsideNode)
                        }
                    }
                    animations.append(SplitAnimation(node: insideNode, children: children, mapView: self))
                }
            }
            
            print("newInsideNodesSet.count: \(newInsideNodesSet.count)")
            
            removeAnnotations(outsideNodes)
            addAnnotations(newOutsideNodes)
        } else { // regroup nodes
            
            var insideNodesSet = Set(insideNodes)
            
            // for each new inside node, look for children in inside nodes
            // do not affect leaf new inside nodes
            for newInsideNode in newInsideNodes {
                switch newInsideNode.type {
                case .leaf:
                    break
                case .node, .root:
                    var children: [Node] = []
                    for insideNode in insideNodesSet {
                        if newInsideNode.isParent(node: insideNode) {
                            children.append(insideNode)
                            insideNodesSet.remove(insideNode)
                        }
                    }
                    animations.append(GroupAnimation(node: newInsideNode, children: children, mapView: self))
                }
            }
            
            print("insideNodesSet.count: \(insideNodesSet.count)")
            
            removeAnnotations(outsideNodes)
            addAnnotations(newOutsideNodes)
        }
        
        // Prepare animations (manipulate annotations coordinates, perform add/remove).
        animations.forEach { $0.prepare() }
        
        // Perform animations.
        // NOTE: DO NOT use add/remove annotations methods inside an animation, as an MKMapView is not really adding/removing them but setting their coordinates to an invalid (outside visibleMapRect) location. Using those methods within an animation could cause unexpected behavior.
        UIView.animate(withDuration: clusterMapViewDelegate?.animationDuration ?? 0.4, animations: {
            
            // Execute animations (change coordinates)
            animations.forEach { $0.execute() }
        }, completion: { (_) in
            
            // Clean animations (manipulate annotations coordinates, perform add/remove).
            animations.forEach { $0.clean() }
            
            // Finally, update the mapView's current depth.
            self.depth = depth
            
            // notify delegate
            self.clusterMapViewDelegate?.mapViewDidFinishAnimating(self)
        })
    }
}
