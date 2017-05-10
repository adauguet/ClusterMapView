Pod::Spec.new do |s|
  s.name         = "ClusterMapView"
  s.version      = "1.0.1"
  s.summary      = "A Swift clustering implementation."
  s.description  = "ClusterMapView is a swift implemntation of a clustering solution. Inspired by Applidium's ADClusterMapView pod, it uses a PCA algorithm. Among differences are the fact that it deliberately displays all annotations on the map instead of using a recycling process. This slightly reduces performance but you see the actual annotations when panning the map view."
  s.homepage     = "https://github.com/adauguet/ClusterMapView"
  s.license      = "MIT"
  s.author       = { "Antoine DAUGUET" => "dauguet.antoine@gmail.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/adauguet/ClusterMapView.git", :tag => s.version }
  s.source_files  = "ClusterMapView", "ClusterMapView/**/*.{h,m,swift}"
  s.exclude_files = "ClusterMapView/ClusterMapView.h", "ClusterMapView/Info.plist"
end
