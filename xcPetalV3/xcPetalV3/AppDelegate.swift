//
//  AppDelegate.swift
//  xcPetalV3
//
//  Created by Andrea Yepez on 7/23/17.
//  Copyright © 2017 Okavango Systems. All rights reserved.
//

import UIKit
import AWSCore
import AWSIoT

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let thingName: String = "pi5"
    var iotDataManager: AWSIoTDataManager!;
    
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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Default credentials and configuration
        let credentialProvider = AWSCognitoCredentialsProvider(regionType: AwsRegion, identityPoolId: CognitoIdentityPoolId)
        let configuration = AWSServiceConfiguration(region: .USEast2, credentialsProvider: credentialProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        // Use Cognito authentication
        let iotEndPoint = AWSEndpoint(urlString: IOT_ENDPOINT)
        let iotDataConfiguration = AWSServiceConfiguration(
            region: AwsRegion,
            endpoint: iotEndPoint,
            credentialsProvider: credentialProvider)
        
        // Init IOT
        AWSIoTDataManager.register(with: iotDataConfiguration!, forKey: "MyIotDataManager")
        iotDataManager = AWSIoTDataManager(forKey: "MyIotDataManager")
        
        #if DEMONSTRATE_LAST_WILL_AND_TESTAMENT
            let lwtTopic: NSString = "temperature-control-last-will-and-testament"
            let lwtMessage: NSString = "disconnected"
            self.iotDataManager.mqttConfiguration.lastWillAndTestament.topic = lwtTopic as String
            self.iotDataManager.mqttConfiguration.lastWillAndTestament.message = lwtMessage as String
            self.iotDataManager.mqttConfiguration.lastWillAndTestament.qos = .AtMostOnce
        #endif
        
        // Connect via WebSocket
        self.iotDataManager.connectUsingWebSocket( withClientId: UUID().uuidString, cleanSession:true, statusCallback: mqttEventCallback)
        
        //Setting up logging to xcode console.
        AWSDDLog.sharedInstance.logLevel = .debug
        AWSDDLog.add(AWSDDTTYLogger.sharedInstance)
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }
}

