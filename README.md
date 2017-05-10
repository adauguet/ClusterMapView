# ClusterMapView
An `MKMapView` subclass with clustering. Greatly inspired by `ADClusterMapView`.

## Features
- Swift implementation
- Principal Components Analysis algorithm
- Full tree's depth on the map view
- Animations

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

##Usage
1. Replace your `MKMapView` instance by a `ClusterMapView` instance.

2. Add annotations using  `setAnnotations`.

###ClusterMapViewDelegate
`ClusterMapView` has a `clusterMapViewDelegate` delegate property that you can use to get notified and to customize clustering parameters. `ClusterMapViewDelegate` is a subclass of `MKMapViewDelegate`.

Customise the maximum number of nodes that you want to see on your map:
```swift
var numberOfVisibleNodes: Int { get } // default 32
```

Customise the animation duration:
```swift
var animationDuration: Double { get } // default 0.4
```
Events:
```swift
func mapViewDidFinishClustering(_ mapView: MKMapView)
    
func mapViewDidFinishAnimating(_ mapView: MKMapView)
```