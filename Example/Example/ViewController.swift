//
//  ViewController.swift
//  ClusterMapViewDemo
//
//  Created by Antoine DAUGUET on 02/05/2017.
//
//

import UIKit
import MapKit
import ClusterMapView

class ViewController: UIViewController {
    
    @IBOutlet weak var mapView: ClusterMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        let path = Bundle.main.path(forResource: "Toilets", ofType: "json")!
        //        let url = URL(fileURLWithPath: path)
        //        let data = try! Data(contentsOf: url)
        //        let json = try! JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [[String : Any]]
        //        let toilets = Toilet.foo(json: json)
        //        mapView.delegate = mapView
        //        mapView.setAnnotations(toilets)
        
        let path = Bundle.main.path(forResource: "Streetlights", ofType: "json")!
        let url = URL(fileURLWithPath: path)
        let data = try! Data(contentsOf: url)
        let json = try! JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [[String : Any]]
        let streetlights = Streetlight.foo(json: json)
        mapView.delegate = self
        mapView.setAnnotations(streetlights)
    }
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if let mapView = mapView as? ClusterMapView {
            mapView.updateNodes(animated: animated)
        }
    }
    
    func mapViewDidFinishClustering(_ mapView: ClusterMapView) {
        print(#function)
    }
    
    func mapViewDidFinishAnimating(_ mapView: ClusterMapView) {
        print(#function)
    }
    
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
}
