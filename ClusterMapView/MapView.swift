import MapKit

public extension MKMapViewDelegate {
    var numberOfVisibleNodes: Int {
        return 32
    }
    
    var animationDuration: Double {
        return 0.4
    }
    
    func mapViewDidFinishClustering(_ mapView: ClusterMapView) {}
    
    func mapViewDidFinishAnimating(_ mapView: ClusterMapView) {}
}

public class ClusterMapView: MKMapView {
    
    private var root: Node?
    private var depth: Int?
    private var isAnimating = false
    private var shouldComputeNodes = false
    
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
    
    public func updateNodes(animated: Bool) {
        selectedAnnotations.forEach {
            deselectAnnotation($0, animated: true)
        }
        if isAnimating {
            shouldComputeNodes = true
        } else {
            isAnimating = true
            displayAnnotations(animated: true)
        }
    }
    
    public func setAnnotations(_ annotations: [MKAnnotation]) {
        root = Node(annotations: annotations)
        delegate?.mapViewDidFinishClustering(self)
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
        let maximum: Int = delegate?.numberOfVisibleNodes ?? 32
        
        // Compute desired depth with corresponding inside/outside annotations.
        let (depth, newInsideNodes, newOutsideNodes) = root.depthAndNodes(mapRect: mapRect, maximum: maximum)
        
        // Depth is not set at first call: just add all desired annotations.
        guard let actualDepth = self.depth else {
            
            // Add all annotations
            super.addAnnotations(newInsideNodes + newOutsideNodes)
            
            // Set actual depth
            self.depth = depth
            
            isAnimating = false
            
            return
        }
        
        print("actualDepth: \(actualDepth)", "depth: \(depth)")
        
        // If the desired depth equals the actual depth, just return.
        // If the desired depth is superior to the actual depth, nodes are going to divide.
        // If the desired depth is inferior to the actual depth, nodes are going to regroup.
        var animations: [Animation] = []
        if depth == actualDepth {
            isAnimating = false
            return
        }
        
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
            
            removeAnnotations(outsideNodes)
            addAnnotations(newOutsideNodes)
        }
        
        // Prepare animations (manipulate annotations coordinates, perform add/remove).
        animations.forEach { $0.prepare() }
        
        // Perform animations.
        // NOTE: DO NOT use add/remove annotations methods inside an animation, as an MKMapView is not really adding/removing them but setting their coordinates to an invalid (outside visibleMapRect) location. Using those methods within an animation could cause unexpected behavior.
        UIView.animate(withDuration: delegate?.animationDuration ?? 0.4, animations: {
            
            // Execute animations (change coordinates)
            animations.forEach { $0.execute() }
        }) { _ in
            
            // Clean animations (manipulate annotations coordinates, perform add/remove).
            animations.forEach { $0.clean() }
            
            // Finally, update the mapView's current depth.
            self.depth = depth
            
            if self.shouldComputeNodes {
                self.shouldComputeNodes = false
                self.displayAnnotations(animated: animated)
            } else {
                // notify delegate
                self.isAnimating = false
                self.delegate?.mapViewDidFinishAnimating(self)
            }
        }
    }
}
