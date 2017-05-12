# ClusterMapView
An `MKMapView` subclass with clustering. Inspired by `ADClusterMapView`.

## Features
- [x] Swift implementation
- [x] Principal Components Analysis algorithm
- [x] Full tree's depth on the map view
- [x] Animations

## Tradeoffs
- Annotation encapsulation: for performance reasons, each annotation is encapsulated in a `Node` to keep track of its children and parent. The original annotation can be retrieved in the node's `annotation` property.
- Since the goal is to display all the tree (current depth) on the map, performance is slightly reduced, but sufficient for most use cases.

## Requirements
- iOS 8.0+
- Swift 3.0+
## Installation
### CocoaPods
```ruby
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'ClusterMapView'
end
```

## Usage
1. Replace your `MKMapView` instance by a `ClusterMapView` instance.

2. Add annotations using  `setAnnotations`.

### Annotation Views
As annotations are now encapsulated in nodes, you can observe each `Node`'s `type` property to adjust annotation views accordingly.

```swift
func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    if let node = annotation as? Node {
        var pin: MKPinAnnotationView!
        if let dequeued = mapView.dequeueReusableAnnotationView(withIdentifier: "pin") as? MKPinAnnotationView {
            pin = dequeued
            pin.annotation = node
        } else {
            pin = MKPinAnnotationView(annotation: node, reuseIdentifier: "pin")
        }
        switch node.type {
        case .leaf:
            pin.pinTintColor = .green
        case .node:
            pin.pinTintColor = .blue
        case .root:
            pin.pinTintColor = .red
        }
        return pin
    }
    return nil
}

```

### MKMapViewDelegate

`ClusterMapView` adds additional methods on `MKMapViewDelegate`.

Customize the maximum number of nodes that you want to see on your map:
```swift
var numberOfVisibleNodes: Int { get } // default 32
```

Customize the animation duration:
```swift
var animationDuration: Double { get } // default 0.4
```
Events:
```swift
func mapViewDidFinishClustering(_ mapView: MKMapView)
    
func mapViewDidFinishAnimating(_ mapView: MKMapView)
```
