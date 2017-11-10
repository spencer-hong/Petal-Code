//
//  AWS.swift
//  xcPetalV3
//
//  Created by Bhai Jaiveer Singh on 8/1/17.
//  Copyright © 2017 Okavango Systems. All rights reserved.
//

import Foundation
import AWSIoT
import SwiftyJSON

class AWS {
    
    let thingName = "pi3"
    
    var temperature = 20
    
    var humidity = 20
    
    var iotDataManager: AWSIoTDataManager!
    
    func register() {
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
    }
    
    @objc func getThingState() {
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
                self.iotDataManager.register(withShadow: self.thingName, options:nil,  eventCallback: self.deviceShadowCallback)
                self.iotDataManager.subscribe(toTopic: "$aws/things/\(self.thingName)/shadow/update/accepted", qoS: AWSIoTMQTTQoS.messageDeliveryAttemptedAtLeastOnce, messageCallback: self.update)
                
                // Two seconds after registering the device shadows, retrieve their current states.
                Timer.scheduledTimer( timeInterval: 2.5, target: self, selector: #selector(self.getThingState), userInfo: nil, repeats: false )
                
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
        getThingState()
    }
    
    func thingShadowDeltaCallback(json: JSON, payloadString: String ) -> Void {
    }
    
    func thingShadowAcceptedCallback(json: JSON, payloadString: String ) -> Void {
        if json["state"]["reported"] != nil {
            updateStatus(payload: json)
        }
    }
    
    func thingShadowRejectedCallback(json: JSON, payloadString: String ) -> Void {
        print("operation rejected on: \(thingName)")
    }
    
    func update(payload: Data) {
        DispatchQueue.main.async {
            let json = JSON(data: (payload as NSData!) as Data)
            if json["state"]["reported"] != nil {
                self.updateStatus(payload: json)
            }
        }
    }
    
    func updateStatus(payload json: JSON) {
        if let temperatureReported = json["state"]["reported"]["temperature"].double {
            temperature = Int(temperatureReported)
        }
        if let humidityReported = json["state"]["reported"]["humidity"].double {
            humidity = Int(humidityReported)
        }
    }

}
