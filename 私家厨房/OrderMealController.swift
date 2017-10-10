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
    let myContainer = CKContainer.default()
    var privateDB : CKDatabase!
    var sharedDB : CKDatabase!
    
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
        //fetch changes from icloud
        //添加聊天管理代理
        EMClient.shared().chatManager.add(self, delegateQueue: nil)
        
        // Use the edit button item provided by the table view controller.
        navigationItem.leftBarButtonItem = editButtonItem
        
        self.privateDB = myContainer.privateCloudDatabase
        self.sharedDB = myContainer.sharedCloudDatabase
        
        if !self.subscribedToPrivateChanges {
            let createSubscriptionOperation = self.createDatabaseSubscriptionOperation(subscriptionId: privateSubscriptionId)
            createSubscriptionOperation.modifySubscriptionsCompletionBlock = { (subscriptions, deletedIds, error) in
                if error == nil {
                    self.subscribedToPrivateChanges = true
                    ICloudPropertyStore.setiCloudProperty(property: self.subscribedToPrivateChanges, forKey: ICloudPropertyStore.keyForSubscribedToPrivateChanges)
                }
                // else custom error handling
            }
            self.privateDB?.add(createSubscriptionOperation)
        }
        
        if !self.subscribedToSharedChanges {
            let createSubscriptionOperation = self.createDatabaseSubscriptionOperation(subscriptionId: sharedSubscriptionId)
            createSubscriptionOperation.modifySubscriptionsCompletionBlock = { (subscriptions, deletedIds, error) in
                
                if error == nil {
                    self.subscribedToSharedChanges = true
                    ICloudPropertyStore.setiCloudProperty(property: self.subscribedToSharedChanges, forKey: ICloudPropertyStore.keyForSubscribedToSharedChanges)
                }
                // else custom error handling
            }
            self.sharedDB?.add(createSubscriptionOperation)
        }
        
        let createZoneGroup = DispatchGroup()
        createZoneGroup.notify(queue: DispatchQueue.global()) {
            if self.createdCustomZone {
                self.fetchChanges(in: .private) {}
                self.fetchChanges(in: .shared) {}
            }
        }
        
        self.fetchChanges(in: .private) {}
        self.fetchChanges(in: .shared) {}
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
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension OrderMealController {
    func createDatabaseSubscriptionOperation(subscriptionId: String) -> CKModifySubscriptionsOperation {
        let subscription = CKDatabaseSubscription.init(subscriptionID: subscriptionId)
        let notificationInfo = CKNotificationInfo()
        
        // send a silent notification
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
        operation.qualityOfService = .utility
    
        return operation
    }
    
    func fetchChanges(in databaseScope: CKDatabaseScope, completion: @escaping () -> Void) {
        switch databaseScope {
        case .private:
            fetchDatabaseChanges(database: self.privateDB, databaseTokenKey: "private", completion: completion)
            
        case .shared:
            fetchDatabaseChanges(database: self.sharedDB, databaseTokenKey: "shared", completion: completion)
            
        case .public:
            fatalError()
        }
    }
    //MARK: Fetch the database changes:
    func fetchDatabaseChanges(database: CKDatabase, databaseTokenKey: String, completion: @escaping () -> Void) {
        print("fetch data begin")
        var changedZoneIDs: [CKRecordZoneID] = []
        
        let tokenURL = ICloudPropertyStore.iCloudProtpertyForKey(key: databaseTokenKey)
        //Be noted: this changeToken is database change token, not zone change token.
        let changeToken = NSKeyedUnarchiver.unarchiveObject(withFile: tokenURL.path) as? CKServerChangeToken // Read change token from disk
        
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: changeToken)
        print("database change token is \(String(describing: changeToken))")
        operation.fetchAllChanges = true
        operation.recordZoneWithIDChangedBlock = { (zoneID) in
            changedZoneIDs.append(zoneID)
            //save zone id to disk
            if zoneID.zoneName == "Meals" && self.createdCustomZone == false {
                let zoneIdURL = ICloudPropertyStore.iCloudProtpertyForKey(key: "zoneID_Meals")
                NSKeyedArchiver.archiveRootObject(zoneID, toFile: zoneIdURL.path)
                self.createdCustomZone = true
                ICloudPropertyStore.setiCloudProperty(property: self.createdCustomZone, forKey: ICloudPropertyStore.keyForCreatedCustomZone)
            }
            print("zoneID to be changed is \(zoneID)")
        }
        operation.recordZoneWithIDWasDeletedBlock = { (zoneID) in
            // Write this zone deletion to memory
            
        }
        operation.changeTokenUpdatedBlock = { (token) in
            // Flush zone deletions for this database to disk
            // Write this new database change token to memory
            NSKeyedArchiver.archiveRootObject(token, toFile: tokenURL.path)
            print("After update, database change token is \(token)")
        }
        operation.fetchDatabaseChangesCompletionBlock = { (token, moreComing, error) in
            if let error = error {
                print("Error during fetch shared database changes operation", error)
                completion()
                return
            }
            // Flush zone deletions for this database to disk
            // Write this new database change token to memory
            NSKeyedArchiver.archiveRootObject(token, toFile: tokenURL.path)
            print("Completed update, database change token is \(String(describing: token))")
            
            self.fetchZoneChanges(database: database, databaseTokenKey: databaseTokenKey, zoneIDs: changedZoneIDs) {
                // Flush in-memory database change token to disk
                completion()
            }
        }
        operation.qualityOfService = .userInitiated
        database.add(operation)
    }
    
    //MARK: Fetch the zone changes:
    func fetchZoneChanges(database: CKDatabase, databaseTokenKey: String, zoneIDs: [CKRecordZoneID], completion: @escaping () -> Void) {
        // Look up the previous change token for each zone
        var optionsByRecordZoneID = [CKRecordZoneID: CKFetchRecordZoneChangesOptions]()

        for zoneID in zoneIDs {
            let key = "zone_" + zoneID.zoneName
            let tokenURL = ICloudPropertyStore.iCloudProtpertyForKey(key: key)
            print("the zoneID change token key is \(key)")
            let changeToken = NSKeyedUnarchiver.unarchiveObject(withFile: tokenURL.path) as? CKServerChangeToken
            let options = CKFetchRecordZoneChangesOptions()
            options.previousServerChangeToken = changeToken // Read change token from disk
                optionsByRecordZoneID[zoneID] = options
        }
        
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: zoneIDs, optionsByRecordZoneID: optionsByRecordZoneID)
        operation.recordChangedBlock = { (record) in
            print("Record changed:", record)
            // Write this record change to memory
            let identifier = record["mealIdentifier"] as! String
            let meals = HandleCoreData.queryDataWithIdentifer(identifier)
            if meals.count == 0 {
                let _ = HandleCoreData.insertData(meal: nil, record: record)
            }
            else {
                HandleCoreData.updateData(meal: nil, record: record)
            }
            let updatedMeals = HandleCoreData.queryData(CKCurrentUserDefaultName)
            self.stateController.saveMeal(updatedMeals)
        }
 
        operation.recordWithIDWasDeletedBlock = { (recordId) in
            print("Record deleted:", recordId)
            // Write this record deletion to memory
            HandleCoreData.deleteData(recordId.0.recordName)
        }

        operation.recordZoneChangeTokensUpdatedBlock = { (zoneId, token, data) in
            // Flush record changes and deletions for this zone to disk
            // Write this new zone change token to disk
            //Be noted: this changeToken is zone change token, not database change token
            let key = "zone_" + zoneId.zoneName
            let tokenURL = ICloudPropertyStore.iCloudProtpertyForKey(key: key)
            NSKeyedArchiver.archiveRootObject(token, toFile: tokenURL.path)
            print("After update, zone change token is \(String(describing: token))")
        }

        operation.recordZoneFetchCompletionBlock = { (zoneId, changeToken, _, _, error) in
            
            if let error = error {
                print("Error fetching zone changes for \(databaseTokenKey) database:", error)
                return
            }
            // Flush record changes and deletions for this zone to disk
            
            // Write this new zone change token to disk
            let key = "zone_" + zoneId.zoneName
            let tokenURL = ICloudPropertyStore.iCloudProtpertyForKey(key: key)
            NSKeyedArchiver.archiveRootObject(changeToken, toFile: tokenURL.path)
            print("Compelte update, zone change token is \(String(describing: changeToken))")
        }

        operation.fetchRecordZoneChangesCompletionBlock = { (error) in
            if let error = error {
                print("Error fetching zone changes for \(databaseTokenKey) database:", error)
            }
            completion()
        }
        database.add(operation)
    }
    
    func saveRecordIniCloud(meal : Meal, uploadImage : UIImage){
        //define
        // Fetch any changes from the server that happened while the app wasn't running
        let zoneIdURL = ICloudPropertyStore.iCloudProtpertyForKey(key: "zoneID_Meals")
        let zoneID = NSKeyedUnarchiver.unarchiveObject(withFile: zoneIdURL.path) as? CKRecordZoneID ?? CKRecordZoneID(zoneName: "Meals", ownerName: CKCurrentUserDefaultName)
        
        //let zoneID = CKRecordZoneID(zoneName: "Meals", ownerName: CKCurrentUserDefaultName)
        print("zone id is \(zoneID)")
        
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
                    let zoneIdURL = ICloudPropertyStore.iCloudProtpertyForKey(key: "zoneID_Meals")
                    NSKeyedArchiver.archiveRootObject(zoneID, toFile: zoneIdURL.path)
                    
                    self.privateDB.save(mealRecord, completionHandler: { (record, error) in
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
        if let sourceViewController = sender.source as? DetailMealViewController, let meal = sourceViewController.meal{
            print("*****DetailMealViewController的meal不为空")
            // Save to Parse server in background
            let photochanged = sourceViewController.photochanged
            print("the photo changed is \(photochanged)")
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
                
                //MARK: Update meal to iCloud
                //Fetch CKRecord
                let myContainer = CKContainer.default()
                let privateDatebase = myContainer.privateCloudDatabase
                
                let zoneIdURL = ICloudPropertyStore.iCloudProtpertyForKey(key: "zoneID_Meals")
                let zoneID = NSKeyedUnarchiver.unarchiveObject(withFile: zoneIdURL.path) as? CKRecordZoneID
                print("the zone id of current meal is \(zoneID)")
                
                let recordID = CKRecordID(recordName: meal.identifier, zoneID: zoneID!)
                print("zone id is \(String(describing: zoneID))")
                privateDatebase.fetch(withRecordID: recordID, completionHandler: { (record, error) in
                    if error != nil {
                        // Insert error handling
                        print("Can't fetch record from icloud")
                    }
                    else {
                        //Update CKRecord
                        record!["comment"] = meal.comment! as NSString
                        if photochanged == true {
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
            //添加图片到Disk
            if photochanged == true {
                ImageStore().setImage(image: uploadImage!, forKey: meal.identifier)
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
