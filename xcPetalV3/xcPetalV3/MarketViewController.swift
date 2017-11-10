//
//  MarketViewController.swift
//  notifTest
//
//  Created by Andrea Yepez on 7/19/17.
//  Copyright © 2017 Okavango Systems. All rights reserved.
//

import UIKit

struct Global {
}

class MarketViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var cartLabel: UILabel!
    
    let browseOptions: [String]? = ["Basil", "Bay", "Chives", "Cilantro", "Dill", "Mesclun", "Micros", "Mint", "Oregano", "Parsley", "Rosemary", "Sage", "Tarragon", "Thyme"]
    var totalCartCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        countCart()
        updateCartCountLabel()
        
        //register to notification cartIsChanging
        NotificationCenter.default.addObserver(self, selector: #selector(cartIsChanging(n:)), name: NSNotification.Name.init("CartIsChanging"), object: nil)
        
        //register to notification cartStoppedChanging
        NotificationCenter.default.addObserver(self, selector: #selector(cartStoppedChanging(n:)), name: NSNotification.Name.init("CartStoppedChanging"), object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateCartCountLabel() {
        
        if (totalCartCount != 1) {
            cartLabel.text = String(describing: (totalCartCount)) + " Plants"
        }
        
        else {
            cartLabel.text = String(describing: (totalCartCount)) + " Plant"
        }
    }
    
    func countCart() {
       
        totalCartCount = 0
        
        for plants in browseOptions! {
            let individualCount = UserDefaults.standard.object(forKey: plants)
            if (individualCount != nil){
                totalCartCount += individualCount as! Int
            }
        }
    }
    
    func cartIsChanging(n:NSNotification) {
        
        //change cart count
        totalCartCount = 0
        for plants in browseOptions! {
            let individualCount = UserDefaults.standard.object(forKey: plants)
            if (individualCount != nil){
                totalCartCount += individualCount as! Int
            }
        }
        
        //update label number and font
        DispatchQueue.main.async {
            self.updateCartCountLabel()
            self.cartLabel.font = UIFont.systemFont(ofSize: 17, weight: UIFontWeightSemibold)
            self.cartLabel.setNeedsDisplay()
        }
        
    }
    
    func cartStoppedChanging(n: NSNotification) {
        DispatchQueue.main.async {
            self.cartLabel.font = UIFont.systemFont(ofSize: 17, weight: UIFontWeightThin)
            self.cartLabel.setNeedsDisplay()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (browseOptions?.count)!
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "option cell", for: indexPath) as! MyCell
        
        //Plant count, label and image
        let plantType = browseOptions?[indexPath.item]
        
        cell.orderCountLabel.layer.cornerRadius = 10
        
        cell.plantLabel.text = plantType
        
        cell.plantImage.image = UIImage(named: plantType!)
        cell.imageBackground.layer.cornerRadius = 8
        cell.imageBackground.layer.borderWidth = 0.5
        cell.imageBackground.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
        
        let initialPlantCount = UserDefaults.standard.object(forKey: plantType!)
        
        if (initialPlantCount != nil) {
            cell.orderCountLabel.text = String(describing: (initialPlantCount)!)
            cell.initialSlider.value = initialPlantCount as! Float
        }
        
        else {
            cell.orderCountLabel.text = "0"
        }
        
        return cell
    }
}

class MyCell : UICollectionViewCell {
    
    @IBOutlet weak var imageBackground: UIView!
    @IBOutlet weak var plantImage: UIImageView!
    @IBOutlet weak var plantLabel: UILabel!
    @IBOutlet weak var orderCountLabel: UILabel!
    @IBOutlet weak var initialSlider: UISlider!
    @IBAction func orderSlider(_ sender: UISlider) {
        
        //pull new cart value
        let newOrderCount = Int(sender.value)
        
        if (sender.isTracking) {
            //notify View class that cart changed so labtel updates and bold text
            NotificationCenter.default.post(name: NSNotification.Name.init("CartIsChanging"), object: nil)
        } else {
            //notify view class to change unbold cart text
            NotificationCenter.default.post(name: NSNotification.Name.init("CartStoppedChanging"), object: nil)
        }
        
        //update ordercountlabel
        orderCountLabel.text = String(newOrderCount)
        
        //update stored value
        UserDefaults.standard.set(newOrderCount, forKey: plantLabel.text!)
        
    }
}

