//
//  ViewController.swift
//  xcPetalV3
//
//  Created by Andrea Yepez on 7/23/17.
//  Copyright © 2017 Okavango Systems. All rights reserved.
//

import UIKit
import AWSIoT
import SwiftyJSON


class HomeViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource{
    
    let thingName = "pi5"
    var lastSlider: Int = 0
    
    //OUTLETS AND ACTIONS
    
//    @IBOutlet weak var lightSlider: UISlider!
    @IBOutlet weak var lightButton: UISwitch!
    
//    var oceanColor = UIColor(hexString: "#004080")
    var oceanColor = UIColor(hexString: "#8AC18A")
    var lightSliderWaitingForSync = false
    var lightTimer = Timer()
    var thingOperationInProgress = false
    
//    
//    var lightSliderValue: Int {
//        get {
//            return Int(lightSlider.value)
//        }
//        set {
//            lightSlider.value = Float(newValue)
//            lastSlider = newValue
//        }
//    }
    
    func startTimer(){
        lightTimer = Timer.scheduledTimer(timeInterval: 3, target: self,   selector: (#selector(HomeViewController.lightTimeOut)), userInfo: nil, repeats: false)
    }
    
    func resetTimer(){
        lightTimer.invalidate()
        startTimer()
    }
    
    func lightTimeOut() {
        lightSliderWaitingForSync = false
        getShadowOf(thingName)
    }
    
    func getShadowOf(_ thingName: String) {
        let iotDataManager = AWSIoTDataManager.default()
        iotDataManager.publishString("", onTopic: "$aws/things/\(thingName)/shadow/get", qoS: .messageDeliveryAttemptedAtLeastOnce)
    }
    
//    let step: Float = 10
//    @IBAction func lightChanging(_ sender: UISlider) {
//        let iotDataManager = AWSIoTDataManager.default()
//        let roundedValue = round(sender.value / step) * step
//        sender.value = roundedValue
//        sender.minimumTrackTintColor = oceanColor
//        lightSliderWaitingForSync = true
//        resetTimer()
//        if Int(sender.value) != lastSlider {
//            //            iotDataManager.publishString("{\"state\":{\"desired\":{\"light\": \(sender.value)}}}", onTopic: "$aws/things/\(thingName)/shadow/update", qoS: .messageDeliveryAttemptedAtLeastOnce)
//            iotDataManager.publishString("\(sender.value)", onTopic: "\(thingName)/change_light", qoS: .messageDeliveryAttemptedAtLeastOnce)
//            lastSlider = Int(sender.value)
//        }
//    }
    
    @IBAction func lightChanging(_ sender: UISwitch) {
        let iotDataManager = AWSIoTDataManager.default()
        let roundedValue = sender.isOn ? 100 : 0
        iotDataManager.publishString("\(roundedValue)", onTopic: "\(thingName)/change_light", qoS: .messageDeliveryAttemptedAtLeastOnce)
    }

    func subLightOverride(a: NSObject, b: String, payload: Data) {
        DispatchQueue.main.async {
            let json = JSON(data: (payload as NSData!) as Data)
            let temp = String(describing: json)
            if let val = Int(temp) {
                if val == 1 {
//                    self.lightSlider.minimumTrackTintColor = self.oceanColor
                }
                if val == 0 {
                    self.lightSliderWaitingForSync = false
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
            self.thingOperationInProgress = false;
        }
    }
    
    func updateStatus(payload json: JSON) {
        print("updating status")
        if lightSliderWaitingForSync == false {
            if let lightReported = json["state"]["reported"]["light"].int {
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

    
    @IBOutlet weak var plantOneImage: UIImageView!
    @IBOutlet weak var plantTwoImage: UIImageView!
    @IBOutlet weak var plantThreeImage: UIImageView!
    @IBOutlet weak var plantFourImage: UIImageView!
    
    @IBOutlet weak var plantOneLabel: UILabel!
    @IBOutlet weak var plantTwoLabel: UILabel!
    @IBOutlet weak var plantThreeLabel: UILabel!
    @IBOutlet weak var plantFourLabel: UILabel!
    
    @IBOutlet weak var plantOneBackground: UIButton!
    @IBOutlet weak var plantTwoBackground: UIButton!
    @IBOutlet weak var plantThreeBackground: UIButton!
    @IBOutlet weak var plantFourBackground: UIButton!
    
    @IBAction func plantOneButton(_ sender: UIButton) {
        if isSlotFilled(slotKey: "slotOne") {
            showTendAlert(slotKey: "slotOne")
        }
        
        else {
            showSowAlertPt1(slotKey: "slotOne")
        }
    }

    @IBAction func plantTwoButton(_ sender: UIButton) {
        if isSlotFilled(slotKey: "slotTwo") {
            showTendAlert(slotKey: "slotTwo")
        }
        
        else {
            showSowAlertPt1(slotKey: "slotTwo")
        }
    }
    
    @IBAction func plantThreeButton(_ sender: UIButton) {
        if isSlotFilled(slotKey: "slotThree") {
            showTendAlert(slotKey: "slotThree")
        }
        
        else {
            showSowAlertPt1(slotKey: "slotThree")
        }
    }
    
    @IBAction func plantFourButton(_ sender: UIButton) {
        if isSlotFilled(slotKey: "slotFour") {
            showTendAlert(slotKey: "slotFour")
        }
            
        else {
            showSowAlertPt1(slotKey: "slotFour")
        }
    }
    
    //INITIAL SETUP
    let plantOptions: [String]? = ["Basil", "Bay", "Chives", "Cilantro", "Dill", "Mesclun", "Micros", "Mint", "Oregano", "Parsley", "Rosemary", "Sage", "Tarragon", "Thyme"]
    var imageOutletDict: [String: UIImageView] = [:]
    var labelOutletDict: [String: UILabel] = [:]
    var pickedPlant: String = "Basil"
    var pickedDate = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let iotDataManager = AWSIoTDataManager.default()
        iotDataManager.subscribe(toTopic: "$aws/things/\(thingName)/shadow/update/accepted", qoS: AWSIoTMQTTQoS.messageDeliveryAttemptedAtLeastOnce, messageCallback: self.update)
//        iotDataManager.subscribe(toTopic: "\(thingName)/light_override", qoS: AWSIoTMQTTQoS.messageDeliveryAttemptedAtLeastOnce, extendedCallback: self.subLightOverride)
        iotDataManager.subscribe(toTopic: "$aws/things/\(thingName)/shadow/get/accepted", qoS: AWSIoTMQTTQoS.messageDeliveryAttemptedAtLeastOnce, messageCallback: self.update)
        iotDataManager.publishString("", onTopic: "$aws/things/\(thingName)/shadow/get", qoS: .messageDeliveryAttemptedAtLeastOnce)
        plantOneBackground.layer.cornerRadius = 10
        plantTwoBackground.layer.cornerRadius = 10
        plantThreeBackground.layer.cornerRadius = 10
        plantFourBackground.layer.cornerRadius = 10
        
        plantOneBackground.layer.borderWidth = 0.5
        plantOneBackground.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
        
        plantTwoBackground.layer.borderWidth = 0.5
        plantTwoBackground.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
        
        plantThreeBackground.layer.borderWidth = 0.5
        plantThreeBackground.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
        
        plantFourBackground.layer.borderWidth = 0.5
        plantFourBackground.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
        
        imageOutletDict = ["slotOne": plantOneImage, "slotTwo": plantTwoImage, "slotThree": plantThreeImage, "slotFour": plantFourImage]
        
        labelOutletDict = ["slotOne": plantOneLabel, "slotTwo": plantTwoLabel, "slotThree": plantThreeLabel, "slotFour": plantFourLabel]
        
        loadSlots(imageArray: imageOutletDict, labelArray: labelOutletDict)
    }
    
    func loadSlots (imageArray: [String: UIImageView], labelArray: [String: UILabel]) {
        
        let slotKeyArray: [String] = ["slotOne", "slotTwo", "slotThree", "slotFour"]
        
        for slotKey in slotKeyArray {
            let imageOutlet = imageArray[slotKey]!
            let labelOutlet = labelArray[slotKey]!
            
            if (isSlotFilled(slotKey: slotKey)) {
                //show image and label
                let plantData = UserDefaults.standard.object(forKey: slotKey) as! [String:Any]
                let plantName = plantData["status"] as! String
                
                imageOutlet.image = UIImage(named: plantName)
                labelOutlet.text = plantName
            }
            
            else {
                //empty image and label
                imageOutlet.image = nil
                labelOutlet.text = nil

            }
        }
    }
    
    //ALERTS
    
    //shows step one of plant addition
    func showSowAlertPt1 (slotKey: String) {
        
        //setup
        let sowPt1VC = UIViewController()
        sowPt1VC.preferredContentSize = CGSize(width: 250,height: 300)
        
        let plantPickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: 250, height: 300))
        plantPickerView.tag = 1
        plantPickerView.delegate = self
        plantPickerView.dataSource = self
        
        sowPt1VC.view.addSubview(plantPickerView)
        
        let choosePlantAlert = UIAlertController(title: "Choose Plant", message: "", preferredStyle: UIAlertControllerStyle.alert)
        choosePlantAlert.setValue(sowPt1VC, forKey: "contentViewController")
        
        //add buttons
        choosePlantAlert.addAction(UIAlertAction(title: "Next", style: .default, handler: { action in
            self.showSowAlertPt2(slotKey: slotKey)
        }))
        choosePlantAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            self.resetPickers()
        }))
        
        //show alert
        self.present(choosePlantAlert, animated: true)
    }
    
    //show step two of plant addition, store data, (animation?), notification pop-up, reload view
    func showSowAlertPt2 (slotKey: String) {
        
        //setup
        let sowPt2VC = UIViewController()
        sowPt2VC.preferredContentSize = CGSize(width: 250,height: 300)
        
        let datePickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: 250, height: 300))
        datePickerView.tag = 2
        datePickerView.delegate = self
        datePickerView.dataSource = self
        
        sowPt2VC.view.addSubview(datePickerView)
        
        let choosePlantAlert = UIAlertController(title: "Choose Plant Date", message: "You will recieve a notification when your plant is ready to harvest", preferredStyle: UIAlertControllerStyle.alert)
        choosePlantAlert.setValue(sowPt2VC, forKey: "contentViewController")
        
        //add buttons
        choosePlantAlert.addAction(UIAlertAction(title: "Sow", style: .destructive, handler: { action in
            self.saveEntry(slotKey: slotKey)
            self.resetPickers()
        }))
        choosePlantAlert.addAction(UIAlertAction(title: "Back", style: .default, handler: { action in self.showSowAlertPt1(slotKey: slotKey)
        }))
        choosePlantAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            self.resetPickers()
        }))
        
        //show alert
        self.present(choosePlantAlert, animated: true)
    }
    
    func showTendAlert (slotKey: String) {
        let tendAlert = UIAlertController(title: "Tend to My Garden", message: "", preferredStyle: UIAlertControllerStyle.alert)
    
        //add buttons
        tendAlert.addAction(UIAlertAction(title: "Harvest", style: UIAlertActionStyle.default, handler: { action in
        self.harvest(slotKey: slotKey)
        }))

        //edits cart
        tendAlert.addAction(UIAlertAction(title: "+1 to Cart", style: UIAlertActionStyle.default, handler: { action in
            self.plusOneAlert(slotKey: slotKey)
        }))
        
        //leads to view with mini-wiki OR showSowAlert1?
        tendAlert.addAction(UIAlertAction(title: "Change Entry", style: UIAlertActionStyle.default, handler: { action in
            self.showSowAlertPt1(slotKey: slotKey)
        }))
        
        tendAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        //show the alert
        self.present(tendAlert, animated: true, completion:  nil)
    }
    
    func plusOneAlert (slotKey: String) {
        
        let slotData: [String: Any] = UserDefaults.standard.object(forKey: slotKey) as! [String : Any]
        let plantType: String = slotData["status"] as! String
        
        let confirmAlert = UIAlertController(title: "", message: "You added " + plantType + " to your cart", preferredStyle: UIAlertControllerStyle.alert)
        
        //add buttons
        confirmAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { action in
            self.addToCart(slotKey: slotKey)
        }))
        
        //show the alert
        self.present(confirmAlert, animated: true, completion:  nil)
    }
    
    //PICKER SETUP
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
        
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent: Int) -> Int {
        
        //for sowPt1
        if (pickerView.tag == 1) {
            return (plantOptions?.count)!
        }
            
        //for sowPt2
        else {
            return 3
        }
    }
        
    func pickerView(_ pickerView : UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        //for sowpt1
        if (pickerView.tag == 1) {
            return plantOptions?[row]
        }
            
        //for sowpt2
        else {
            let dayOptions = ["Today", "Yesterday", "Two Days Ago"]
            return dayOptions[row]
        }
    }
        
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        //for sowpt1
        if (pickerView.tag == 1) {
            pickedPlant = (plantOptions?[row])!
        }
            
        //for sowpt2
        else {
            if (row == 1) {
                pickedDate = Date()
            } else if (row == 2) {
                pickedDate = pickedDate.addingTimeInterval(TimeInterval(-86400))
            } else {
                pickedDate = pickedDate.addingTimeInterval(TimeInterval(-172800))
            }
        }
    }
    
    //ADDITIONAL FUNCTIONS
    
    func addToCart (slotKey: String) {
        //extract plantType from slot
        let slotData: [String: Any] = UserDefaults.standard.object(forKey: slotKey) as! [String : Any]
        let plantType: String = slotData["status"] as! String
        
        //update cart
        let previousCartCount: Int? = UserDefaults.standard.object(forKey: plantType) as? Int
        
        if (previousCartCount == nil) {
            UserDefaults.standard.set(1, forKey: plantType)
        }
        
        else {
            UserDefaults.standard.set(previousCartCount! + 1, forKey: plantType)
        }
        
    }
    
    func resetPickers() {
        pickedPlant = "Basil"
        pickedDate = Date()
    }
    
    func harvest(slotKey: String) {
        let slotData = ["status":"empty"]
        UserDefaults.standard.set(slotData, forKey: slotKey)
        
        reloadData(slotKey: slotKey)
    }
    
    func saveEntry (slotKey: String) {
        let slotData = ["status": pickedPlant, "sowDate": pickedDate] as [String : Any]
        UserDefaults.standard.set(slotData, forKey: slotKey)
     
        reloadData(slotKey: slotKey)
    }
    
    func reloadData(slotKey: String) {
        
        let imageOutlet = imageOutletDict[slotKey]!
        let labelOutlet = labelOutletDict[slotKey]!
        
        if (isSlotFilled(slotKey: slotKey)) {
            let plantData = UserDefaults.standard.object(forKey: slotKey) as! [String:Any]
            let plantName = plantData["status"] as! String
            
            imageOutlet.image = UIImage(named: plantName)
            labelOutlet.text = plantName
            
            DispatchQueue.main.async {
                imageOutlet.setNeedsDisplay()
                labelOutlet.setNeedsDisplay()
            }
        }
        
        else {
            //empty image and label
            imageOutlet.image = nil
            labelOutlet.text = nil
        }
    }
    
    func isSlotFilled(slotKey: String) -> Bool {
        let slotData = UserDefaults.standard.object(forKey: slotKey) as? [String:Any]
        
        if (slotData == nil) {
            return false
        }
        
        else {
            let status = slotData?["status"] as? String
            
            if (status == "empty") {
                return false
            } else {
                return true
            }
        }
    }
    
    
}
