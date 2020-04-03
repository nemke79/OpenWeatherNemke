//
//  ViewController.swift
//  OpenWeatherNemke
//
//  Created by Nemanja Petrovic on 18/02/2020.
//  Copyright © 2020 Nemanja Petrovic. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    
    let locationManager = CLLocationManager()
    
    var arrayOfPinsCLLocations = [CLLocation]()
    
    var arrayOfPinsNames = [String]()
    
    var arrayOfAnotations = [MKAnnotation]()
    
    private var currentLocation: CLLocation?
    
    let myPin = MKPointAnnotation()
    
    var baseURL = String()
    
    var rainInfo = String()
    
    var windSpeed = String()
    
    var temperature = String()
    
    var humidity = String()
    
    // Adding outlet for map
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            let tgr = UITapGestureRecognizer(target: self, action: #selector(self.tapGestureHandler))
            tgr.delegate = self
            mapView.addGestureRecognizer(tgr)
            
        }
    }
    
    
    // List of cities added.
    @IBOutlet weak var citiesTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        citiesTableView.dataSource = self
        citiesTableView.delegate = self
        mapView.delegate = self
        mapView.mapType = .standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Check for Location Services
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
    }
    
    // Gesture for adding pins to map
    
    @objc func tapGestureHandler(tgr: UITapGestureRecognizer)
    {
        let touchPoint = tgr.location(in: mapView)
        let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = touchMapCoordinate
        mapView.addAnnotation(annotation)
        
        arrayOfAnotations.append(annotation)
        
        let location = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            // Process Response
            if let error = error {
                print("Unable to Reverse Geocode Location (\(error))")
            } else {
                if let placemarks = placemarks, let placemark = placemarks.first {
                    self.arrayOfPinsNames.append("\(placemark.locality ?? placemark.name ?? placemark.country ?? placemark.ocean ?? "Unknown location") \(placemark.country ?? "")")
                    self.arrayOfPinsCLLocations.append(placemark.location!)
                    
                    self.citiesTableView.reloadData()
                    
                    let indexPath = NSIndexPath(row: self.arrayOfPinsNames.count-1, section: 0)
                    self.citiesTableView.scrollToRow(at: indexPath as IndexPath, at: .bottom, animated: true)
                    
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayOfPinsNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cityName", for: indexPath)
        
        cell.textLabel?.text = arrayOfPinsNames[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            mapView.removeAnnotation(arrayOfAnotations[indexPath.row])
            arrayOfAnotations.remove(at: indexPath.row)
            arrayOfPinsNames.remove(at: indexPath.row)
            arrayOfPinsCLLocations.remove(at: indexPath.row)
            citiesTableView.deleteRows(at: [indexPath], with: .fade)
            citiesTableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        baseURL = "http://api.openweathermap.org/data/2.5/weather?lat=\(arrayOfPinsCLLocations[indexPath.row].coordinate.latitude)&lon=\(arrayOfPinsCLLocations[indexPath.row].coordinate.longitude)&appid=e854ddd801a0b12983d135bbd5fb005e&units=metric"
        
        requestWeather{ (data, success) in
            
            guard let _ = data else {return}
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "showWeatherInfo":
                if let weatherInfoVC = segue.destination.contents as? WeatherInfoViewController {
                    if let indexPath = citiesTableView.indexPathForSelectedRow {
                        weatherInfoVC.nameText = arrayOfPinsNames[indexPath.row]
                        
                        weatherInfoVC.rainChancesText = self.rainInfo
                        weatherInfoVC.temperatureText = self.temperature
                        weatherInfoVC.humidityText = self.humidity
                        weatherInfoVC.windText = self.windSpeed
                        
                    }
                }
                
            default: break
            }
        }
    }
    
    func requestWeather(completion: @escaping (Any?, Bool) -> ()) {
        let url = URL(string: baseURL)
        
        let dataTask = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            self.fetchData(data: data, response: response!, error: error, completion: completion)
            if error == nil {
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "showWeatherInfo", sender: self)
                }
            }
            
        }
        
        dataTask.resume()
        
    }
    
    private func fetchData(data: Data?, response: URLResponse, error: Error?, completion: @escaping (Any?, Bool) -> ()) {
        do {
            let jsonData = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
            
            let info = jsonData
            let weather = info!["weather"] as! [[String: Any]]
            let wind = info!["wind"] as! [String: Any]
            let main = info!["main"] as! [String: Any]
            
            for weatherInfo in weather {
                let description = weatherInfo["description"] as? String
                
                DispatchQueue.main.async {
                    self.rainInfo = String(describing: description!)
                }
            }
            
            let speed = wind["speed"] as? Double
            
            DispatchQueue.main.async {
                self.windSpeed = String(describing: speed!) + " m/s"
            }
            
            let temp = main["temp"] as? Double
            let humidity = main["humidity"] as? Double
            
            DispatchQueue.main.async {
                self.temperature = String(describing: Int(temp!)) + " °C"
                self.humidity = String(describing: Int(humidity!)) + "%"
            }
        } catch let error as NSError {
            print("Decoding error \(error.localizedDescription)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        defer { currentLocation = locations.last }
        
        if currentLocation == nil {
            // Zoom to user location
            if let userLocation = locations.last {
                let viewRegion = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
                mapView.setRegion(viewRegion, animated: false)
                
                myPin.coordinate = userLocation.coordinate
                
                mapView.addAnnotation(myPin)
                
                arrayOfAnotations.append(myPin)
                
                let location = CLLocation(latitude: myPin.coordinate.latitude, longitude: myPin.coordinate.longitude)
                
                let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                    // Process Response
                    if let error = error {
                        print("Unable to Reverse Geocode Location (\(error))")
                    } else {
                        if let placemarks = placemarks, let placemark = placemarks.first {
                            
                            self.arrayOfPinsNames.append("\(placemark.locality ?? placemark.name ?? placemark.country ?? placemark.ocean ?? "Unknown location") \(placemark.country ?? "")")
                            self.arrayOfPinsCLLocations.append(placemark.location!)
                            self.citiesTableView.reloadData()
                            
                            let indexPath = NSIndexPath(row: self.arrayOfPinsNames.count-1, section: 0)
                            self.citiesTableView.scrollToRow(at: indexPath as IndexPath, at: .bottom, animated: true)
                        }
                    }
                }
            }
        }
    }
}

extension UIViewController {
    var contents: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController ?? navcon
        } else {
            return self
        }
    }
}

