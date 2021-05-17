//
//  ViewController.swift
//  A1_iOS_GurinderSingh_C0806087
//
//  Created by Gurinder Singh on 16/05/21.
//  Copyright © 2021 Gurinder Singh. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    //MARK:- IBOutlets
    @IBOutlet weak var map: MKMapView!
    
    //MARK:- MemberVariables
    let locationManager = CLLocationManager() // To get current location
    
    var distance = CLLocationDistance() // To find the distance between marker and current location
    
    var loader : UIView? // create a loader before getting automobille distance
    
    var tapGesture = UITapGestureRecognizer() // To Create Markers on the map view
    
    var tapPoint = CGPoint() // To get cgpoint when tap on the map view
    
    var isLastRoutePending = true // To check whether route created between C And A or not
    
    var arrSelectedCoordinates = Array<CLLocationCoordinate2D>() // Create array to add coordinates of created markers
    
    var centerCoordinate = CLLocationCoordinate2D() // To get the center point of created triangle MKPolygon
    
    var polygon = MKPolygon() // Create variable for MKPolygon class
    
    var directionsArray: [MKDirections] = [] // To get the directions for creating polylines on the map
    
    var isPolygonOverlayActive = true // To check which overlay is active
    
    var routeGuidance = ""
    
    //MARK:- ViewLifeCycle
    override func viewDidLoad() {
        
        super.viewDidLoad()
        setupInitials()
    }
    
    //MARK:- Private Methods
    func setupInitials(){
        
        setupLocationManager()
        setupTapGesture()
    }
    
    func setupLocationManager(){
        
        locationManager.delegate = self // Set map view controller as delegate of CLLocationManager
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // Set the accuracy of location on the map
        
        locationManager.requestWhenInUseAuthorization() // Request for permission to access the locaton
        
        locationManager.startUpdatingLocation() // It will the CLLocation manager delegate
    }
    
    func setupTapGesture(){
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(createMarker)) // Create gesture recognizer
        
        tapGesture.numberOfTapsRequired = 1 // Number of taps required to invoke gesture recognizer
        
        map.addGestureRecognizer(tapGesture) // Finally add tap gesture in the map view
    }
    
    @objc func createMarker(gesture: UITapGestureRecognizer){
        
        tapPoint = gesture.location(in: map)
        
        if arrSelectedCoordinates.count < 3{
            
            let tapPoint = gesture.location(in: map) // When touch on map view you get the cgpoint on the map
            
            let coordinate = map.convert(tapPoint, toCoordinateFrom: map) // Then convert cgpoint into coordinates
            
            let annotation = MKPointAnnotation() // Create MKPointAnnotation to give the description of particular point on map
            
            var annotationTitle = "" // Create annotation title varible to assign title to different annotations
            
            switch arrSelectedCoordinates.count {
            case 0:
                annotationTitle = "A"
            case 1:
                annotationTitle = "B"
            case 2:
                annotationTitle = "C"
            default:
                print("No title is required")
            }
            
            annotation.title = annotationTitle // Add title to the MKPointAnnotation
            
            annotation.coordinate = coordinate // Add coordinates to MKPointAnnotation
            
            map.addAnnotation(annotation)  // Finally add MKPointAnnotation in the map view
            
            arrSelectedCoordinates.append(coordinate) // Append the selected coordinates
            
            if isPolygonOverlayActive{
                
                if arrSelectedCoordinates.count == 3{
                    
                    createTriangle()
                }
            }
            else{
                
                getDirectionsForRouting()
            }
        }
        else{
            
            if isPolygonOverlayActive{
                
                let location = CLLocation(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)
                
                let coordinate = map.convert(tapPoint, toCoordinateFrom: map)
                
                let newLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                
                print(location.distance(from: newLocation))
                
                if location.distance(from: newLocation) > 10000{
                    
                    map.removeOverlay(polygon)
                    
                    for annotation in map.annotations{
                        
                        if annotation.coordinate.latitude != 43.6532{
                            
                            if annotation.title != "A"{
                                
                                map.removeAnnotation(annotation)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func createTriangle() {
        
        polygon = MKPolygon(coordinates: arrSelectedCoordinates, count: arrSelectedCoordinates.count)
        
        map.addOverlay(polygon)
    }
    
    func getDirectionsForRouting() {
        
        var sourceLocation = CLLocationCoordinate2D()
        
        let count = arrSelectedCoordinates.count
        
        if count == 2{
            
            sourceLocation = arrSelectedCoordinates[0]
        }
        else if count == 3{
            
            if isLastRoutePending{
                
                sourceLocation = arrSelectedCoordinates[1]
            }
            else{
                
                sourceLocation = arrSelectedCoordinates[2]
            }
        }
        
        let request = createDirectionsRequest(from: sourceLocation)
        
        let directions = MKDirections(request: request)
        
        resetMapView(withNew: directions)
        
        directions.calculate { [unowned self] (response, error) in
            
            guard let response = response else { return }
            
            for route in response.routes {
                
                self.map.addOverlay(route.polyline)
                
                self.map.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                
                let steps = route.steps
                
                for i in 0..<steps.count{
                    
                    let step = steps[i]
                    
                    self.routeGuidance += "\n" + step.instructions
                    
                    print(step.distance)
                }
            }
        }
    }
    
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        
        var destinationLocation = CLLocationCoordinate2D()
        
        let count = arrSelectedCoordinates.count
        
        if count == 2{
            
            destinationLocation = arrSelectedCoordinates[1]
        }
        else if count == 3{
            
            if isLastRoutePending{
                
                isLastRoutePending = false
                destinationLocation = arrSelectedCoordinates[2]
            }
            else{
                
                destinationLocation = arrSelectedCoordinates[0]
            }
        }
        
        let destinationCoordinate = destinationLocation
        
        let startingLocation = MKPlacemark(coordinate: coordinate)
        
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        
        request.source = MKMapItem(placemark: startingLocation)
        
        request.destination = MKMapItem(placemark: destination)
        
        request.transportType = .automobile
        
        request.requestsAlternateRoutes = false
        
        return request
    }
    
    
    func resetMapView(withNew directions: MKDirections) {
        
        directionsArray.append(directions)
        
        let _ = directionsArray.map { $0.cancel() }
    }
    
    
    func showDistance(){
        
        let alertController = UIAlertController(title: "Distance", message: String(format: " Distance from your current location is %.2f KMs", distance) , preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showSpinner(onView : UIView) {
        
        let loaderView = UIView.init(frame: onView.bounds)
        
        loaderView.backgroundColor = UIColor.clear
        
        let ai = UIActivityIndicatorView.init(style: .large)
        
        ai.startAnimating()
        
        ai.center = loaderView.center
        
        DispatchQueue.main.async {
            
            loaderView.addSubview(ai)
            
            onView.addSubview(loaderView)
        }
        
        loader = loaderView
    }
    
    func removeSpinner() {
        
        DispatchQueue.main.async {
            
            self.loader?.removeFromSuperview()
            
            self.loader = nil
        }
    }
    
    //MARK:- UIButton
    @IBAction func tapChangeOverlay(_ sender: Any) {
        
        
        var alertController = UIAlertController()
        alertController = UIAlertController(title: "Select Overlay", message: "You can change your overlay by selecting below options.", preferredStyle: .actionSheet)
        
        self.map.removeOverlays(self.map.overlays)
        self.map.removeAnnotations(self.map.annotations)
        self.arrSelectedCoordinates.removeAll()
        
        let polygon = UIAlertAction(title: "Polygon", style: .default) { (action) in
            
            self.isPolygonOverlayActive = true
        }
        
        let polyline = UIAlertAction(title: "Polyline", style: .default) { (action) in
            
            self.isLastRoutePending = true
            self.isPolygonOverlayActive = false
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            
            print("Action was cancelled")
        }
        
        alertController.addAction(polygon)
        
        alertController.addAction(polyline)
        
        alertController.addAction(cancel)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func tapRouteGuidance(_ sender: Any) {
        
        if !isPolygonOverlayActive && arrSelectedCoordinates.count == 3{
            
            self.map.removeOverlays(self.map.overlays)
        }
    }
}

extension MapViewController: CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // Set up user current location with a proper zooming.
        guard let location = locations.first else { return }
        
        let meters: Double = 20000 // Set up zooming in and out on the basis of meters
        
        // Get the coordinates of particular location
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude , longitude: location.coordinate.longitude)
        
        // Set up region on the basis of coordinates on the map view
        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: meters, longitudinalMeters: meters)
        
        map.setRegion(region, animated: true) // Finally set MKCoordinateRegion in the map view
    }
}

extension MapViewController: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if !isLastRoutePending{
            
            getDirectionsForRouting()
        }
        
        if !isPolygonOverlayActive && arrSelectedCoordinates.count == 3{
            
            let alert = UIAlertController(title: "Route Guidance", message: routeGuidance, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        
        let location = CLLocation(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!)
        
        let coordinate = map.convert(tapPoint, toCoordinateFrom: map)
        
        let newLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        if location.distance(from: newLocation) < 2000{
            
            map.removeAnnotation(view.annotation!)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if isPolygonOverlayActive{
            
            if annotation is MKUserLocation {
                
                return nil
            }
            
            let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "MyMarker")
            
            annotationView.canShowCallout = true
            
            annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            
            return annotationView
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        let request = MKDirections.Request()
        
        let sourcePoint = CLLocationCoordinate2DMake((view.annotation?.coordinate.latitude)!, (view.annotation?.coordinate.longitude)!)
        
        let destinationPoint = CLLocationCoordinate2DMake((locationManager.location?.coordinate.latitude)!, (locationManager.location?.coordinate.longitude)!)
        
        let source = MKPlacemark(coordinate: sourcePoint)
        
        let destination = MKPlacemark(coordinate: destinationPoint)
        
        request.source = MKMapItem(placemark: source)
        
        request.destination = MKMapItem(placemark: destination)
        
        request.transportType = MKDirectionsTransportType.automobile;
        
        request.requestsAlternateRoutes = false;
        
        let directions = MKDirections(request: request)
        
        showSpinner(onView: mapView)
        
        directions.calculate { (response, error) in
            
            if let response = response, let route = response.routes.first{
                
                self.removeSpinner()
                
                self.distance = route.distance/1000
                
                self.showDistance()
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is MKPolyline {
            let rendrer = MKPolylineRenderer(overlay: overlay)
            
            rendrer.strokeColor = UIColor.blue
            
            rendrer.lineWidth = 3
            
            return rendrer
        }
            
        else{
            
            let rendrer = MKPolygonRenderer(overlay: overlay)
            
            rendrer.fillColor = UIColor.red.withAlphaComponent(0.5)
            
            rendrer.strokeColor = UIColor.black
            
            rendrer.lineWidth = 1
            
            centerCoordinate = overlay.coordinate
            
            return rendrer
            
        }
    }
}
