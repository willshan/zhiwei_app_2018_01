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
    var stateController : StateController!
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var catagoryLabel: UILabel!
    @IBOutlet weak var reserveButton: UIButton!
    
    var reservedMeals : ReservedMeals?
    
    @IBAction func reserveMeals(_ sender: UIButton) {
        reservedMeals = ReservedMeals(dateLabel.text!, catagoryLabel.text!, nil)
        stateController.saveReservedMeals(reservedMeals)
        
        self.loadSavedMealList()
        self.presentTabNavigationVC()
        
    }
    
    @IBAction func check(_ sender: UIButton) {
        self.loadSavedMealList()
        self.presentTabNavigationVC()
    }
    
    static func dateConvertString(date:Date, dateFormat:String="yyyy-MM-dd") -> String {
        let timeZone = TimeZone.init(identifier: "UTC")
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = Locale.init(identifier: "zh_CN")
        formatter.dateFormat = dateFormat
        let date = formatter.string(from: date)
        return date.components(separatedBy: " ").first!
    }
    
    func loadSavedMealList() {
        
        HandleCoreData.clearAllMealSelectionStatus()
        
        let key = self.dateLabel.text!+self.catagoryLabel.text!
        let archiveURL = DataStore.objectURLForKey(key: key)
        if let reserveMeals = NSKeyedUnarchiver.unarchiveObject(withFile: archiveURL.path) as? ReservedMeals {
            print("Loading reservedMeals from disk")
            let mealIdentifers = reserveMeals.mealsIdentifiers
            for mealIdentifer in mealIdentifers! {
                HandleCoreData.updateMealSelectionStatus(identifier: mealIdentifer)
            }
        }
    }
    
    func presentTabNavigationVC() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        //tab0
        let orderMealController = mainStoryboard.instantiateViewController(withIdentifier: StoryboardID.mealListVC) as! MealListVC
        orderMealController.stateController = stateController
        let nav0 = UINavigationController(rootViewController: orderMealController)
        nav0.tabBarItem.image = UIImage(named: AssetNames.menu)
        nav0.title = "菜单"
        
        //tab1
        let shoppingCartController = mainStoryboard.instantiateViewController(withIdentifier: StoryboardID.shoppingCartVC) as! ShoppingCartVC
        shoppingCartController.stateController = stateController
        let nav1 = UINavigationController(rootViewController: shoppingCartController)
        
        let selectedMealsCount = stateController?.getSelectedMeals().count
        if selectedMealsCount != 0 {
            nav1.tabBarItem.badgeValue = "\(selectedMealsCount!)"
        }
        nav1.tabBarItem.image = UIImage(named: AssetNames.shoppingCart)
        nav1.title = "已点"
        
//        //tab2
//        let nav2 = UINavigationController()
//        nav2.tabBarItem.image = UIImage(named: AssetNames.message)
//        nav2.title = "消息"
        
        //tab3
        let personalCenterController = mainStoryboard.instantiateViewController(withIdentifier: StoryboardID.personalCenterVC) as! PersonalCenterVC
        personalCenterController.stateController = stateController
        let nav3 = UINavigationController(rootViewController: personalCenterController)
        nav3.tabBarItem.image = UIImage(named: AssetNames.personalCenter)
        nav3.title = "个人"
        
        let rootViewController = UITabBarController()
        let viewControllerArray = [nav0, nav1, nav3]
        rootViewController.viewControllers = viewControllerArray
        
        appDelegate.window?.rootViewController = rootViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stateController = appDelegate.stateController
        
        updateReserveButton()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension MainVC {

    func updateReserveButton() {
        if dateLabel.text == "日期" || catagoryLabel.text == "餐类" {
            reserveButton.isEnabled = false
            reserveButton.backgroundColor = UIColor.lightGray
        }
        else {
            reserveButton.isEnabled = true
            reserveButton.backgroundColor = UIColor(hex: 0x928CFF)
        }
    }
}

extension MainVC : DataTransferBackProtocol{
    //MARK: -Actions
    @IBAction func selectMealCatagory(_ sender: UITapGestureRecognizer) {
        
        let storyBoard = UIStoryboard(name: StoryboardID.catagoryPopUpSB, bundle: nil)
        let popUpVC = storyBoard.instantiateInitialViewController()! as! CatagoryPopUpVC
        popUpVC.delegate = self
        popUpVC.catagory = ["早餐","午餐","晚餐"]
        
        self.present(popUpVC, animated: true)
    }
    
    @IBAction func selectDate(_ sender: UITapGestureRecognizer) {
        
        let storyBoard = UIStoryboard(name: StoryboardID.datePopUpSB, bundle: nil)
        let popUpVC = storyBoard.instantiateInitialViewController()! as! DatePopUpVC
        popUpVC.delegate = self
        
        self.present(popUpVC, animated: true)
    }
    
    func stringTransferBack(string: String) {
        catagoryLabel.text = string

        updateReserveButton()
    }
    
    func dateTransferBack(date: Date) {
        print("dataTransferBack was running")
        
        let dateString = MainVC.dateConvertString(date: date)
        dateLabel.text = dateString
        
        updateReserveButton()
    }
}
