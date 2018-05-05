//
//  MainVC.swift
//  私家厨房
//
//  Created by Admin on 28/03/2018.
//  Copyright © 2018 待定. All rights reserved.
//

import UIKit

class MainVC: UIViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var dateLabel: UIButton!
    @IBOutlet weak var catagoryLabel: UIButton!
    @IBOutlet weak var reserveButton: UIButton!
    
    var reservedMeals : ReservedMeals?
    
    @IBAction func reserveMeals(_ sender: UIButton) {
        reservedMeals = ReservedMeals((dateLabel.titleLabel?.text)!, (catagoryLabel.titleLabel?.text)!, nil)
        StateController.share.saveReservedMeals(reservedMeals)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        self.loadSavedMealList()
    }
    
    @IBAction func check(_ sender: UIButton) {
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        self.loadSavedMealList()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.backgroundColor = UIColor.green
        self.navigationController?.tabBarController?.tabBar.backgroundColor = UIColor.green
        updateReserveButton()
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(true)
//        self.navigationController?.tabBarController?.tabBar.isHidden = false
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension MainVC {
    static func dateConvertString(date:Date, dateFormat:String="yyyy-MM-dd") -> String {
        //        let timeZone = TimeZone.init(identifier: "UTC")
        let formatter = DateFormatter()
        //        formatter.timeZone = timeZone
        formatter.locale = Locale.init(identifier: "zh_CN")
        formatter.dateFormat = dateFormat
        let date = formatter.string(from: date)
        return date.components(separatedBy: " ").first!
    }
    
    func loadSavedMealList() {
        HandleCoreData.clearAllMealSelectionStatus()
        
        let key = (self.dateLabel.titleLabel?.text)!+(self.catagoryLabel.titleLabel?.text!)!
        let archiveURL = DataStore.objectURLForKey(key: key)
        if let reserveMeals = NSKeyedUnarchiver.unarchiveObject(withFile: archiveURL.path) as? ReservedMeals {
            print("Loading reservedMeals from disk")
            let mealIdentifers = reserveMeals.mealsIdentifiers
            for mealIdentifer in mealIdentifers! {
                HandleCoreData.updateMealSelectionStatus(identifier: mealIdentifer)
            }
        }
    }
    
    func updateReserveButton() {
        if dateLabel.titleLabel?.text == "日期" || catagoryLabel.titleLabel?.text == "餐类" {
            reserveButton.isEnabled = false
            reserveButton.backgroundColor = UIColor.lightGray
        }
        else {
            reserveButton.isEnabled = true
            reserveButton.backgroundColor = UIColor(hex: 0x928CFF)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case SegueID.reserveMeals:
            print("reserveMeals tapped")
            
        case SegueID.checkMealsList:
            print("checkMealsList tapped")

        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
}

extension MainVC : DataTransferBackProtocol{
    
    //MARK: -Actions
    @IBAction func selectMealCatagory(_ sender: UIButton) {
        
        let storyBoard = UIStoryboard(name: StoryboardID.catagoryPopUpSB, bundle: nil)
        let popUpVC = storyBoard.instantiateInitialViewController()! as! CatagoryPopUpVC
        popUpVC.delegate = self
        popUpVC.catagory = ["早餐","午餐","晚餐"]
        
        self.present(popUpVC, animated: true)
    }
    
    @IBAction func selectDate(_ sender: UIButton) {
        
        let storyBoard = UIStoryboard(name: StoryboardID.calenderPopUpSB, bundle: nil)
        let popUpVC = storyBoard.instantiateInitialViewController()! as! CalenderPopUpVC
        popUpVC.delegate = self
        self.navigationController?.pushViewController(popUpVC, animated: true)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }
    
    @IBAction func unwindToMainVC(sender: UIStoryboardSegue) {
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        
        dateLabel.setTitle("日期", for: UIControlState.normal)
        let dateImage = UIImage(named: AssetNames.calender)
        dateLabel.setImage(dateImage, for: .normal)
        
        catagoryLabel.setTitle("餐类", for: UIControlState.normal)
        let catagoryImage = UIImage(named: AssetNames.mealCategory)
        catagoryLabel.setImage(catagoryImage, for: .normal)
		updateReserveButton()
    }
    
    func stringTransferBack(string: String) {
        catagoryLabel.setTitle(string, for: UIControlState.normal)
        catagoryLabel.setImage(nil, for: .normal)
        catagoryLabel.backgroundColor = UIColor(hex: 0x15C425)
        updateReserveButton()
    }
    
    func dateTransferBack(date: Date) {
        print("dataTransferBack was running")
        
        let dateString = MainVC.dateConvertString(date: date)
        dateLabel.setTitle(dateString, for: UIControlState.normal)
        dateLabel.setImage(nil, for: .normal)
        dateLabel.backgroundColor = UIColor(hex: 0x15C425)
        
        updateReserveButton()
    }
}
