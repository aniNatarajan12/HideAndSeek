//
//  ViewController.swift
//  HideAndSeek
//
//  Created by Anirudh Natarajan on 3/19/17.
//  Copyright © 2017 Kodikos. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import MultipeerConnectivity

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    var appDelegate:AppDelegate!
    var selected = false
    var found = "def"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.handleReceivedDataWithNotification(_:)), name: NSNotification.Name(rawValue: "MPC_DidReceiveDataNotification"), object: nil)
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        self.mapView.showsUserLocation = false
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.handleLongPress))
        lpgr.minimumPressDuration = 0.3
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        self.mapView.addGestureRecognizer(lpgr)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if(!selected){
            if gestureReconizer.state != UIGestureRecognizerState.ended {
                let touchLocation = gestureReconizer.location(in: mapView)
                let locationCoordinate = mapView.convert(touchLocation,toCoordinateFrom: mapView)
                //              print("Tapped at lat: \(locationCoordinate.latitude) long: \(locationCoordinate.longitude)")
                
                if(mapView.annotations[0].coordinate.latitude != locationCoordinate.latitude || mapView.annotations[0].coordinate.longitude != locationCoordinate.longitude) {
                    mapView.removeAnnotations(mapView.annotations)
                    
                    let location = CLLocation(latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude)
                    
                    addPin(location: location)
                }
                
                return
            }
            if gestureReconizer.state != UIGestureRecognizerState.began {
                return
            }
        } else {
            let alert = UIAlertController(title: "CHEATER!", message: "You already picked a hiding spot you can't change it! Wait for the seeker to recieve further actions.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func addPin(location: CLLocation){
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        annotation.title = "Your Hiding Spot"
        
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            //                    print(location)
            
            if error != nil {
                print("Reverse geocoder failed with error " + (error?.localizedDescription)!)
                return
            }
            
            var address = ""
            
            if (placemarks?.count)! > 0 {
                let pm = placemarks?[0] as? CLPlacemark!
                if let city = pm!.locality {
                    address += "\(city), "
                }
                if let state = pm!.administrativeArea {
                    address += "\(state)"
                }
                annotation.subtitle = address
            }
            else {
                print("Problem with the data received from geocoder")
            }
        })
        mapView.addAnnotation(annotation)
    }
    
    func getHint() {
        let alertController = UIAlertController(title: "Hint", message: "Type the hint you want to give the seeker: ", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (_) in
            let messageDict: NSDictionary
            if let field = alertController.textFields![0] as? UITextField {
                messageDict = ["hint": "\(field.text)"]
            } else {
                messageDict = ["hint": "Umm... The hider was being a bit cruel and unusual and decided not to give you a hint... Sorry.."]
            }
            let messageData: Data
            
            do {
                messageData = try JSONSerialization.data(withJSONObject: messageDict, options: JSONSerialization.WritingOptions.prettyPrinted)
                try self.appDelegate.mpcHandler.session.send(messageData, toPeers: self.appDelegate.mpcHandler.session.connectedPeers, with: MCSessionSendDataMode.reliable)
            }
            catch {
                print(error)
            }
        }
        
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Hint"
        }
        
        alertController.addAction(confirmAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Location Delegate Methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        
        addPin(location: location!)
        
        //        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        //        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
        //        self.mapView.setRegion(region, animated: true)
        self.locationManager.stopUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Errors " + error.localizedDescription)
    }
    
    @IBAction func hidingSpotSelected(_ sender: Any) {
        if(!selected){
            selected = true
            let coordinate = mapView.annotations[0].coordinate
            
            let messageDict = ["lat": "\(coordinate.latitude)", "long": "\(coordinate.longitude)"]
            let messageData: Data
            
            do {
                messageData = try JSONSerialization.data(withJSONObject: messageDict, options: JSONSerialization.WritingOptions.prettyPrinted)
                try appDelegate.mpcHandler.session.send(messageData, toPeers: appDelegate.mpcHandler.session.connectedPeers, with: MCSessionSendDataMode.reliable)
            }
            catch {
                print(error)
            }
            let alert = UIAlertController(title: "Spot Selected", message: "You have sucessfully chosen your hiding spot. Wait for the seeker to recieve further actions.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "CHEATER!", message: "You already picked a hiding spot you can't change it! Wait for the seeker to recieve further actions.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func handleReceivedDataWithNotification(_ notification:Notification){
        let userInfo = notification.userInfo! as Dictionary
        let receivedData:Data = userInfo["data"] as! Data
        
        do {
            let message = try JSONSerialization.jsonObject(with: receivedData, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
            if let guess = message.object(forKey: "guess") as? String {
                if(guess == "right"){
                    let alert = UIAlertController(title: "Darn!", message: "The seeker found your hiding spot!", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (result: UIAlertAction) -> Void in
                        self.found = "yes"
                        self.performSegue(withIdentifier: "gameOverH", sender: self)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
                else if (guess == "wrong") {
                    let attempts = (message.object(forKey: "attempts") as! NSString).integerValue
                    
                    if(attempts>0){
                        let alert = UIAlertController(title: "Phew!", message: "The seeker didn't find you but still has \(attempts) attempts. Swipe around to see where they guessed!", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        
                        let lat: CLLocationDegrees = (message.object(forKey: "lat") as! NSString).doubleValue
                        let long: CLLocationDegrees = (message.object(forKey: "long") as! NSString).doubleValue
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                        annotation.title = "This is where the seeker guessed."
                        print(mapView.annotations.count)
                        if(mapView.annotations.count > 1){
                            print(mapView.annotations[0].title)
                            mapView.removeAnnotation(mapView.annotations[mapView.annotations.count-1])
                        }
                        mapView.addAnnotation(annotation)
                    }
                    else {
                        let alert = UIAlertController(title: "Congratulations!", message: "The seeker ran out of attempts and didn't find your hiding spot!", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (result: UIAlertAction) -> Void in
                            self.found = "no"
                            self.performSegue(withIdentifier: "gameOverH", sender: self)
                        }))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            } else {
                let hints = (message.object(forKey: "left") as! NSString).integerValue
                let alert = UIAlertController(title: "Help Needed!", message: "The seeker needs some help. Give them a hint. The seeker has \(hints) hints remaining.", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (result: UIAlertAction) -> Void in
                    self.getHint()
                }))
                self.present(alert, animated: true, completion: nil)
            }
            
        } catch {
            print(error)
        }
    }
    
}
