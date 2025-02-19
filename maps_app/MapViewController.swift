//
//  ViewController.swift
//  maps_app
//
//  Created by Volkan Ustekidag on 11.02.2025.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager()
    
    @IBOutlet weak var noteTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    var lastLocation: CLLocation?
    var selectedLat = Double()
    var selectedLong = Double()
    
    var selectedTitle = ""
    var selectedId : UUID?
    
    var annnotationTile = ""
    var annotationNote = ""
    var annotationLat = Double()
    var annotationLong = Double()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.distanceFilter = 500
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        
        if selectedTitle != "" {
            
            if let uuidString = selectedId?.uuidString {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
                fetchRequest.predicate = NSPredicate(format: "id == %@", uuidString)
                fetchRequest.returnsObjectsAsFaults = false
                
                
                do {
                    let responses = try context.fetch(fetchRequest)
                    
                    if responses.count > 0 {
                        for response in responses as! [NSManagedObject] {
                            guard let title = response.value(forKey: "title") as? String,
                                  let subtitle = response.value(forKey: "subtitle") as? String,
                                  let lat = response.value(forKey: "lat") as? Double,
                                  let long = response.value(forKey: "long") as? Double else {
                                return // Eğer herhangi biri eksikse, işlemi durdur
                            }
                            
                            // Tüm değerler güvenli şekilde alındığında atama yap
                            nameTextField.text = title
                            noteTextField.text = subtitle
                            annotationLat = lat
                            annotationLong = long
                            
                            let annotation = MKPointAnnotation()
                            annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                            annotation.title = title
                            annotation.subtitle = subtitle
                            
                            mapView.addAnnotation(annotation)
                            
                            nameTextField.text = selectedTitle
                            noteTextField.text = subtitle
                            
                            nameTextField.isEnabled = false
                            noteTextField.isEnabled = false
                            saveButton.isHidden = true
                            
                            locationManager.startUpdatingLocation()
                            
                            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                            let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: long), span: span)
                            mapView.setRegion(region, animated: true)
                            
                        }
                        
                    }
                } catch {
                    print("error")
                }
                
            }
            
            
        } else {
            let uILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(gestureRecognizer:)))
            mapView.addGestureRecognizer(uILongPressGestureRecognizer)
            
            
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func addAnnotation(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            selectedLat = coordinate.latitude
            selectedLong = coordinate.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            annotation.title = nameTextField.text?.isEmpty == false ? nameTextField.text : "boş title"
            annotation.subtitle = noteTextField.text?.isEmpty == false ? noteTextField.text : "boş subtitle"
            
            mapView.addAnnotation(annotation)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let id = "annation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: id)
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
            pinView?.canShowCallout = true
            pinView?.tintColor = .orange
            
            let button = UIButton(type: .detailDisclosure)
            
            pinView?.rightCalloutAccessoryView = button
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
       if selectedTitle != "" {

            let requestLocation = CLLocation(latitude: self.annotationLat, longitude:self.annotationLong)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) {
                (placemarks, error) in
                
                if placemarks?.count ?? 0 > 0 {
                    let newPlaceMark = MKPlacemark(placemark:  placemarks![0] )
                    let item = MKMapItem(placemark: newPlaceMark)
                    item.name = self.selectedTitle
                    let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                    item.openInMaps(launchOptions:launchOptions)
                    
                }
            }
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if selectedTitle == "" {
            let location    = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span    = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region     = MKCoordinateRegion(center: location, span:span)
            mapView.setRegion(region, animated: true)
            
        }
    }
    
    
    
    @IBAction func onClickSave(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newLocation = NSEntityDescription.insertNewObject(forEntityName: "Location", into: context)
        
        newLocation.setValue(nameTextField.text, forKey: "title")
        newLocation.setValue(noteTextField.text, forKey: "subtitle")
        newLocation.setValue(selectedLat, forKey: "lat")
        newLocation.setValue(selectedLong, forKey: "long")
        newLocation.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            print("saved.")
            
            NotificationCenter.default.post(name: NSNotification.Name("newLocationSaved"), object: nil)
            navigationController?.popViewController(animated: true)
            
        } catch {
            print("error saving: \(error)")
            
            let alert = UIAlertController(title: "Error", message: "Saving failed: \(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        
        
    }
    
}

