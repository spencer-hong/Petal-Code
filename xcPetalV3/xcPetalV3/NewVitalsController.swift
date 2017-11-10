//
//  NewVitalsController.swift
//  xcPetalV3
//
//  Created by Bhai Jaiveer Singh on 10/23/17.
//  Copyright © 2017 Okavango Systems. All rights reserved.
//

import UIKit
import AWSIoT
import SwiftyJSON
import CircularSlider

class NewVitalsController: UIViewController {
    
    let thingName = "pi5"

    
    @IBOutlet weak var modeImage: UIImageView!
    @IBOutlet weak var humidityDisplay: UILabel!
    @IBOutlet weak var temperatureSPDisplay: UILabel!
    @IBOutlet weak var scheduleSlider: CircularSlider!
    @IBOutlet weak var lightButton: UISwitch!
    @IBOutlet weak var hours: UITextField!
    
    var hoursValue: Int {
        get {
            return Int(hours.text!)!
        }
        set {
            hours.text = "\(newValue)"
        }
    }
    
    var temperatureSPDisplayValue: Double {
        get {
            return Double(temperatureSPDisplay.text!)!
        }
        set {
            let fahreneitValue = (newValue*1.8) + 32
            let roundedValue = Int(fahreneitValue.rounded())
            temperatureSPDisplay.text = "\(roundedValue)°"
        }
    }
    
    var humidityDisplayValue: Double {
        get {
            return Double(humidityDisplay.text!)!
        }
        set {
            let roundedValue = Int(newValue.rounded())
            humidityDisplay.text = "Humidity: \(roundedValue)%"
        }
    }
    
    func subLightOverride(a: NSObject, b: String, payload: Data) {
        DispatchQueue.main.async {
            let json = JSON(data: (payload as NSData!) as Data)
            let temp = String(describing: json)
            if let val = Int(temp) {
//                Do something
            }
        }
    }
    
    func update(payload: Data) {
        print("updating")
        DispatchQueue.main.async {
            let json = JSON(data: (payload as NSData!) as Data)
            if json["state"]["reported"] != nil {
                self.updateStatus(payload: json)
            }
        }
    }
    
    func updateStatus(payload json: JSON) {
        print("updating status")
        if let temperatureSPReported = json["state"]["reported"]["tempSP"].double {
            temperatureSPDisplayValue = temperatureSPReported
        }
        if let humidityReported = json["state"]["reported"]["humidity"].double {
            humidityDisplayValue = humidityReported
        }
        if let mode = json["state"]["reported"]["mode"].int {
            switch mode {
            case 1:
                modeImage.image = UIImage(named: "Heating")
            case 2:
                modeImage.image = UIImage(named: "Cooling")
            case 0:
                modeImage.image = UIImage(named: "Neutral")
            default:
                modeImage.image = UIImage(named: "Nuetral")
            }
        }
        if let lightReported = json["state"]["reported"]["light"].int {
            lightButton.isOn = lightReported > 50 ? true : false
        }
        if let lightOverride = json["state"]["reported"]["light_override"].int {
            if lightOverride == 0 {
            }
            else {
            }
        }
    }
    
    @IBAction func hourChanged(_ sender: UITextField) {
        slideEnded()
    }
    
    @IBAction func lightChanging(_ sender: UISwitch) {
        let iotDataManager = AWSIoTDataManager.default()
        let roundedValue = sender.isOn ? 100 : 0
        iotDataManager.publishString("\(roundedValue)", onTopic: "\(thingName)/change_light", qoS: .messageDeliveryAttemptedAtLeastOnce)
    }
    
    func slideEnded() {
        let iotDataManager = AWSIoTDataManager.default()
        let val = Int(scheduleSlider.value)
        let hr = 6
        var schedule = ""
        if val < 4 {
            schedule = "[['day','0\(Int(scheduleSlider.value) + hr)00'],['night','0\(Int(scheduleSlider.value))00']]"
        }
        else if val < 10 {
            schedule = "[['day','\(Int(scheduleSlider.value) + hr)00'],['night','0\(Int(scheduleSlider.value))00']]"
        }
        else if val > 20 {
            schedule = "[['day','\(Int(scheduleSlider.value) - 18)00'],['night','\(Int(scheduleSlider.value))00']]"
        }
        else {
            schedule = "[['day','\(Int(scheduleSlider.value) + hr)00'],['night','\(Int(scheduleSlider.value))00']]"
        }
        iotDataManager.publishString(_: schedule, onTopic: "\(thingName)/schedule", qoS: .messageDeliveryAttemptedAtLeastOnce)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let iotDataManager = AWSIoTDataManager.default()
        setupCircularSlider()
        setupTapGesture()
        //        lightSlider.minimumTrackTintColor = oceanColor
        //        lightSlider.minimumTrackTintColor = UIColor.lightGray
        modeImage.image = UIImage(named: "Neutral")
        iotDataManager.subscribe(toTopic: "$aws/things/\(thingName)/shadow/update/accepted", qoS: AWSIoTMQTTQoS.messageDeliveryAttemptedAtLeastOnce, messageCallback: self.update)
        iotDataManager.subscribe(toTopic: "\(thingName)/light_override", qoS: AWSIoTMQTTQoS.messageDeliveryAttemptedAtLeastOnce, extendedCallback: self.subLightOverride)
        iotDataManager.subscribe(toTopic: "$aws/things/\(thingName)/shadow/get/accepted", qoS: AWSIoTMQTTQoS.messageDeliveryAttemptedAtLeastOnce, messageCallback: self.update)
        getShadowOf(thingName)
        iotDataManager.publishString("", onTopic: "$aws/things/\(thingName)/shadow/get", qoS: .messageDeliveryAttemptedAtLeastOnce)
    }

    func getShadowOf(_ thingName: String) {
        let iotDataManager = AWSIoTDataManager.default()
        iotDataManager.publishString("", onTopic: "$aws/things/\(thingName)/shadow/get", qoS: .messageDeliveryAttemptedAtLeastOnce)
    }
    
    // MARK: - methods
    fileprivate func setupCircularSlider() {
        scheduleSlider.delegate = self
    }
    
    fileprivate func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc fileprivate func hideKeyboard() {
        view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// CircularSliderDelegate
extension NewVitalsController: CircularSliderDelegate {
    func circularSlider(_ circularSlider: CircularSlider, valueForValue value: Float) -> Float {
        return floorf(value)
    }
}

// UIColor Helper
extension UIColor {
    public convenience init?(hexString: String) {
        let r, g, b, a: CGFloat
        
        if hexString.hasPrefix("#") {
            let start = hexString.index(hexString.startIndex, offsetBy: 1)
            let hexColor = hexString.substring(from: start)
            
            if hexColor.characters.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255
                    
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        return nil
    }
}

