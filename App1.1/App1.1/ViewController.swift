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

let thingName = "myThingName"

class ViewController: UIViewController {
    
    var iotDataManager: AWSIoTDataManager!
    
    @IBOutlet weak var temperatureDisplay: UILabel!
    @IBOutlet weak var humidityDisplay: UILabel!
    @IBOutlet weak var lightSlider: UISlider!
    
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
                //                self.iotDataManager.subscribe(topic: "$aws/things/myThingName/shadow/update", qos: AWSIoTMQTTQoSAtLeastOnce, callback: self.deviceShadowCallback)
                
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
    
    func deviceShadowCallback(name:String, operation:AWSIoTShadowOperationType, operationStatus:
        AWSIoTShadowOperationStatusType, clientToken:String, payload:Data){
        self.iotDataManager.getShadow(thingName)
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
        //            if desired custom light exists print that in red else reported
        //            if json["state"]["desired"]["custom_light"].int != nil {
        //                print("if statement")
        //                updateControl( json["state"]["desired"]["custom_light"].int,
        //                    enabled: json["state"]["desired"]["enabled"].bool );
        //            }
        //            else {
        //                print("else statement")
        
        
//        var k = json["state"]["reported"]["custom_light"].int;
//        if (k != currentSetpoint) {
//            counter = counter + 1;
//            if (counter >= 30) {
//                currentSetpoint = k!;
//                updateControl( json["state"]["reported"]["custom_light"].int,
//                               enabled: json["state"]["desired"]["enabled"].bool );
//                controlThingOperationInProgress = false;
//                counter = 0
//            }
//        }
//        else {
//            counter = 0;
//            updateControl( json["state"]["reported"]["custom_light"].int,
//                           enabled: json["state"]["desired"]["enabled"].bool );
//            controlThingOperationInProgress = false;
//        }
//        //            }
//        print("HERE ACCEPTED")
//        print(json)
//        updateStatus( json["state"]["reported"]["temperature"].int,
//                      exteriorTemperature: json["state"]["reported"]["humidity"].int,
//                      state: json["state"]["desired"]["curState"].string );
        
        temperatureDisplayValue = json["state"]["reported"]["temperature"].double!
        humidityDisplayValue = json["state"]["reported"]["humidity"].double!
        
        thingOperationInProgress = false;
    }
    
    func thingShadowRejectedCallback(json: JSON, payloadString: String ) -> Void {
        thingOperationInProgress = false
        print("operation rejected on: \(thingName)")
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Initialize the setpoint stepper
//        setpointStepper.wraps=false
//        setpointStepper.maximumValue=90
//        setpointStepper.minimumValue=50
//        setpointStepper.value=70
//        currentSetpointStepValue = setpointStepper.value
//        // Initialize the temperature and setpoint labels
//        interiorLabel.text="60"
//        exteriorLabel.text="45"
//        setpointLabel.text=setpointStepper.value.description
//        // Initialize the status switch
//        statusSwitch.isOn=true
        
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
