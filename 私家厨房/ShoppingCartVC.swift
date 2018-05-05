//
//  ShoppingCartViewController.swift
//  私家厨房
//
//  Created by Will.Shan on 02/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit

class ShoppingCartVC: UIViewController, UITableViewDelegate{

    @IBOutlet weak var firstTableView: UITableView!

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var catagoryLabel: UILabel!
    @IBOutlet weak var reserveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBAction func sentOut(_ sender: UIBarButtonItem) {
        saveToLocal()
    }
    
    @IBAction func saveMealList(_ sender: UIButton) {
        saveMealList()
    }
    
    @IBAction func cancelMealList(_ sender: UIButton) {
        cancelMealList()
    }

    var dataSource: ShoppingCartDataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        navigationItem.leftBarButtonItem = editButtonItem
        
        if StateController.share.reservedMeals != nil {
            dateLabel.text = StateController.share.reservedMeals?.date
            catagoryLabel.text = StateController.share.reservedMeals?.mealCatagory
        }
        
        updateReserveButton()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        print("view appear in shoppingCart vc")
        
        updateReserveButtonWhenSwithingVC()
        
        dataSource = ShoppingCartDataSource(selectedMeals: StateController.share.getSelectedMeals())
        dataSource.shoppingCartController = self

        firstTableView.dataSource = dataSource
        firstTableView.delegate = dataSource

        firstTableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        print("+++++++++++shoppingCartVC will disappear")
    }

    override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
            // Dispose of any resources that can be recreated.
        }

    deinit {
        print("instance shoppingCartVC was deinited")
    }
}
extension ShoppingCartVC {
    func saveMealList() {
        
        let title = "保存已点菜单?"
        let message = "确认保存当前日期内所有菜品么?"
        let ac = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        ac.addAction(cancelAction)
        
        let deleteAction = UIAlertAction(title: "保存", style: .destructive, handler: {
            (action) -> Void in
            
            let meals = StateController.share.getSelectedMeals()
            var mealIdentifers = [String]()
            for meal in meals {
                HandleCoreData.updateMealSelectionStatus(identifier: meal.identifier)
                mealIdentifers.append(meal.identifier)
            }
            
            //save resverd meals to disk
            StateController.share.saveReservedMeals(nil)
            
            let reserveMeals = ReservedMeals(self.dateLabel.text!, self.catagoryLabel.text!, mealIdentifers)
            let key = self.dateLabel.text!+self.catagoryLabel.text!
            let archiveURL = DataStore.objectURLForKey(key: key)
            
            NSKeyedArchiver.archiveRootObject(reserveMeals as Any, toFile: archiveURL.path)
            
            //update reservedMealsHistory in disk
            let key0 = "reservedMealsHistory"
            let archiveURL0 = DataStore.objectURLForKey(key: key0)
            
            if var historyList = NSKeyedUnarchiver.unarchiveObject(withFile: archiveURL0.path) as? [String] {
                if historyList.index(of: key) == nil {
                    historyList.append(key)
                    NSKeyedArchiver.archiveRootObject(historyList, toFile: archiveURL0.path)
                    print("保存预定到硬盘成功！！！")
                }
                print("共预定了\(historyList)")
            }
            else {
                NSKeyedArchiver.archiveRootObject([key], toFile: archiveURL0.path)
                print("第一次保存预定到硬盘成功！！！")
            }
			//send out notification for updating orderlistcenter
            NotificationCenter.default.post(name: .reservedMealsAdded, object: nil)
            
            self.dateLabel.text = "选择日期"
            self.catagoryLabel.text = "选择餐类"
            self.updateReserveButton()
            
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let popUpVC = storyBoard.instantiateViewController(withIdentifier: StoryboardID.orderListVC) as! OrderListVC
            popUpVC.mealListBySections = self.dataSource.mealListBySections
            print("\(self.dataSource.mealListBySections)")
            UIView.animate(withDuration: 0.6) {
                self.present(popUpVC, animated: false, completion: nil)
            }
            
//            self.navigationController?.pushViewController(popUpVC, animated: true)
            
//            self.dataSource = ShoppingCartDataSource(selectedMeals: [Meal]())
//            self.firstTableView.reloadData()
            
        })
        ac.addAction(deleteAction)
        self.present(ac, animated: true, completion: nil)
    }
    
    func cancelMealList() {
        
        let title = "删除已点菜单?"
        let message = "确认删除当前日期内所有菜品么?"
        let ac = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        ac.addAction(cancelAction)
        
        let deleteAction = UIAlertAction(title: "删除", style: .destructive, handler: {
            (action) -> Void in
            
            let meals = StateController.share.getSelectedMeals()
  
            for meal in meals {
                HandleCoreData.updateMealSelectionStatus(identifier: meal.identifier)
            }

            self.dataSource = ShoppingCartDataSource(selectedMeals: [Meal]())

            self.firstTableView.reloadData()
            
            //update shopping cart badge number
            let nav0 = self.navigationController
            let nav0TabBar = nav0?.tabBarItem
            nav0TabBar?.badgeValue = nil

            //remove resveredMeals in disk
            //update reservedMealsHistory in disk
            let key = self.dateLabel.text!+self.catagoryLabel.text!
            let archiveURL = DataStore.objectURLForKey(key: key)
            
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: archiveURL.path) {
                do {
                    try! fileManager.removeItem(atPath: archiveURL.path)
                }
                let key0 = "reservedMealsHistory"
                let archiveURL0 = DataStore.objectURLForKey(key: key0)
                
                if var historyList = NSKeyedUnarchiver.unarchiveObject(withFile: archiveURL0.path) as? [String] {
                    for list in historyList {
                        if list == key {
                            let index = historyList.index(of: list)
                            historyList.remove(at: index!)
                            break
                        }
                    }
                    NSKeyedArchiver.archiveRootObject(historyList, toFile: archiveURL0.path)
                    //send out notification for updating orderlistcenter
                    NotificationCenter.default.post(name: .reservedMealsDeleted, object: nil)
                }
            }
            
            self.dateLabel.text = "选择日期"
            self.catagoryLabel.text = "选择餐类"
            StateController.share.saveReservedMeals(nil)
            self.updateReserveButton()

        })
        ac.addAction(deleteAction)
        self.present(ac, animated: true, completion: nil)
    }
}
extension ShoppingCartVC : DataTransferBackProtocol{
    //MARK: -Actions
    @IBAction func selectMealCatagory(_ sender: UITapGestureRecognizer) {
        
        let storyBoard = UIStoryboard(name: StoryboardID.catagoryPopUpSB, bundle: nil)
        let popUpVC = storyBoard.instantiateInitialViewController()! as! CatagoryPopUpVC
        popUpVC.delegate = self
        popUpVC.catagory = ["早餐","午餐","晚餐"]
        
        self.present(popUpVC, animated: true)
    }
    
    func stringTransferBack(string: String) {
        catagoryLabel.text = string
        
        updateReserveButton()
        
    }

    @IBAction func selectDate(_ sender: UITapGestureRecognizer) {
        
//        let storyBoard = UIStoryboard(name: StoryboardID.datePopUpSB, bundle: nil)
//        let popUpVC = storyBoard.instantiateInitialViewController()! as! DatePopUpVC
//        popUpVC.delegate = self
//
//        self.present(popUpVC, animated: true)
        let storyBoard = UIStoryboard(name: StoryboardID.calenderPopUpSB, bundle: nil)
        let popUpVC = storyBoard.instantiateInitialViewController()! as! CalenderPopUpVC
        popUpVC.delegate = self
        self.navigationController?.pushViewController(popUpVC, animated: true)
    }
    
    func dateTransferBack(date: Date) {
        print("dataTransferBack was running")
        
        let dateString = MainVC.dateConvertString(date: date)
        dateLabel.text = dateString
        
        updateReserveButton()
    }
}

extension ShoppingCartVC : UITextViewDelegate{
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        if navigationItem.leftBarButtonItem?.title == "Edit" {
            firstTableView.setEditing(true, animated: false)
            navigationItem.leftBarButtonItem?.title = "Done"
        }
        else {
            firstTableView.setEditing(false, animated: false)
            navigationItem.leftBarButtonItem?.title = "Edit"
        }
    }
}

extension ShoppingCartVC {
    
    func updateReserveButton() {
        if dateLabel.text == "选择日期" || catagoryLabel.text == "选择餐类" {
            disableButton()
        }
        else {
            //load resvedMeals from disk if existing
            print("Prepare loading reservedMeals from disk")
            let key = self.dateLabel.text!+self.catagoryLabel.text!

            let archiveURL = DataStore.objectURLForKey(key: key)
            if let reserveMeals = NSKeyedUnarchiver.unarchiveObject(withFile: archiveURL.path) as? ReservedMeals {
                print("Loading reservedMeals from disk")
                let mealIdentifers = reserveMeals.mealsIdentifiers
                
                var meals = [Meal]()
                //更新MealListVC到对应状态
                HandleCoreData.clearAllMealSelectionStatus()
                
                for mealID in mealIdentifers! {
                    print("\(mealID)")
                    HandleCoreData.updateMealSelectionStatus(identifier: mealID)
                    
                    let meal = HandleCoreData.queryDataWithIdentifer(mealID)
                    if meal.count > 0 {
                        meals.append(meal.first!)
                    }
                }
                self.dataSource = ShoppingCartDataSource(selectedMeals: meals)
                self.firstTableView.dataSource = self.dataSource
                self.firstTableView.delegate = self.dataSource
                self.dataSource.shoppingCartController = self
                self.firstTableView.reloadData()

                if meals.count != 0 {
                    enableButton()
                }
            }
            else {
                if StateController.share.getSelectedMeals().count != 0 {
                    enableButton()
                }
            }
        }
    }
    
    func disableButton() {
        reserveButton.isEnabled = false
        cancelButton.isEnabled = false
        reserveButton.backgroundColor = UIColor.lightGray
        cancelButton.backgroundColor = UIColor.lightGray
    }
    func enableButton() {
        reserveButton.isEnabled = true
        cancelButton.isEnabled = true
        reserveButton.backgroundColor = UIColor.blue
        cancelButton.backgroundColor = UIColor.blue
    }
    
    func updateReserveButtonWhenSwithingVC() {
        let selectedMeals = StateController.share.getSelectedMeals()
        if dateLabel.text == "选择日期" || catagoryLabel.text == "选择餐类" || selectedMeals.count == 0 {
            disableButton()
        }
        else {
            enableButton()
        }
    }
    
    func saveToLocal() {
        //截屏
        /*参考代码，来源百度
        guard frame.size.height > 0 && frame.size.width > 0 else {

            return nil
        }

        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0)
        layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
 */
        let screenRect = UIScreen.main.bounds

        UIGraphicsBeginImageContextWithOptions(screenRect.size, false, 0) //该方法截屏清晰度高

//        UIGraphicsBeginImageContext(screenRect.size) //该方法截屏清晰度不高
        let ctx:CGContext = UIGraphicsGetCurrentContext()!
        self.view.layer.render(in: ctx)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        let activityController = UIActivityViewController(activityItems: [image as Any], applicationActivities: nil)
        self.present(activityController, animated: true)
//        保存相册
//        UIImageWriteToSavedPhotosAlbum(image!, self, #selector(image(image:didFinishSavingWithError:contextInfo:)), nil)
        
    }
    
    func image(image:UIImage,didFinishSavingWithError error:NSError?,contextInfo:AnyObject) {
        
        if error != nil {
            let title = "保存失败"
            let ac = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            ac.addAction(cancelAction)
        } else {
            let title = "保存成功"
            let ac = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
            let successAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            ac.addAction(successAction)
        }
    }
}

extension ShoppingCartVC {
    
    @IBAction func unwindToShoppingCartVC(sender: UIStoryboardSegue) {
//        判断 shoppingCartVC instance是否已经存在，
//        当dateLabel为nil时，说明instance还未建立，此时viewDidLoad()，viewWillAppear(false)还未运行过，该func调用后，viewDidLoad()，viewWillAppear(false)会运行一次
//        当dateLabel不为nil时，说明instance已经建立，此时viewDidLoad()，viewWillAppear(false)已经运行过，该func调用后，只有viewWillAppear(false)会运行一次
        let sourceViewController = sender.source as? OrderListDetailVC
        let reservedMeals = sourceViewController?.orderListDetail
        
        //如果是Navigation的形式，则释放popViewController
        if let owningNavigationController = sourceViewController?.navigationController{
            owningNavigationController.popViewController(animated: true)
        }
        
        if self.dateLabel == nil {
            print("label is nil")
            StateController.share.saveReservedMeals(reservedMeals)
            
        }
        else {
            StateController.share.saveReservedMeals(reservedMeals)
            viewDidLoad()
//            viewWillAppear(false)
        }
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }
}

