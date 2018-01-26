//
//  ViewController.swift
//  私家厨房
//
//  Created by Will.Shan on 15/01/2018.
//  Copyright © 2018 待定. All rights reserved.
//

import UIKit
import os.log
import CoreData
import CloudKit

//tableVC is easy for serachbar
class MealListVC: UIViewController {
    //MARK: -Properties
    
    @IBOutlet weak var firstTableView: UITableView!
    
    var stateController : StateController!
    var dataSource : MealListDataSource!
    
    //searchController要在这里设个变量
    var searchController : UISearchController!
    var resultsController = UITableViewController()
    
    // Define icloudKit
    let container = CKContainer.default()
    var privateDB : CKDatabase!
    var sharedDB : CKDatabase!
    var selectedIndexPath : IndexPath!
    
    // Store these to disk so that they persist across launches
    var createdCustomZone = ICloudPropertyStore.getICloudPropertyForKey(key: ICloudPropertyStore.keyForCreatedCustomZone) ?? false
    var subscribedToPrivateChanges = ICloudPropertyStore.getICloudPropertyForKey(key: ICloudPropertyStore.keyForSubscribedToPrivateChanges) ?? false
    var subscribedToSharedChanges = ICloudPropertyStore.getICloudPropertyForKey(key: ICloudPropertyStore.keyForSubscribedToSharedChanges) ?? false
    
    let privateSubscriptionId = "private-changes"
    let sharedSubscriptionId = "shared-changes"
    
    let zoneIdURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: "zoneID_Meals")
    let zoneChangeTokenURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: "zone_Meals")
}

extension MealListVC{
    //MARK: -Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Use the edit button item provided by the table view controller.
        
        navigationItem.leftBarButtonItem = editButtonItem
        
        setSearchController()
        
        self.privateDB = container.privateCloudDatabase
        self.sharedDB = container.sharedCloudDatabase
        
        //creat custon zone
        let createZoneGroup = DispatchGroup()
        if !self.createdCustomZone {
            //start to create custom zone
            createZoneGroup.enter()
            
            let zoneID = NSKeyedUnarchiver.unarchiveObject(withFile: zoneIdURL.path) as? CKRecordZoneID ?? CKRecordZoneID(zoneName: "Meals", ownerName: CKCurrentUserDefaultName)
            
            let customZone = CKRecordZone(zoneID: zoneID)
            let createZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: [customZone], recordZoneIDsToDelete: [] )
            
            createZoneOperation.modifyRecordZonesCompletionBlock = { (saved, deleted, error) in
                if (error == nil) {
                    self.createdCustomZone = true
                    ICloudPropertyStore.setICloudPropertyForKey(property: self.createdCustomZone, forKey: ICloudPropertyStore.keyForCreatedCustomZone)
                }
                // else custom error handling
                createZoneGroup.leave()
            }
            createZoneOperation.qualityOfService = .userInitiated
            privateDB.add(createZoneOperation)
        }
        
        if !self.subscribedToPrivateChanges {
            let createSubscriptionOperation = self.createDatabaseSubscriptionOperation(subscriptionId: privateSubscriptionId)
            createSubscriptionOperation.modifySubscriptionsCompletionBlock = { (subscriptions, deletedIds, error) in
                if error == nil {
                    self.subscribedToPrivateChanges = true
                    ICloudPropertyStore.setICloudPropertyForKey(property: self.subscribedToPrivateChanges, forKey: ICloudPropertyStore.keyForSubscribedToPrivateChanges)
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
                    ICloudPropertyStore.setICloudPropertyForKey(property: self.subscribedToSharedChanges, forKey: ICloudPropertyStore.keyForSubscribedToSharedChanges)
                }
                // else custom error handling
            }
            self.sharedDB?.add(createSubscriptionOperation)
        }
        
        // Fetch any changes from the server that happened while the app wasn't running
        createZoneGroup.notify(queue: DispatchQueue.global()) {
            if self.createdCustomZone {
                self.fetchChanges(in: .private) {}
                self.fetchChanges(in: .shared) {}
            }
        }
        
        //fetch changes when start
        self.fetchChanges(in: .private) {}
        self.fetchChanges(in: .shared) {}
        
    }
    
    //这一步在unwind之后调用
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        print("view will appear in OrderMealVC")
        
        //        dataSource = MealListDataSource(meals: stateController.meals)
        dataSource = MealListDataSource(meals: stateController.getAllMeals())
        dataSource.mealListVC = self
        
        if stateController.mealOrderList != nil {
            dataSource.mealOrderList = stateController.mealOrderList
        }
        
        firstTableView.dataSource = dataSource
        firstTableView.delegate = dataSource
        
        resultsController.tableView.dataSource = dataSource
        searchController.searchResultsUpdater = dataSource
        resultsController.tableView.delegate = dataSource
        
        firstTableView.reloadData()
    }
}
extension MealListVC : UISearchControllerDelegate, UISearchBarDelegate {
    
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
    
    func setSearchController() {
        if #available(iOS 11.0, *) {
            print("setting searchController")
            navigationController?.navigationBar.prefersLargeTitles = true
            navigationItem.largeTitleDisplayMode = .never
            
            let nib = UINib(nibName: "MealCell", bundle: nil)
            firstTableView.register(nib, forCellReuseIdentifier: "MealCell")
            resultsController.tableView.register(nib, forCellReuseIdentifier: "MealCell")
            
            self.searchController = UISearchController(searchResultsController: resultsController)
            
            resultsController.tableView.rowHeight = 90
            
            //searchController.delegate = self
            //searchController.searchBar.delegate = self
            searchController.hidesNavigationBarDuringPresentation = true
            searchController.dimsBackgroundDuringPresentation = true
            
            self.navigationItem.searchController = searchController
            self.navigationItem.hidesSearchBarWhenScrolling = true
            
            //this step make searchbar visable in resultsController
            self.definesPresentationContext = true
            
        } else {
            // Fallback on earlier versions

            let nib = UINib(nibName: "MealCell", bundle: nil)
            firstTableView.register(nib, forCellReuseIdentifier: "MealCell")
            resultsController.tableView.register(nib, forCellReuseIdentifier: "MealCell")
            
            self.searchController = UISearchController(searchResultsController: resultsController)
            
            resultsController.tableView.rowHeight = 90
            
            searchController.delegate = self
            searchController.searchBar.delegate = self
            searchController.hidesNavigationBarDuringPresentation = true
            searchController.dimsBackgroundDuringPresentation = true
            
            self.firstTableView.tableHeaderView = searchController.searchBar
            
            //this step make searchbar visable in resultsController
            self.definesPresentationContext = true
        }
    }
}

extension MealListVC {
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
        print("++++++++fetch data begin")
        var changedZoneIDs: [CKRecordZoneID] = []
        
        let tokenURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: databaseTokenKey)
        //Be noted: this changeToken is database change token, not zone change token.
        let changeToken = NSKeyedUnarchiver.unarchiveObject(withFile: tokenURL.path) as? CKServerChangeToken // Read change token from disk
        
        var changeTokenInMemory = changeToken
        
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: changeToken)
        print("++++++++database change token is \(String(describing: changeToken))")
        
//        operation.fetchAllChanges = true
        
        operation.recordZoneWithIDChangedBlock = { (zoneID) in
            changedZoneIDs.append(zoneID)
//            save zone id to disk
            print("+++++++create custom zone is \(self.createdCustomZone)")
            if zoneID.zoneName == "Meals" {
                let zoneIdURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: "zoneID_Meals")
                NSKeyedArchiver.archiveRootObject(zoneID, toFile: zoneIdURL.path)
                
                print("+++++++zoneID to be saved is \(zoneID)")
            }
        }
        
        operation.recordZoneWithIDWasDeletedBlock = { (zoneID) in
            // Write this zone deletion to memory
            
        }
        
        operation.changeTokenUpdatedBlock = { (token) in
            // Flush zone deletions for this database to disk
            
            NSKeyedArchiver.archiveRootObject(token, toFile: tokenURL.path)
            print("After update, database change token is \(token)")
            // Write this new database change token to memory
            changeTokenInMemory = token
        }
        
        operation.fetchDatabaseChangesCompletionBlock = { (token, moreComing, error) in
            if let error = error {
                print("Error during fetch shared database changes operation", error)
                completion()
                return
            }
            // Flush zone deletions for this database to disk
            NSKeyedArchiver.archiveRootObject(token as Any, toFile: tokenURL.path)
            print("Completed update, database change token is \(String(describing: token))")
            // Write this new database change token to memory
            changeTokenInMemory = token

            self.fetchZoneChanges(database: database, databaseTokenKey: databaseTokenKey, zoneIDs: changedZoneIDs) {
                // Flush in-memory database change token to disk
                NSKeyedArchiver.archiveRootObject(changeTokenInMemory as Any, toFile: tokenURL.path)
                completion()
            }
        }
        operation.qualityOfService = .userInitiated
        database.add(operation)
    }
    
    //MARK: Fetch the zone changes:
    func fetchZoneChanges(database: CKDatabase, databaseTokenKey: String, zoneIDs: [CKRecordZoneID], completion: @escaping () -> Void) {
        // Look up the previous change token for each zone
        print("++++++++fetch zone begin")
        var optionsByRecordZoneID = [CKRecordZoneID: CKFetchRecordZoneChangesOptions]()
        
        for zoneID in zoneIDs {
            print("+++++++the zoneID is \(zoneID)")
            let key = "zone_" + zoneID.zoneName
            let tokenURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: key)
            print("++++++++the zoneID change token key is \(key)")
            let changeToken = NSKeyedUnarchiver.unarchiveObject(withFile: tokenURL.path) as? CKServerChangeToken
            let options = CKFetchRecordZoneChangesOptions()
            options.previousServerChangeToken = changeToken // Read change token from disk
            optionsByRecordZoneID[zoneID] = options
        }
        
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: zoneIDs, optionsByRecordZoneID: optionsByRecordZoneID)
        
        //        open var recordChangedBlock: ((CKRecord) -> Swift.Void)?
        operation.recordChangedBlock = { (record) in
            print("++++++++Record changed: \(record["mealName"] as! String)")
            
            // Write this record change to memory
            let identifier = record["mealIdentifier"] as! String
            let meals = HandleCoreData.queryDataWithIdentifer(identifier)
            if meals.count == 0 {
                let _ = HandleCoreData.insertData(meal: nil, record: record)
                
                //update UI
                DispatchQueue.main.async {
                self.updateUI()
                }
            }
            else {
                HandleCoreData.updateData(meal: nil, record: record)
                
                //update UI
                DispatchQueue.main.async {
                self.updateUI()
                }

            }
            let updatedMeals = HandleCoreData.queryDataWithUserName(CKCurrentUserDefaultName)
            self.stateController.saveMeal(updatedMeals)
        }
        
        //    open var recordWithIDWasDeletedBlock: ((CKRecordID, String) -> Swift.Void)?
        operation.recordWithIDWasDeletedBlock = { (recordId, string) in
            print("++++++++Record deleted:", string)
            // Write this record deletion to memory
            //print("#1 stateController's meals count is \(self.stateController.meals?.count)")
            HandleCoreData.deleteMealWithIdentifier(recordId.recordName)
            //update UI
            DispatchQueue.main.async {
                self.updateUI()
            }
            
            let updatedMeals = HandleCoreData.queryDataWithUserName(CKCurrentUserDefaultName)
            self.stateController.saveMeal(updatedMeals)
            //print("#2 stateController's meals count is \(self.stateController.meals?.count)")
        }
        
        operation.recordZoneChangeTokensUpdatedBlock = { (zoneId, token, data) in
            // Flush record changes and deletions for this zone to disk
            // Write this new zone change token to disk
            //Be noted: this changeToken is zone change token, not database change token
            let key = "zone_" + zoneId.zoneName
            let tokenURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: key)
            NSKeyedArchiver.archiveRootObject(token as Any, toFile: tokenURL.path)
            //print("After update, zone change token is \(String(describing: token))")
        }
        
        operation.recordZoneFetchCompletionBlock = { (zoneId, changeToken, _, _, error) in
            if let error = error {
                print("++++++++1-Error fetching zone changes for \(databaseTokenKey) database:", error)
                return
            }
            // Flush record changes and deletions for this zone to disk
            
            // Write this new zone change token to disk
            let key = "zone_" + zoneId.zoneName
            let tokenURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: key)
            NSKeyedArchiver.archiveRootObject(changeToken as Any, toFile: tokenURL.path)
            print("++++++++Compelte update, zone change token is \(String(describing: changeToken))")
        }
        
        operation.fetchRecordZoneChangesCompletionBlock = { (error) in
            if let error = error {
                print("++++++++2-Error fetching zone changes for \(databaseTokenKey) database:", error)
            }
            else {
                print("++++++++Successfully fetching zone changes for \(databaseTokenKey) database:")
            }
            completion()
        }
        database.add(operation)
    }
    
    //update UI
    func updateUI() {
        self.dataSource = MealListDataSource(meals: self.stateController.getAllMeals())
        self.dataSource.mealListVC = self
        
        if self.stateController.mealOrderList != nil {
            self.dataSource.mealOrderList = self.stateController.mealOrderList
        }
        
        self.firstTableView.dataSource = self.dataSource
        self.firstTableView.delegate = self.dataSource
        
        self.resultsController.tableView.dataSource = self.dataSource
        self.searchController.searchResultsUpdater = self.dataSource
        self.resultsController.tableView.delegate = self.dataSource
        
        self.firstTableView.reloadData()
    }
    
    func saveRecordIniCloud(meal : Meal, uploadImage : UIImage){
        //define
        // Fetch any changes from the server that happened while the app wasn't running
        let zoneIdURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: "zoneID_Meals")
        let zoneID = NSKeyedUnarchiver.unarchiveObject(withFile: zoneIdURL.path) as? CKRecordZoneID ?? CKRecordZoneID(zoneName: "Meals", ownerName: CKCurrentUserDefaultName)
        
        //Creat CKRecord
        let mealRecord = CKRecord(recordType: "Meal", zoneID: zoneID)
        
        //participant.acceptanceStatus = .accepted
        
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
                    ICloudPropertyStore.setICloudPropertyForKey(property: self.createdCustomZone, forKey: ICloudPropertyStore.keyForCreatedCustomZone)
                    let zoneIdURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: "zoneID_Meals")
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

extension MealListVC {
    //MARK: -Segus
    func showMealDetail() {
        self.performSegue(withIdentifier: SegueID.showMealDetail, sender: nil)
    }
    
    //Add New Meal and show meal details
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case SegueID.addNewMeal:
            os_log("Adding a new meal.", log: OSLog.default, type: .debug)
            
        case SegueID.showMealDetail:
            guard let viewDetailVC = segue.destination as? MealDetailVC else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            //            guard let selectedMealCell = sender as? MealCell else {
            //                fatalError("Unexpected sender: \(String(describing: sender))")
            //            }
            //
            //            guard let indexPath = self.tableView.indexPath(for: selectedMealCell) else {
            //                fatalError("The selected cell is not being displayed by the table")
            //            }
            
            var selectedMeal = Meal()
            print(dataSource.searchedMeals.count)
            if dataSource.searchedMeals.count == 0 {
                selectedMeal = self.dataSource.mealListBySections[selectedIndexPath.section][selectedIndexPath.row]
            }
            else {
                selectedMeal = self.dataSource.searchMealsBySections[selectedIndexPath.section][selectedIndexPath.row]
            }
            //            let selectedMeal = self.dataSource.mealListBySections[selectedIndexPath.section][selectedIndexPath.row]
            
            print("***************\(selectedMeal)")
            
            viewDetailVC.meal = selectedMeal
            
            viewDetailVC.photoFromOrderMeal = ImageStore().imageForKey(key: selectedMeal.identifier)
            
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
    @IBAction func saveUnwindToMealList(sender: UIStoryboardSegue) {
        let sourceViewController = sender.source as? PersonalSetVC
        navigationItem.title = sourceViewController?.mealListName.text
        
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }
    
    @IBAction func unwindFromOrderCenter(sender: UIStoryboardSegue) {
        return
    }
    
    @IBAction func unwindToMealList(sender: UIStoryboardSegue) {
        print("transfered data to orderMeal")
        if let sourceViewController = sender.source as? EditMealVC, let meal = sourceViewController.meal{
            print("*****DetailMealViewController的meal不为空")
            // Save to Parse server in background
            let photochanged = sourceViewController.photochanged
            print("the photo changed is \(photochanged)")
            let uploadImage = sourceViewController.photoFromOrderMeal ?? UIImage(named: AssetNames.defaultPhoto)
            
            //Determine update meal or add new meal
            if let selectedIndexPath = firstTableView.indexPathForSelectedRow {
                //Update an existing meal
                if meal.mealType != dataSource.mealListBySections[selectedIndexPath.section].first?.mealType {
                    //移出数据
                    dataSource.mealListBySections[selectedIndexPath.section].remove(at: selectedIndexPath.row)
                    //移出表格
                    let indexPath = IndexPath(row: selectedIndexPath.row, section: selectedIndexPath.section)
                    firstTableView.deleteRows(at: [indexPath], with: .automatic)
                    
                    if meal.mealType == "凉菜" {
                        let newIndexPath = IndexPath(row: dataSource.mealListBySections[0].count, section: 0)
                        dataSource.mealListBySections[0].append(meal)
                        firstTableView.insertRows(at: [newIndexPath], with: .automatic)
                    }
                    if meal.mealType == "热菜" {
                        let newIndexPath = IndexPath(row: dataSource.mealListBySections[1].count, section: 1)
                        dataSource.mealListBySections[1].append(meal)
                        firstTableView.insertRows(at: [newIndexPath], with: .automatic)
                    }
                    if meal.mealType == "汤" {
                        let newIndexPath = IndexPath(row: dataSource.mealListBySections[2].count, section: 2)
                        dataSource.mealListBySections[2].append(meal)
                        firstTableView.insertRows(at: [newIndexPath], with: .automatic)
                    }
                    if meal.mealType == "酒水" {
                        let newIndexPath = IndexPath(row: dataSource.mealListBySections[3].count, section: 3)
                        dataSource.mealListBySections[3].append(meal)
                        firstTableView.insertRows(at: [newIndexPath], with: .automatic)
                    }
                }
                    
                else {
                    dataSource.mealListBySections[selectedIndexPath.section][selectedIndexPath.row] = meal
                    firstTableView.reloadRows(at: [selectedIndexPath], with: .none)
                }
                
                //MARK: Update meal to iCloud
                //Fetch CKRecord
                let myContainer = CKContainer.default()
                let privateDatebase = myContainer.privateCloudDatabase
                
                let zoneIdURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: "zoneID_Meals")
                let zoneID = NSKeyedUnarchiver.unarchiveObject(withFile: zoneIdURL.path) as? CKRecordZoneID ?? CKRecordZoneID(zoneName: "Meals", ownerName: CKCurrentUserDefaultName)
//                let zoneID = NSKeyedUnarchiver.unarchiveObject(withFile: zoneIdURL.path) as? CKRecordZoneID
                print("the zone id of current meal is \(String(describing: zoneID))")

                let recordID = CKRecordID(recordName: meal.identifier, zoneID: zoneID)
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
                    firstTableView.insertRows(at: [newIndexPath], with: .automatic)
                }
                if meal.mealType == "热菜" {
                    let newIndexPath = IndexPath(row: dataSource.mealListBySections[1].count, section: 1)
                    dataSource.mealListBySections[1].append(meal)
                    firstTableView.insertRows(at: [newIndexPath], with: .automatic)
                }
                if meal.mealType == "汤" {
                    let newIndexPath = IndexPath(row: dataSource.mealListBySections[2].count, section: 2)
                    dataSource.mealListBySections[2].append(meal)
                    firstTableView.insertRows(at: [newIndexPath], with: .automatic)
                }
                if meal.mealType == "酒水" {
                    let newIndexPath = IndexPath(row: dataSource.mealListBySections[3].count, section: 3)
                    dataSource.mealListBySections[3].append(meal)
                    firstTableView.insertRows(at: [newIndexPath], with: .automatic)
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

