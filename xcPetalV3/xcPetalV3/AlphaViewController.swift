//
//  alphaViewController.swift
//  dDayListServ
//
//  Created by Andrea Yepez on 8/9/17.
//  Copyright © 2017 Okavango Systems. All rights reserved.
//

import UIKit
import AWSIoT
import AWSCore

class AlphaViewController: UIViewController {
    
    var email: String?
    
    @IBAction func noAlpha(_ sender: Any) {
    }
    
    @IBAction func yesAlpha(_ sender: Any) {
        let iotDataManager = AWSIoTDataManager.default()
        if let email = self.email {
            iotDataManager.publishString("{\"email\": \"\(email)\"}", onTopic: "alpha", qoS: .messageDeliveryAttemptedAtLeastOnce)
        }
    }
    
//    @IBAction func yesAlpha(_ sender: UIButton) {
//        //send corresponding data to AWS
//    }
//    @IBAction func noAlpha(_ sender: UIButton) {
//        //send corresponding data to AWS
//    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
