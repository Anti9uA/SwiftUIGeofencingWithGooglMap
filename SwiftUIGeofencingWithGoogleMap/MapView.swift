//
//  MapView.swift
//  SwiftUIGeofencingWithGoogleMap
//
//  Created by Kyubo Shim on 5/23/24.
//

import SwiftUI
import GoogleMaps

struct MapView: UIViewRepresentable {
    var coordinate: CLLocationCoordinate2D

    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: coordinate.latitude, longitude: coordinate.longitude, zoom: 14.0)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        mapView.clear()
        let marker = GMSMarker()
        marker.position = coordinate
        marker.map = mapView
        mapView.camera = GMSCameraPosition.camera(withLatitude: coordinate.latitude, longitude: coordinate.longitude, zoom: 14.0)
    }
}
#Preview {
    MapView(coordinate: CLLocationCoordinate2D(latitude: 37.240778, longitude: 131.869556))
}
