//
//  OrderMealTableViewController.swift
//  私家厨房
//
//  Created by Will.Shan on 25/03/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit
import os.log
import CoreData
import CloudKit

//合并后使用该class
class OrderMealController: UITableViewController {
    //MARK: -Properties
    var stateController : StateController!
    var dataSource: OrderMealDataSource!
    
    // Define icloudKit
    // Store these to disk so that they persist across launches
    var createdCustomZone = ICloudPropertyStore.propertyForKey(key: ICloudPropertyStore.keyForCreatedCustomZone) ?? false
    var subscribedToPrivateChanges = ICloudPropertyStore.propertyForKey(key: ICloudPropertyStore.keyForSubscribedToPrivateChanges) ?? false
    var subscribedToSharedChanges = ICloudPropertyStore.propertyForKey(key: ICloudPropertyStore.keyForSubscribedToSharedChanges) ?? false
    
    let privateSubscriptionId = "private-changes"
    let sharedSubscriptionId = "shared-changes"
}

extension OrderMealController{
    //MARK: -Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        //self.loadMealsFromServer()
        //添加聊天管理代理
        EMClient.shared().chatManager.add(self, delegateQueue: nil)
        
        // Use the edit button item provided by the table view controller.
        navigationItem.leftBarButtonItem = editButtonItem
    }
    
    //这一步在unwind之后调用
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        print("view will appear in OrderMealVC")
        dataSource = OrderMealDataSource(meals: stateController.meals)

        dataSource.orderMealController = self
        
        if stateController.mealOrderList != nil {
            dataSource.mealOrderList = stateController.mealOrderList
        }
        tableView.dataSource = dataSource
        //tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        //loadMealsFromServer()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension OrderMealController {
    func saveRecordIniCloud(meal : Meal, uploadImage : UIImage){
        //define
        let myContainer = CKContainer.default()
        let privateDB = myContainer.privateCloudDatabase
        //let sharedDB = myContainer.sharedCloudDatabase
        
        let zoneID = CKRecordZoneID(zoneName: "Meals", ownerName: CKCurrentUserDefaultName)
        
        //Creat CKRecord
        //let mealRecordID = CKRecordID(recordName: meal.identifier)
        //let mealRecord = CKRecord(recordType: "Meal", recordID: mealRecordID)
        let mealRecord = CKRecord(recordType: "Meal", zoneID: zoneID)
        
        //save image to local
        ImageStore().setImage(image: uploadImage, forKey: mealRecord.recordID.recordName)
        //update meal identifier in local
        HandleCoreData.updateMealIdentifer(identifier: meal.identifier, recordName: mealRecord.recordID.recordName)
        
        mealRecord["cellSelected"] = Int64(0) as CKRecordValue
        mealRecord["comment"] = meal.comment! as NSString
        
        let URL = ImageStore().imageURLForKey(key: mealRecord.recordID.recordName)
        let imageAsset = CKAsset(fileURL: URL)
        mealRecord["image"] = imageAsset
        
        mealRecord["mealCreatedAt"] = meal.date
        mealRecord["mealIdentifier"] = mealRecord.recordID.recordName as NSString
        mealRecord["mealName"] = meal.mealName as NSString
        mealRecord["mealType"] = meal.mealType as NSString
        mealRecord["spicy"] = meal.spicy as CKRecordValue
        
        //Creat custom Zone and Save CKRecord
        let createZoneGroup = DispatchGroup()
        if !self.createdCustomZone {
            //start to create custom zone
            createZoneGroup.enter()
            let customZone = CKRecordZone(zoneID: zoneID)
            let createZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: [customZone], recordZoneIDsToDelete: [] )
            
            createZoneOperation.modifyRecordZonesCompletionBlock = { (saved, deleted, error) in
                if (error == nil) {
                    self.createdCustomZone = true
                    ICloudPropertyStore.setiCloudProperty(property: self.createdCustomZone, forKey: ICloudPropertyStore.keyForCreatedCustomZone)
                    
                    privateDB.save(mealRecord, completionHandler: { (record, error) in
                        if error != nil {
                            // Insert error handling
                            print("failed save in icloud")
                            return
                            
                        }
                        // Insert successfully saved record code
                        print("successfully save in icloud")

                    })
                }
                // else custom error handling
                createZoneGroup.leave()
            }
            createZoneOperation.qualityOfService = .userInitiated
            
            privateDB.add(createZoneOperation)
        }
        //Save CKRecord without creating custom zone
        else {
            privateDB.save(mealRecord, completionHandler: { (record, error) in
                if error != nil {
                    // Insert error handling
                    print("failed save in icloud")
                    return
                    
                }
                // Insert successfully saved record code
                print("successfully save in icloud")

            })
        }
    }

    //load data from Parse, no longer used beacuse of using iCloud replacement
    /*
    func loadMealsFromServer() {
        print("func loadMealsFromServer is loaded")
        
        guard let query = MealToServer.query() else {
            return
        }
        
        query.countObjectsInBackground { [unowned self] count, error in
            if Int(count) == self.stateController.meals?.count {
            return
        }
                
        else {
        query.findObjectsInBackground { [unowned self] objects, error in
            guard let objects = objects as? [MealToServer]
                else {
                    self.showErrorView(error)
                    return
            }

            //Clear coredata first
            //print((PFUser.current()?.username)!)
            let userName : String? = UserDefaults.standard.string(forKey: "user_name")

            //clear coreData
            HandleCoreData.clearCoreData(userName!)
            
            //download from server
            for object in objects {
                if object.userName == userName {
                    //print("object的user为\(object.user)")
                    //print("current的user为\(PFUser.current())")
					
					//添加数据到coreData
					let meal = HandleCoreData.insertData(mealToServer: object, meal: nil)
                    print("***the identifier for the meal is \(String(describing: meal.identifier))")
                    
                    self.stateController.addMeal(meal)
                    
                    self.dataSource = OrderMealDataSource(meals: self.stateController.meals)
                    self.tableView.dataSource = self.dataSource
                    self.dataSource.orderMealController = self
                    self.tableView.reloadData()
                    
                    object.photo?.getDataInBackground { [unowned self] data, error in
                            guard let data = data,
                                let image = UIImage(data: data) else {
                                    return
                        }
                        //添加图片到Disk
                        ImageStore().setImage(image: image, forKey: meal.identifier)
                    }
                }
                //print("**3**共找到了的meals数量为\(meals.count)")
            }
            print("**************001")
            print("********该用户有\(String(describing: self.stateController.meals?.count))道菜！！***********")

            self.dataSource = OrderMealDataSource(meals: self.stateController.meals)
            print("**************002")
            
            self.tableView.dataSource = self.dataSource
            print("**************003")
            
            self.dataSource.orderMealController = self
            self.tableView.reloadData()
            print("func loadMealsFromServer is loaded")
            }
        }
        }
    }*/
}


extension OrderMealController {
    //MARK: -Segus
    //Add New Meal and show meal details
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch(segue.identifier ?? "") {
            
        case "AddNewMeal":
            os_log("Adding a new meal.", log: OSLog.default, type: .debug)
            
        case "ShowDetailSegue":
            
            guard let viewDetailVC = segue.destination as? ViewDetailVC else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedMealCell = sender as? OrderMealCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedMealCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedMeal = self.dataSource.mealListBySections[indexPath.section][indexPath.row]
            print("***************\(selectedMeal)")
            
            viewDetailVC.meal = selectedMeal
            
            viewDetailVC.photoFromOrderMeal = ImageStore().imageForKey(key: selectedMeal.identifier)
            //cell.order?.setTitle("加入菜单", for: .normal)
            //viewDetailVC.addToShoppingCartLabel = selectedMealCell.order?.titleLabel?.text
            
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
    @IBAction func saveUnwindToMealList(sender: UIStoryboardSegue) {
        let sourceViewController = sender.source as? PersonalSetViewController
        navigationItem.title = sourceViewController?.mealListName.text
        
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        }
    
    @IBAction func unwindFromOrderCenter(sender: UIStoryboardSegue) {
        return
    }
    
    @IBAction func unwindToMealList(sender: UIStoryboardSegue) {
        print("transfered data to orderMeal")
        if let sourceViewController = sender.source as? DetailMealViewController, let meal = sourceViewController.meal, let photochanged : Bool = sourceViewController.photochanged {
            print("*****DetailMealViewController的meal不为空")
            // Save to Parse server in background
            let uploadImage = sourceViewController.photoFromOrderMeal ?? UIImage(named: "defaultPhoto")
            
            //Determine update meal or add new meal
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                //Update an existing meal
                if meal.mealType != dataSource.mealListBySections[selectedIndexPath.section].first?.mealType {
                    //移出数据
                    dataSource.mealListBySections[selectedIndexPath.section].remove(at: selectedIndexPath.row)
                    //移出表格
                    let indexPath = IndexPath(row: selectedIndexPath.row, section: selectedIndexPath.section)
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                    
                    if meal.mealType == "凉菜" {
                        let newIndexPath = IndexPath(row: dataSource.mealListBySections[0].count, section: 0)
                        dataSource.mealListBySections[0].append(meal)
                        tableView.insertRows(at: [newIndexPath], with: .automatic)
                    }
                    if meal.mealType == "热菜" {
                        let newIndexPath = IndexPath(row: dataSource.mealListBySections[1].count, section: 1)
                        dataSource.mealListBySections[1].append(meal)
                        tableView.insertRows(at: [newIndexPath], with: .automatic)
                    }
                    if meal.mealType == "汤" {
                        let newIndexPath = IndexPath(row: dataSource.mealListBySections[2].count, section: 2)
                        dataSource.mealListBySections[2].append(meal)
                        tableView.insertRows(at: [newIndexPath], with: .automatic)
                    }
                    if meal.mealType == "酒水" {
                        let newIndexPath = IndexPath(row: dataSource.mealListBySections[3].count, section: 3)
                        dataSource.mealListBySections[3].append(meal)
                        tableView.insertRows(at: [newIndexPath], with: .automatic)
                    }
                }
                    
                else {
                    dataSource.mealListBySections[selectedIndexPath.section][selectedIndexPath.row] = meal
                    tableView.reloadRows(at: [selectedIndexPath], with: .none)
                }
                
                //MARK: Save new meal to iCloud
                //save image to local
                if photochanged == true {
                    ImageStore().setImage(image: uploadImage!, forKey: meal.identifier)
                }
                
                //Fetch CKRecord
                let myContainer = CKContainer.default()
                let privateDatebase = myContainer.privateCloudDatabase
                let recordID = CKRecordID.init(recordName: meal.identifier)
                privateDatebase.fetch(withRecordID: recordID, completionHandler: { (record, error) in
                    if error != nil {
                        // Insert error handling
                        print("Can't fetch record from icloud")
                    
                    }
                    else {
                        //Update CKRecord
                        record!["comment"] = meal.comment! as NSString
                        
                        if photochanged ==  true {
                            let URL = ImageStore().imageURLForKey(key: meal.identifier)
                            let imageAsset = CKAsset(fileURL: URL)
                            record!["image"] = imageAsset
                        }

                        record!["mealName"] = meal.mealName as NSString
                        record!["mealType"] = meal.mealType as NSString
                        record!["spicy"] = meal.spicy as CKRecordValue
                        
                        //Save CKRecord
                        privateDatebase.save(record!, completionHandler: { (record, error) in
                            
                            if error != nil {
                                // Insert error handling
                                print("failed save in icloud")
                                return
                                
                            }
                            
                            // Insert successfully saved record code
                            print("successfully save in icloud")
                            
                        })
                        
                        // Insert successfully saved record code
                        print("successfully save in icloud")
                    }
                    
                })
            }
            else {
                //Add a new meal
                if meal.mealType == "凉菜" {
                    let newIndexPath = IndexPath(row: dataSource.mealListBySections[0].count, section: 0)
                    dataSource.mealListBySections[0].append(meal)
                    tableView.insertRows(at: [newIndexPath], with: .automatic)
                }
                if meal.mealType == "热菜" {
                    let newIndexPath = IndexPath(row: dataSource.mealListBySections[1].count, section: 1)
                    dataSource.mealListBySections[1].append(meal)
                    tableView.insertRows(at: [newIndexPath], with: .automatic)
                }
                if meal.mealType == "汤" {
                    let newIndexPath = IndexPath(row: dataSource.mealListBySections[2].count, section: 2)
                    dataSource.mealListBySections[2].append(meal)
                    tableView.insertRows(at: [newIndexPath], with: .automatic)
                }
                if meal.mealType == "酒水" {
                    let newIndexPath = IndexPath(row: dataSource.mealListBySections[3].count, section: 3)
                    dataSource.mealListBySections[3].append(meal)
                    tableView.insertRows(at: [newIndexPath], with: .automatic)
                }
                //MARK: Save new meal to iCloud
                //Save record in icloud
                self.saveRecordIniCloud(meal: meal, uploadImage: uploadImage!)
            }
            
            // Save the meals to stateControler
            dataSource.updateMeals()
            stateController?.saveMeal(dataSource.meals!)
        }
    }
}

//MARK: -监听消息列表
extension OrderMealController : EMChatManagerDelegate{
    func conversationListDidUpdate(_ aConversationList: [Any]!) {
        self.showTabBarBadge()
    }
    
    func messagesDidReceive(_ aMessages: [Any]!) {
        self.showTabBarBadge()
    }
    
    func showTabBarBadge() {
        let conversations = EMClient.shared().chatManager.getAllConversations() as! [EMConversation]
        var unreadMessageCount = 0
        for conv in conversations {
            unreadMessageCount += Int(conv.unreadMessagesCount)
        }
        let nav0 = self.navigationController
        let tabNav = nav0?.tabBarController
        let nav2 = tabNav?.viewControllers?[2]
        
        if unreadMessageCount == 0 {
            nav2?.tabBarItem.badgeValue = nil
        }
        else {
            
            nav2?.tabBarItem.badgeValue = "\(unreadMessageCount)"
        }
    }
}
