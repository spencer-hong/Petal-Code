//
//  ViewController.swift
//  App1.1
//
//  Created by Bhai Jaiveer Singh ~~BIG BAUUUSS~~ on 7/12/17.
//  Copyright © 2017 Jaiveer. All rights reserved.
//

import UIKit
import AWSIoT
import SwiftyJSON
import CircularSlider

let thingName = "myThingName"
var counter = 0

class ViewController: UIViewController {
    
    var iotDataManager: AWSIoTDataManager!
    
    @IBOutlet weak var scheduleSlider: CircularSlider!
    @IBOutlet weak var lightSlider: UISlider!
    @IBOutlet weak var temperatureDisplay: UILabel!
    @IBOutlet weak var humidityDisplay: UILabel!
    
    let maxTime = 5

    var lightSliderWaitingForSync = 0 // 0 = synced, 1 - x means change made x cycles ago
    
    var thingOperationInProgress = false
    
    var temperatureDisplayValue: Double {
        get {
            return Double(temperatureDisplay.text!)!
        }
        set {
            let roundedValue = floor(newValue * 10)/10
            temperatureDisplay.text = String(roundedValue)
        }
    }
    
    var humidityDisplayValue: Double {
        get {
            return Double(humidityDisplay.text!)!
        }
        set {
            let roundedValue = floor(newValue * 10)/10
            humidityDisplay.text = String(roundedValue)
        }
    }
    
    var lightSliderValue: Int {
        get {
            return Int(lightSlider.value)
        }
        set {
            lightSlider.value = Float(newValue)
        }
    }
    
    @IBAction func lightChanged(_ sender: UISlider) {
        let controlJson = JSON(["state": ["desired": [ "custom_light": Int(sender.value),]]])
        self.iotDataManager.updateShadow(thingName, jsonString: controlJson.rawString()! )
        self.iotDataManager.publishString(_: String(sender.value), onTopic: "changeLight", qoS: .messageDeliveryAttemptedAtLeastOnce)
        lightSliderWaitingForSync = 1
        sender.minimumTrackTintColor = UIColor.blue
    }
    
    func getThingState() {
        self.iotDataManager.getShadow(thingName)
    }
    
    func mqttEventCallback( _ status: AWSIoTMQTTStatus )
    {
        DispatchQueue.main.async {
            print("connection status = \(status.rawValue)")
            switch(status)
            {
            case .connecting:
                print( "Connecting..." )
                
            case .connected:
                print( "Connected" )
                // Register the device shadows once connected.
                self.iotDataManager.register(withShadow: thingName, options:nil,  eventCallback: self.deviceShadowCallback)
                self.iotDataManager.subscribe(toTopic: "$aws/things/myThingName/shadow/update/accepted", qoS: AWSIoTMQTTQoS.messageDeliveryAttemptedAtLeastOnce, messageCallback: self.update)
                self.iotDataManager.subscribe(toTopic: "light_override", qoS: AWSIoTMQTTQoS.messageDeliveryAttemptedAtLeastOnce, extendedCallback: self.subLightOverride)
                
                // Two seconds after registering the device shadows, retrieve their current states.
                Timer.scheduledTimer( timeInterval: 2.5, target: self, selector: #selector(ViewController.getThingState), userInfo: nil, repeats: false )
                
            case .disconnected:
                print( "Disconnected" )
                
            case .connectionRefused:
                print( "Connection Refused" )
                
            case .connectionError:
                print( "Connection Error" )
                
            case .protocolError:
                print( "Protocol Error" )
                
            default:
                print("unknown state: \(status.rawValue)")
            }
        }
    }
    
    func update(payload: Data) {
        DispatchQueue.main.async {
            let json = JSON(data: (payload as NSData!) as Data)
            if json["state"]["reported"] != nil {
                self.updateStatus(payload: json)
            }
            self.thingOperationInProgress = false;
        }
    }
    
    func subLightOverride(a: NSObject, b: String, payload: Data) {
        DispatchQueue.main.async {
            let json = JSON(data: (payload as NSData!) as Data)
            let temp = String(describing: json)
            if let val = Int(temp) {
                if val == 1 {
                    self.lightSlider.minimumTrackTintColor = UIColor.blue
                }
                if val == 0 {
                    self.lightSlider.minimumTrackTintColor = UIColor.lightGray
                }
            }
        }
    }
    
    func updateStatus(payload json: JSON) {
        if let temperatureReported = json["state"]["reported"]["temperature"].double {
            temperatureDisplayValue = temperatureReported
        }
        if let humidityReported = json["state"]["reported"]["humidity"].double {
            humidityDisplayValue = humidityReported
        }
        if let lightReported = json["state"]["reported"]["custom_light"].int {
            if lightSliderValue == lightReported {
                lightSliderWaitingForSync = 0
            }
            else if lightSliderWaitingForSync < maxTime && lightSliderWaitingForSync > 0 {
                lightSliderWaitingForSync = lightSliderWaitingForSync + 1
            }
            else if lightSliderWaitingForSync >= maxTime {
                lightSliderValue = lightReported
                lightSliderWaitingForSync = 0
                print("Couldn't update lightSlider")
                lightSlider.minimumTrackTintColor = UIColor.lightGray
            }
        }
    }
    
    func deviceShadowCallback(name:String, operation:AWSIoTShadowOperationType, operationStatus:
        AWSIoTShadowOperationStatusType, clientToken:String, payload:Data){
//        self.iotDataManager.getShadow(thingName)
        print("callback")
        DispatchQueue.main.async {
            let json = JSON(data: (payload as NSData!) as Data)
            let stringValue = NSString(data: payload, encoding: String.Encoding.utf8.rawValue)
            switch(operationStatus) {
            case .accepted:
                print("accepted on \(name)")
                self.thingShadowAcceptedCallback(json: json, payloadString: stringValue as! String)
            case .rejected:
                print("rejected on \(name)")
                self.thingShadowRejectedCallback(json: json, payloadString: stringValue as! String)
            case .delta:
                print("delta on \(name)")
                self.thingShadowDeltaCallback(json: json, payloadString: stringValue as! String)
            case .timeout:
                print("timeout on \(name)")
                self.thingShadowTimeoutCallback(json: json, payloadString: stringValue as! String)
            default:
                print("unknown operation status: \(operationStatus.rawValue)")
            }
        }
    }
        
    func thingShadowTimeoutCallback(json: JSON, payloadString: String ) -> Void {
        thingOperationInProgress = false;
        getThingState()
    }
    
    func thingShadowDeltaCallback(json: JSON, payloadString: String ) -> Void {
    }
    
    func thingShadowAcceptedCallback(json: JSON, payloadString: String ) -> Void {
        if json["state"]["reported"] != nil {
            updateStatus(payload: json)
        }
        thingOperationInProgress = false;
    }
    
    func thingShadowRejectedCallback(json: JSON, payloadString: String ) -> Void {
        thingOperationInProgress = false
        print("operation rejected on: \(thingName)")
    }
    
    func slideEnded() {
        print("\(scheduleSlider.value)")
        let schedule = "[['day',\(Int(scheduleSlider.value))],['night','1800']]"
        self.iotDataManager.publishString(_: schedule, onTopic: "schedule", qoS: .messageDeliveryAttemptedAtLeastOnce)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCircularSlider()
        setupTapGesture()
        
        // Use Cognito authentication
        let credentialProvider = AWSCognitoCredentialsProvider(regionType: AwsRegion, identityPoolId: CognitoIdentityPoolId)
        let iotEndPoint = AWSEndpoint(urlString: IOT_ENDPOINT)
        let iotDataConfiguration = AWSServiceConfiguration(
            region: AwsRegion,
            endpoint: iotEndPoint,
            credentialsProvider: credentialProvider)
        
        // Init IOT
        AWSIoTDataManager.register(with: iotDataConfiguration!, forKey: "MyIotDataManager")
        iotDataManager = AWSIoTDataManager(forKey: "MyIotDataManager")
        
        #if DEMONSTRATE_LAST_WILL_AND_TESTAMENT
            //
            // Set a Last Will and Testament message in the MQTT configuration; other
            // clients can subscribe to this topic, and if this client disconnects from
            // from AWS IoT unexpectedly, they will receive the message defined here.
            //
            // To enable this code, add '-DDEMONSTRATE_LAST_WILL_AND_TESTAMENT' to
            // your project build flags in:
            //
            //    Build Settings -> Swift Compiler - Custom Flags -> Other Swift Flags
            //
            // IMPORTANT NOTE FOR SWIFT PROGRAMS: When specifying the Last Will and Testament
            // message in Swift, make sure to use the NSString data type; this object must
            // support the dataUsingEncoding selector, which is not available in Swift's
            // native String type.
            //
            let lwtTopic: NSString = "temperature-control-last-will-and-testament"
            let lwtMessage: NSString = "disconnected"
            self.iotDataManager.mqttConfiguration.lastWillAndTestament.topic = lwtTopic as String
            self.iotDataManager.mqttConfiguration.lastWillAndTestament.message = lwtMessage as String
            self.iotDataManager.mqttConfiguration.lastWillAndTestament.qos = .AtMostOnce
        #endif
        // Connect via WebSocket
        self.iotDataManager.connectUsingWebSocket( withClientId: UUID().uuidString, cleanSession:true, statusCallback: mqttEventCallback)
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

// MARK: - CircularSliderDelegate
extension ViewController: CircularSliderDelegate {
    func circularSlider(_ circularSlider: CircularSlider, valueForValue value: Float) -> Float {
        return floorf(value)
    }
}

