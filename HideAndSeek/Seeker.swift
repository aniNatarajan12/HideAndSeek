//
//  Seeker.swift
//  HideAndSeek
//
//  Created by Anirudh Natarajan on 3/19/17.
//  Copyright © 2017 Kodikos. All rights reserved.
//

import UIKit
import MapKit
import MultipeerConnectivity
import CoreLocation

class Seeker: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    var appDelegate:AppDelegate!
    var hiderSpot: CLLocationCoordinate2D!
    var spotLooking: CLLocationCoordinate2D!
    var distance: Double!
    var spotChosen = false
    let locationManager = CLLocationManager()
    var attempts = 4
    var hints = 2
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
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(Seeker.handleLongPress))
        lpgr.minimumPressDuration = 0.3
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        self.mapView.addGestureRecognizer(lpgr)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if(spotChosen){
            if gestureReconizer.state != UIGestureRecognizerState.ended {
                let touchLocation = gestureReconizer.location(in: mapView)
                let locationCoordinate = mapView.convert(touchLocation,toCoordinateFrom: mapView)
                //            print("Tapped at lat: \(locationCoordinate.latitude) long: \(locationCoordinate.longitude)")
                
                if(mapView.annotations[0].coordinate.latitude != locationCoordinate.latitude || mapView.annotations[0].coordinate.longitude != locationCoordinate.longitude) {
                    mapView.removeAnnotations(mapView.annotations)
                    
                    let location = CLLocation(latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude)
                    
                    addPin(location: location, first: false)
                }
                
                return
            }
            if gestureReconizer.state != UIGestureRecognizerState.began {
                return
            }
        }
        else {
            let alert = UIAlertController(title: "Hold Your Horses", message: "The hider hasn't picked a spot yet.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func addPin(location: CLLocation, first: Bool){
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        spotLooking = annotation.coordinate
        if(!first){
            distance = location.distance(from: CLLocation(latitude: hiderSpot.latitude, longitude: hiderSpot.longitude))/1609.344
        }
        annotation.title = "Do you think someone would hide here?"
        
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            print(location)
            
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
    @IBAction func guessHidingSpot(_ sender: Any) {
        if(spotChosen && attempts > 0){
            attempts -= 1
            let messageDict: NSDictionary
            
            if(distance<400){
                let alert = UIAlertController(title: "Congratulations!", message: "You found the hider!", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (result: UIAlertAction) -> Void in
                    self.found = "yes"
                    self.performSegue(withIdentifier: "gameOverS", sender: self)
                }))
                self.present(alert, animated: true, completion: nil)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: hiderSpot.latitude, longitude: hiderSpot.longitude)
                annotation.title = "This is where the hider hid."
                mapView.addAnnotation(annotation)
                messageDict = ["guess": "right"]
            }
            else{
                if(attempts>0){
                    let alert = UIAlertController(title: "Not Quite", message: "You haven't found the hider. You have \(attempts) attempts left and \(hints) hints left. You were \(Int(distance)) miles off. You need to be within 400 to find the hider.", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    messageDict = ["guess": "wrong", "attempts": "\(attempts)", "lat": "\(spotLooking.latitude)", "long": "\(spotLooking.longitude)"]
                }
                else {
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = CLLocationCoordinate2D(latitude: hiderSpot.latitude, longitude: hiderSpot.longitude)
                    annotation.title = "This is where the hider hid."
                    mapView.addAnnotation(annotation)
                    
                    let alert = UIAlertController(title: "Darn!", message: "You ran out of attempts and couldn't find the hider. You were \(distance) miles off.", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (result: UIAlertAction) -> Void in
                        self.found = "no"
                        self.performSegue(withIdentifier: "gameOverS", sender: self)
                    }))
                    self.present(alert, animated: true, completion: nil)
                    messageDict = ["guess": "wrong", "attempts": "\(attempts)"]
                }
            }
            
            let messageData: Data
            do {
                messageData = try JSONSerialization.data(withJSONObject: messageDict, options: JSONSerialization.WritingOptions.prettyPrinted)
                try appDelegate.mpcHandler.session.send(messageData, toPeers: appDelegate.mpcHandler.session.connectedPeers, with: MCSessionSendDataMode.reliable)
            }
            catch {
                print(error)
            }
        }
    }
    @IBAction func getHint(_ sender: Any) {
        if(spotChosen && hints > 0){
            hints -= 1
            let messageDict = ["hint": "hint", "left": "\(hints)"]
            let messageData: Data
            do {
                messageData = try JSONSerialization.data(withJSONObject: messageDict, options: JSONSerialization.WritingOptions.prettyPrinted)
                try appDelegate.mpcHandler.session.send(messageData, toPeers: appDelegate.mpcHandler.session.connectedPeers, with: MCSessionSendDataMode.reliable)
            }
            catch {
                print(error)
            }
            if(hints > 0) {
                let alert = UIAlertController(title: "Help", message: "The hider has been asked to give a hint. Please wait till they respond. You have \(hints) hints remaining.", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            else if (hints == 0) {
                let alert = UIAlertController(title: "Help", message: "The hider has been asked to give a hint. Please wait till they respond. You have no more hints. Good luck!", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        } else if (hints == 0) {
            let alert = UIAlertController(title: "Sorry", message: "You used up all your hints. It's up to you know. Good luck!", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - Location Delegate Methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        
        addPin(location: location!, first: true)
        
        //        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        //        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
        //        self.mapView.setRegion(region, animated: true)
        self.locationManager.stopUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Errors " + error.localizedDescription)
    }
    
    func handleReceivedDataWithNotification(_ notification:Notification){
        let userInfo = notification.userInfo! as Dictionary
        let receivedData:Data = userInfo["data"] as! Data
        
        do {
            let message = try JSONSerialization.jsonObject(with: receivedData, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
            if let hint = message.object(forKey: "hint") as? String {
                let start = hint.index(hint.startIndex, offsetBy: 10)
                let end = hint.index(hint.endIndex, offsetBy: -2)
                let range = start..<end
                let hintR = hint.substring(with: range)
                
                let alert = UIAlertController(title: "Help Recieved!", message: "The hint the hider gave is: \(hintR)", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                let latitude:CLLocationDegrees = (message.object(forKey: "lat") as! NSString).doubleValue
                let longitude:CLLocationDegrees = (message.object(forKey: "long") as! NSString).doubleValue
                hiderSpot = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                spotChosen = true
            }
        } catch {
            print(error)
        }
    }
    
}
