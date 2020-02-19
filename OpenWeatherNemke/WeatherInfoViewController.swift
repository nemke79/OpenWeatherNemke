//
//  WeatherInfoViewController.swift
//  OpenWeatherNemke
//
//  Created by Nemanja Petrovic on 18/02/2020.
//  Copyright © 2020 Nemanja Petrovic. All rights reserved.
//

import UIKit

class WeatherInfoViewController: UIViewController {
    @IBOutlet weak var cityName: UILabel!
    @IBOutlet weak var temperature: UILabel!
    @IBOutlet weak var humidity: UILabel!
    @IBOutlet weak var rainChances: UILabel!
    @IBOutlet weak var wind: UILabel!
    
    
    var nameText: String?
    var temperatureText: String?
    var humidityText: String?
    var rainChancesText: String?
    var windText: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let cityNameText = nameText {
            cityName.text = cityNameText
        }
        
        if let cityTemperatureText = temperatureText {
            temperature.text = "Temperature: \(cityTemperatureText)"
        }
        
        if let cityHumidityText = humidityText {
            humidity.text = "Humidity: \(cityHumidityText)"
        }
        
        if let cityRainChancesText = rainChancesText {
            rainChances.text = cityRainChancesText
        }
        
        if let cityWindText = windText {
            wind.text = "Wind: \(cityWindText)"
        }
    }
}
