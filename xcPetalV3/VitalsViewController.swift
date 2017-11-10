//
//  VitalsViewController.swift
//  App1.1
//
//  Created by Bhai Jaiveer Singh on 7/12/17.
//  Copyright © 2017 Jaiveer. All rights reserved.
//

import UIKit
import AWSIoT
import SwiftyJSON
import CircularSlider

class VitalsViewController: UIViewController {

    let thingName = "pi5"
//    var lastSlider: Int = 0
    
    // OUTLETS AND SHIT
    
    @IBOutlet weak var modeImage: UIImageView!
    @IBOutlet weak var scheduleSlider: CircularSlider!
    @IBOutlet weak var humidityDisplay: UILabel!
//    @IBOutlet weak var lightSlider: UISlider!
    @IBOutlet weak var temperatureSPDisplay: UILabel!
    @IBOutlet weak var lightButton: UISwitch!
    
    // VARIABLES AND SHIT
    
    var oceanColor = UIColor(hexString: "#004080")
    var lightSliderWaitingForSync = false

//    var thingOperationInProgress = false
    
    // GET/SET
    
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
    
//    var lightSliderValue: Int {
//        get {
//            return Int(lightSlider.value)
//        }
//        set {
//            lightSlider.value = Float(newValue)
//            lastSlider = newValue
//        }
//    }
//    
//    func startTimer(){
//        lightTimer = Timer.scheduledTimer(timeInterval: 3, target: self,   selector: (#selector(VitalsViewController.lightTimeOut)), userInfo: nil, repeats: false)
//    }
//    
//    func resetTimer(){
//        lightTimer.invalidate()
//        startTimer()
//    }
    
    // Step for the slider
    let step: Float = 10
    
    @IBAction func lightChanging(_ sender: UISlider) {
        let iotDataManager = AWSIoTDataManager.default()
        let roundedValue = round(sender.value / step) * step
        sender.value = roundedValue
        sender.minimumTrackTintColor = oceanColor
        lightSliderWaitingForSync = true
//        resetTimer()
//        if Int(sender.value) != lastSlider {
//            iotDataManager.publishString("{\"state\":{\"desired\":{\"light\": \(sender.value)}}}", onTopic: "$aws/things/\(thingName)/shadow/update", qoS: .messageDeliveryAttemptedAtLeastOnce)
//            iotDataManager.publishString("\(sender.value)", onTopic: "\(thingName)/change_light", qoS: .messageDeliveryAttemptedAtLeastOnce)
//            lastSlider = Int(sender.value)
//        }
    }

//    @IBAction func lightChanging(_ sender: UISwitch) {
//        let iotDataManager = AWSIoTDataManager.default()
//        let roundedValue = sender.isOn ? 100 : 0
//        iotDataManager.publishString("\(roundedValue)", onTopic: "\(thingName)/change_light", qoS: .messageDeliveryAttemptedAtLeastOnce)
//    }
    
    func subLightOverride(a: NSObject, b: String, payload: Data) {
        DispatchQueue.main.async {
            let json = JSON(data: (payload as NSData!) as Data)
            let temp = String(describing: json)
            if let val = Int(temp) {
                if val == 1 {
//                    self.lightSlider.minimumTrackTintColor = self.oceanColor
                }
                if val == 0 {
//                    self.lightSliderWaitingForSync = false
//                    self.lightSlider.minimumTrackTintColor = UIColor.lightGray
                }
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
//            self.thingOperationInProgress = false;
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
        if lightSliderWaitingForSync == false {
            if let lightReported = json["state"]["reported"]["light"].int {
//                lightSliderValue = lightReported
                lightButton.isOn = lightReported > 50 ? true : false
                
            }
            if let lightOverride = json["state"]["reported"]["light_override"].int {
                if lightOverride == 0 {
//                    self.lightSlider.minimumTrackTintColor = UIColor.lightGray
                }
                else {
//                    self.lightSlider.minimumTrackTintColor = self.oceanColor
                }
            }
        }
    }
//    
//    func lightTimeOut() {
//        lightSliderWaitingForSync = false
//        getShadowOf(thingName)
//        print("asdasd")
////        if lightSliderValue != lightReported {
////            lightSlider.minimumTrackTintColor = UIColor.lightGray
////        }
//    }
    
    func slideEnded() {
        let iotDataManager = AWSIoTDataManager.default()
        let val = scheduleSlider.value
        var schedule = ""
        if val < 4 {
//            dayTime = '0\(Int(scheduleSlider.value + 6))00'
            schedule = "[['day','0\(Int(scheduleSlider.value + 6))00'],['night','0\(Int(scheduleSlider.value))00']]"
        }
        else if val < 10 {
            schedule = "[['day','\(Int(scheduleSlider.value + 6))00'],['night','0\(Int(scheduleSlider.value))00']]"
        }
        else if val > 20 {
            schedule = "[['day','\(Int(scheduleSlider.value - 18))00'],['night','\(Int(scheduleSlider.value))00']]"
        }
        else {
            schedule = "[['day','\(Int(scheduleSlider.value + 6))00'],['night','\(Int(scheduleSlider.value))00']]"
        }
        iotDataManager.publishString(_: schedule, onTopic: "\(thingName)/schedule", qoS: .messageDeliveryAttemptedAtLeastOnce)
    }
    
    override func viewDidLoad() {
        print("here222")
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
extension VitalsViewController: CircularSliderDelegate {
    func circularSlider(_ circularSlider: CircularSlider, valueForValue value: Float) -> Float {
        return floorf(value)
    }
}

//// UIColor Helper
//extension UIColor {
//    public convenience init?(hexString: String) {
//        let r, g, b, a: CGFloat
//        
//        if hexString.hasPrefix("#") {
//            let start = hexString.index(hexString.startIndex, offsetBy: 1)
//            let hexColor = hexString.substring(from: start)
//            
//            if hexColor.characters.count == 8 {
//                let scanner = Scanner(string: hexColor)
//                var hexNumber: UInt64 = 0
//                
//                if scanner.scanHexInt64(&hexNumber) {
//                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
//                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
//                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
//                    a = CGFloat(hexNumber & 0x000000ff) / 255
//                    
//                    self.init(red: r, green: g, blue: b, alpha: a)
//                    return
//                }
//            }
//        }
//        return nil
//    }
//}
//
