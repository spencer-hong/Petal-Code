//
//  popupViewController.swift
//  dDayListServ
//
//  Created by Andrea Yepez on 8/9/17.
//  Copyright © 2017 Okavango Systems. All rights reserved.
//

import UIKit
import AWSIoT
import AWSCore

class FirstPopUpViewController: UIViewController {
    
    var email: String?
    
    @IBOutlet weak var lastText: UITextField!
    @IBOutlet weak var firstText: UITextField!
    @IBOutlet weak var emailText: UITextField!
    
    @IBAction func cancelPopup(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submitPopup(_ sender: Any) {
        let iotDataManager = AWSIoTDataManager.default()
        if let email = emailText.text {
            if email != "" {
                iotDataManager.publishString("{\"email\": \"\(email)\", \"first\": \"\(firstText.text!)\", \"last\": \"\(lastText.text!)\"}", onTopic: "newsletter", qoS: .messageDeliveryAttemptedAtLeastOnce)
                self.email = email
            }   
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? AlphaViewController {
            destination.email = self.email
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
