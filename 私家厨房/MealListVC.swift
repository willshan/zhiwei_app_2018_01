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
    let reachability = Reachability()!
    
    var stateController : StateController!
    var dataSource : MealListDataSource!
    private let userName = CKCurrentUserDefaultName
    
    //searchController要在这里设个变量
    var searchController : UISearchController!
    var resultsController = UITableViewController()
    var selectedIndexPath : IndexPath!
//    var mealListOpen = true
    
    deinit {
        print("The instance of MealListVC was deinited!!!")
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name.mealCacheDidChange, object: nil)
        // 关闭网络状态消息监听
        reachability.stopNotifier()
        // 移除网络状态消息通知
        NotificationCenter.default.removeObserver(self, name: Notification.Name.reachabilityChanged, object: reachability)
    }
}

extension MealListVC{
    //MARK: -Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(type(of:self).mealCacheDidChange(_:)),
                                               name: .mealCacheDidChange,
                                               object: nil)
        networkStatusListener()
        
        // Use the edit button item provided by the table view controller.
//        navigationItem.leftBarButtonItem = editButtonItem
//        var organizeButtonItem : UIBarButtonItem {
//            return UIBarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(self.openAndCloseMealList(_:)))
//        }
//
//        navigationItem.leftBarButtonItems = [editButtonItem, organizeButtonItem]
        navigationItem.leftBarButtonItems = [editButtonItem]
        setSearchController()
        
        //        dataSource = MealListDataSource(meals: stateController.meals)
//        dataSource = MealListDataSource(meals: stateController.getAllMeals())
//        dataSource.mealListVC = self
//
//        if stateController.mealOrderList != nil {
//            dataSource.mealOrderList = stateController.mealOrderList
//        }
//
//        firstTableView.dataSource = dataSource
//        firstTableView.delegate = dataSource
//
//        resultsController.tableView.dataSource = dataSource
//        searchController.searchResultsUpdater = dataSource
//        resultsController.tableView.delegate = dataSource
        
    }
    
    //这一步在unwind之后调用
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        print("view will appear in OrderMealVC")
        
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
//extension MealListVC {
//    @objc func openAndCloseMealList(_ sender : UIBarButtonItem) {
//        if mealListOpen == true {
//            mealListOpen = false
//            dataSource.mealListBySections[0].collapsed = true
//            dataSource.mealListBySections[1].collapsed = true
//            dataSource.mealListBySections[2].collapsed = true
//            dataSource.mealListBySections[3].collapsed = true
//        }
//        else {
//            mealListOpen = true
//            dataSource.mealListBySections[0].collapsed = false
//            dataSource.mealListBySections[1].collapsed = false
//            dataSource.mealListBySections[2].collapsed = false
//            dataSource.mealListBySections[3].collapsed = false
//        }
//        self.firstTableView.reloadData()
//    }
//}

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
    func networkStatusListener() {
        // 1、设置网络状态消息监听 2、获得网络Reachability对象
        NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityChanged),name: Notification.Name.reachabilityChanged,object: reachability)
        do{
            // 3、开启网络状态消息监听
            try reachability.startNotifier()
        }catch{
            print("could not start reachability notifier")
        }
    }
    // 主动检测网络状态
    @objc func reachabilityChanged(note: NSNotification) {
        
        let reachability = note.object as! Reachability // 准备获取网络连接信息
        
        if reachability.connection != .none { // 判断网络连接状态
            print("网络连接：可用")
            if reachability.connection == .wifi { // 判断网络连接类型
                print("连接类型：WiFi")
                resaveRecrodFaiedSavingToCloud()
                // strServerInternetAddrss = getHostAddress_WLAN() // 获取主机IP地址 192.168.31.2 小米路由器
                // processClientSocket(strServerInternetAddrss)    // 初始化Socket并连接，还得恢复按钮可用
            } else {
                print("连接类型：移动网络")
                resaveRecrodFaiedSavingToCloud()
                // getHostAddrss_GPRS()  // 通过外网获取主机IP地址，并且初始化Socket并建立连接
            }
        } else {
            print("网络连接：不可用")
            DispatchQueue.main.async { // 不加这句导致界面还没初始化完成就打开警告框，这样不行
                self.alert_noNetwrok() // 警告框，提示没有网络
            }
        }
    }
    
    // 警告框，提示没有连接网络 *********************
    func alert_noNetwrok() -> Void {
        let alert = UIAlertController(title: "系统提示", message: "请打开网络连接", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "确定", style: .default, handler: nil)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
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
    @objc func mealCacheDidChange(_ notification: Notification) {
        // Here we don't want to updateUI which will change the edit status and call dismiss in some cases.
        // Simply reload the table data.
        //
        guard let object = notification.object as? NSDictionary else {
            updateUI()
            return
        }
        
        
        // If the note was deleted, alert the user and go back to the main screen.
        // MainViewController should get the same notificaiton, so should have updated.
        //
        if let recordIDsDeleted = object[NotificationObjectKey.recordIDsDeleted] as? [CKRecordID] {
            for recordId in recordIDsDeleted {
                print(recordId.recordName)
                HandleCoreData.deleteMealWithIdentifier(recordId.recordName)
                updateUI()
            }
        }
        
        if let recordsChanged = object[NotificationObjectKey.sharedRecordChanged] as? [CKRecord] {
            for record in recordsChanged {
                print(record.recordType)
                if record.recordType == ICloudPropertyStore.recordType.meal {
                    let identifier = record["mealIdentifier"] as! String
                    print("\(identifier)")
                    
                    let meals = HandleCoreData.queryDataWithIdentifer(identifier)
                    if meals.count == 0 {
                        let _ = HandleCoreData.insertData(meal: nil, record: record, database: "Shared")
                        
                        HandleCoreData.updateSaveInCloudStatus(identifier: record.recordID.recordName, savingStatus: true)
                    }
                    else {
                        HandleCoreData.updateData(meal: nil, record: record)
                        HandleCoreData.updateSaveInCloudStatus(identifier: record.recordID.recordName, savingStatus: true)
                    }
                    updateUI()
                    
                    // Write meladata to disk
                    // obtain the metadata from the CKRecord
                    
                    let data = NSMutableData()
                    let coder = NSKeyedArchiver.init(forWritingWith: data)
                    coder.requiresSecureCoding = true
                    record.encodeSystemFields(with: coder)
                    
                    coder.finishEncoding()
                    
                    let key = "Record_"+identifier
                    let url = DataStore.objectURLForKey(key: key)
                    NSKeyedArchiver.archiveRootObject(data as Any, toFile: url.path)
                }
                else {
                    continue
                }
            }
        }
        
        // If the note was changed, alert the user and refresh the UI.
        //
        if let recordsChanged = object[NotificationObjectKey.recordsChanged] as? [CKRecord] {
            for record in recordsChanged {
                print(record.recordType)
                if record.recordType == ICloudPropertyStore.recordType.meal {
                    let identifier = record["mealIdentifier"] as! String
                    print("\(identifier)")
                    
                    let meals = HandleCoreData.queryDataWithIdentifer(identifier)
                    if meals.count == 0 {
                        let _ = HandleCoreData.insertData(meal: nil, record: record, database: "Private")
                        
                        HandleCoreData.updateSaveInCloudStatus(identifier: record.recordID.recordName, savingStatus: true)
                    }
                    else {
                        HandleCoreData.updateData(meal: nil, record: record)
                        HandleCoreData.updateSaveInCloudStatus(identifier: record.recordID.recordName, savingStatus: true)
                    }
                    updateUI()
                    
                    // Write meladata to disk
                    // obtain the metadata from the CKRecord
                    
                    let data = NSMutableData()
                    let coder = NSKeyedArchiver.init(forWritingWith: data)
                    coder.requiresSecureCoding = true
                    record.encodeSystemFields(with: coder)
                    
                    coder.finishEncoding()
                    
                    let key = "Record_"+identifier
                    let url = DataStore.objectURLForKey(key: key)
                    NSKeyedArchiver.archiveRootObject(data as Any, toFile: url.path)
                }
                else {
                    continue
                }
            }
        }
    }
    
    func resaveRecrodFaiedSavingToCloud(){
        let meals = HandleCoreData.queryDataWithSaveStatusAndUser(userName)
        
        //Creat custom Zone and Save CKRecord
        if stateController.accountStatus == false {
            let alert = UIAlertController(title: "iCloud账户不可用",
                                          message: "请确认已登录iCloud并开启iCloud Drive",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true)
            
            return
        }
        
        if meals.count == 0 {
            return
        }
        else {
            let zoneIdURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: ICloudPropertyStore.keyForPrivateCustomZoneID)
            let zoneID = NSKeyedUnarchiver.unarchiveObject(withFile: zoneIdURL.path) as? CKRecordZoneID ?? CKRecordZoneID(zoneName: ICloudPropertyStore.zoneName.privateCustomZoneName, ownerName: CKCurrentUserDefaultName)
            
            for meal in meals {
                
                //如果从未保存到icloud过
                if meal.newMeal == true {
                    // Fetch any changes from the server that happened while the app wasn't running
                    let zoneIdURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: ICloudPropertyStore.keyForPrivateCustomZoneID)
                    let zoneID = NSKeyedUnarchiver.unarchiveObject(withFile: zoneIdURL.path) as? CKRecordZoneID ?? CKRecordZoneID(zoneName: ICloudPropertyStore.zoneName.privateCustomZoneName, ownerName: CKCurrentUserDefaultName)
                    
                    //Creat CKRecord
                    let recordID = CKRecordID(recordName: meal.identifier, zoneID: zoneID)
                    let mealRecord = CKRecord(recordType: "Meal", recordID: recordID)
                    
                    mealRecord["cellSelected"] = Int64(0) as CKRecordValue
                    mealRecord["comment"] = meal.comment! as NSString
                    
                    let URL = DataStore.objectURLForKey(key: meal.identifier)
                    let imageAsset = CKAsset(fileURL: URL)
                    mealRecord["image"] = imageAsset
                    
                    mealRecord["mealCreatedAt"] = meal.date
                    //recordID.recordName is a UUID
                    mealRecord["mealIdentifier"] = meal.identifier as NSString
                    mealRecord["mealName"] = meal.mealName as NSString
                    mealRecord["mealType"] = meal.mealType as NSString
                    mealRecord["spicy"] = meal.spicy as CKRecordValue
                    
                    if ZoneLocalCache.share.createdPrivateCustomZone == true {
                        ZoneLocalCache.share.databases[1].cloudKitDB.save(mealRecord, completionHandler: { (record, error) in
                            if error != nil {
                                // Insert error handling
                                print("failed save in icloud")
                                HandleCoreData.updateSaveInCloudStatus(identifier: mealRecord.recordID.recordName, savingStatus: false)
                                return
                            }
                            // Insert successfully saved record code
                            print("successfully save in icloud")
                            
                            // Write meladata to disk
                            // obtain the metadata from the CKRecord
                            let data = NSMutableData()
                            let coder = NSKeyedArchiver.init(forWritingWith: data)
                            coder.requiresSecureCoding = true
                            record?.encodeSystemFields(with: coder)
                            coder.finishEncoding()
                            
                            let key = "Record_"+mealRecord.recordID.recordName
                            let url = DataStore.objectURLForKey(key: key)
                            NSKeyedArchiver.archiveRootObject(data as Any, toFile: url.path)
                            
                            HandleCoreData.changeNewMeal(meal.identifier)
                            HandleCoreData.updateSaveInCloudStatus(identifier: mealRecord.recordID.recordName, savingStatus: true)
                        })
                    }
                    else {
                        ZoneLocalCache.share.creatCustomZone(zoneName: ICloudPropertyStore.zoneName.privateCustomZoneName, database: ZoneLocalCache.share.databases[1]) { (error) in
                            if error == nil {
                                ZoneLocalCache.share.databases[1].cloudKitDB.save(mealRecord, completionHandler: { (record, error) in
                                    if error != nil {
                                        // Insert error handling
                                        print("failed save in icloud")
                                        HandleCoreData.updateSaveInCloudStatus(identifier: mealRecord.recordID.recordName, savingStatus: false)
                                        return
                                    }
                                    // Insert successfully saved record code
                                    print("successfully save in icloud")
                                    
                                    // Write meladata to disk
                                    // obtain the metadata from the CKRecord
                                    let data = NSMutableData()
                                    let coder = NSKeyedArchiver.init(forWritingWith: data)
                                    coder.requiresSecureCoding = true
                                    record?.encodeSystemFields(with: coder)
                                    coder.finishEncoding()
                                    
                                    let key = "Record_"+mealRecord.recordID.recordName
                                    let url = DataStore.objectURLForKey(key: key)
                                    NSKeyedArchiver.archiveRootObject(data as Any, toFile: url.path)
                                    HandleCoreData.updateSaveInCloudStatus(identifier: mealRecord.recordID.recordName, savingStatus: true)
                                })
                            }
                        }
                    }
                }
                //更新后未保存到icloud
                else {
                    let recordID = CKRecordID(recordName: meal.identifier, zoneID: zoneID)
                    print("zone id is \(String(describing: zoneID))")
                    
                    ZoneLocalCache.share.databases[1].cloudKitDB.fetch(withRecordID: recordID, completionHandler: { (record, error) in
                        if error != nil {
                            // Insert error handling
                            print("Can't fetch record from privateDB in icloud")
                        }
                        else {
                            //Update CKRecord
                            record!["cellSelected"] = Int64(0) as CKRecordValue
                            record!["comment"] = meal.comment! as NSString
                            
                            let URL = DataStore.objectURLForKey(key: meal.identifier)
                            let imageAsset = CKAsset(fileURL: URL)
                            record!["image"] = imageAsset
                            
                            record!["mealCreatedAt"] = meal.date
                            //recordID.recordName is a UUID
                            record!["mealIdentifier"] = meal.identifier as NSString
                            record!["mealName"] = meal.mealName as NSString
                            record!["mealType"] = meal.mealType as NSString
                            record!["spicy"] = meal.spicy as CKRecordValue
                            
                            //Save CKRecord
                            ZoneLocalCache.share.databases[1].cloudKitDB.save(record!, completionHandler: { (record, error) in
                                if error != nil {
                                    // Insert error handling
                                    print("failed save in icloud")
                                    return
                                }
                                // Insert successfully saved record code
                                print("successfully save in icloud")
                                
                                // Write meladata to disk
                                // obtain the metadata from the CKRecord
                                let data = NSMutableData()
                                let coder = NSKeyedArchiver.init(forWritingWith: data)
                                coder.requiresSecureCoding = true
                                record?.encodeSystemFields(with: coder)
                                coder.finishEncoding()
                                
                                let key = "Record_"+meal.identifier
                                let url = DataStore.objectURLForKey(key: key)
                                NSKeyedArchiver.archiveRootObject(data as Any, toFile: url.path)
                                
                                HandleCoreData.updateSaveInCloudStatus(identifier: meal.identifier, savingStatus: true)
                                
                            })
                        }
                    })
                }
            }
        }
    }
    
    func saveRecordIniCloud(meal : Meal, uploadImage : UIImage){
        //define
        //Creat custom Zone and Save CKRecord
        if stateController.accountStatus == false {
            let alert = UIAlertController(title: "iCloud账户不可用",
                                          message: "请确认已登录iCloud并开启iCloud Drive",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true)
            
            return
        }
        
        // Fetch any changes from the server that happened while the app wasn't running
        let zoneIdURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: ICloudPropertyStore.keyForPrivateCustomZoneID)
        let zoneID = NSKeyedUnarchiver.unarchiveObject(withFile: zoneIdURL.path) as? CKRecordZoneID ?? CKRecordZoneID(zoneName: ICloudPropertyStore.zoneName.privateCustomZoneName, ownerName: CKCurrentUserDefaultName)
        
        //Creat CKRecord
        let mealRecord = CKRecord(recordType: "Meal", zoneID: zoneID)

        //participant.acceptanceStatus = .accepted
        
        //save image to local
        DataStore().saveImageInDisk(image: uploadImage, forKey: mealRecord.recordID.recordName)
        //update meal identifier in local, use mealRecord.recordID.recordName to replace previous meal.identifer
        HandleCoreData.updateMealIdentifer(identifier: meal.identifier, recordName: mealRecord.recordID.recordName)
        
        mealRecord["cellSelected"] = Int64(0) as CKRecordValue
        mealRecord["comment"] = meal.comment! as NSString
        
        let URL = DataStore.objectURLForKey(key: mealRecord.recordID.recordName)
        let imageAsset = CKAsset(fileURL: URL)
        mealRecord["image"] = imageAsset
        
        mealRecord["mealCreatedAt"] = meal.date
		//recordID.recordName is a UUID
        mealRecord["mealIdentifier"] = mealRecord.recordID.recordName as NSString
        mealRecord["mealName"] = meal.mealName as NSString
        mealRecord["mealType"] = meal.mealType as NSString
        mealRecord["spicy"] = meal.spicy as CKRecordValue
        
        //Dont creat custom Zone and Save CKRecord
        if ZoneLocalCache.share.createdPrivateCustomZone == true {
            ZoneLocalCache.share.databases[1].cloudKitDB.save(mealRecord, completionHandler: { (record, error) in
                if error != nil {
                    // Insert error handling
                    print("failed save in icloud")
                    HandleCoreData.updateSaveInCloudStatus(identifier: mealRecord.recordID.recordName, savingStatus: false)
                    return
                    
                }
                // Insert successfully saved record code
                print("successfully save in icloud")
                
                // Write meladata to disk
                // obtain the metadata from the CKRecord
                let data = NSMutableData()
                let coder = NSKeyedArchiver.init(forWritingWith: data)
                coder.requiresSecureCoding = true
                record?.encodeSystemFields(with: coder)
                coder.finishEncoding()
                
                let key = "Record_"+record!.recordID.recordName
                let url = DataStore.objectURLForKey(key: key)
                NSKeyedArchiver.archiveRootObject(data as Any, toFile: url.path)
                HandleCoreData.updateSaveInCloudStatus(identifier: record!.recordID.recordName, savingStatus: true)
            })
        }
        else {
            //Creat custom Zone and Save CKRecord
            ZoneLocalCache.share.creatCustomZone(zoneName: ICloudPropertyStore.zoneName.privateCustomZoneName, database: ZoneLocalCache.share.databases[1]) { (error) in
                if error == nil {
                    ZoneLocalCache.share.databases[1].cloudKitDB.save(mealRecord, completionHandler: { (record, error) in
                        if error != nil {
                            // Insert error handling
                            print("failed save in icloud")
                            HandleCoreData.updateSaveInCloudStatus(identifier: mealRecord.recordID.recordName, savingStatus: false)
                            return
                        }
                        // Insert successfully saved record code
                        print("successfully save in icloud")
                        
                        // Write meladata to disk
                        // obtain the metadata from the CKRecord
                        let data = NSMutableData()
                        let coder = NSKeyedArchiver.init(forWritingWith: data)
                        coder.requiresSecureCoding = true
                        record?.encodeSystemFields(with: coder)
                        coder.finishEncoding()
                        
                        let key = "Record_"+record!.recordID.recordName
                        let url = DataStore.objectURLForKey(key: key)
                        NSKeyedArchiver.archiveRootObject(data as Any, toFile: url.path)
                        HandleCoreData.updateSaveInCloudStatus(identifier: mealRecord.recordID.recordName, savingStatus: true)
                    })
                }
            }
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
            print("cell tapped")
            guard let viewDetailVC = segue.destination as? MealDetailVC else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            var selectedMeal = Meal()
            print(dataSource.searchedMeals.count)
            if dataSource.searchedMeals.count == 0 {
                selectedMeal = self.dataSource.mealListBySections[selectedIndexPath.section].meals[selectedIndexPath.row]
            }
            else {
                selectedMeal = self.dataSource.searchMealsBySections[selectedIndexPath.section].meals[selectedIndexPath.row]
            }
            
//            print("***************\(selectedMeal)")
            
            viewDetailVC.meal = selectedMeal
            
            viewDetailVC.photoFromOrderMeal = DataStore().getImageForKey(key: selectedMeal.identifier)
            
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
    @IBAction func saveUnwindToMealList(sender: UIStoryboardSegue) {
        let sourceViewController = sender.source as? PersonalSetVC
        navigationItem.title = sourceViewController?.mealListName.text
        
        self.navigationController?.tabBarController?.tabBar.isHidden = false
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
                if meal.mealType != dataSource.mealListBySections[selectedIndexPath.section].meals.first?.mealType {
                    //移出数据
                    dataSource.mealListBySections[selectedIndexPath.section].meals.remove(at: selectedIndexPath.row)
                    //移出表格
                    let indexPath = IndexPath(row: selectedIndexPath.row, section: selectedIndexPath.section)
                    firstTableView.deleteRows(at: [indexPath], with: .automatic)
                    
                    if meal.mealType == "凉菜" {
                        let newIndexPath = IndexPath(row: dataSource.mealListBySections[0].meals.count, section: 0)
                        dataSource.mealListBySections[0].meals.append(meal)
                        firstTableView.insertRows(at: [newIndexPath], with: .automatic)
                    }
                    if meal.mealType == "热菜" {
                        let newIndexPath = IndexPath(row: dataSource.mealListBySections[1].meals.count, section: 1)
                        dataSource.mealListBySections[1].meals.append(meal)
                        firstTableView.insertRows(at: [newIndexPath], with: .automatic)
                    }
                    if meal.mealType == "汤" {
                        let newIndexPath = IndexPath(row: dataSource.mealListBySections[2].meals.count, section: 2)
                        dataSource.mealListBySections[2].meals.append(meal)
                        firstTableView.insertRows(at: [newIndexPath], with: .automatic)
                    }
                    if meal.mealType == "酒水" {
                        let newIndexPath = IndexPath(row: dataSource.mealListBySections[3].meals.count, section: 3)
                        dataSource.mealListBySections[3].meals.append(meal)
                        firstTableView.insertRows(at: [newIndexPath], with: .automatic)
                    }
                }
                    
                else {
                    dataSource.mealListBySections[selectedIndexPath.section].meals[selectedIndexPath.row] = meal
                    firstTableView.reloadRows(at: [selectedIndexPath], with: .none)
                }
                
                //MARK: Update meal to iCloud
                //option 1: use metadata in local
                if meal.newMeal == true {
                    //Save record in icloud
                    self.saveRecordIniCloud(meal: meal, uploadImage: uploadImage!)
                    // Save the meals to stateControler
                    dataSource.updateMeals()
                    stateController?.saveMeal(dataSource.meals!)
                    return
                }
                
                let key = "Record_"+meal.identifier
                let url = DataStore.objectURLForKey(key: key)
                let meladata = NSKeyedUnarchiver.unarchiveObject(withFile: url.path) as? NSMutableData
                let coder = NSKeyedUnarchiver(forReadingWith: meladata! as Data)
                coder.requiresSecureCoding = true
                let record = CKRecord(coder: coder)
                coder.finishDecoding()
                
                //Update CKRecord
                record!["comment"] = meal.comment! as NSString
                if photochanged == true {
                    let URL = DataStore.objectURLForKey(key: meal.identifier)
                    let imageAsset = CKAsset(fileURL: URL)
                    record!["image"] = imageAsset
                }
                record!["mealName"] = meal.mealName as NSString
                record!["mealType"] = meal.mealType as NSString
                record!["spicy"] = meal.spicy as CKRecordValue
                print(meal.database)
                if meal.database == "Private" {
                    //Save CKRecord
                    ZoneLocalCache.share.databases[1].cloudKitDB.save(record!, completionHandler: { (record, error) in
                        if error != nil {
                            // Insert error handling
                            print("failed save in icloud")
                            HandleCoreData.updateSaveInCloudStatus(identifier: meal.identifier, savingStatus: false)
                            return
                        }
                        // Insert successfully saved record code
                        // Write meladata to disk
                        // obtain the metadata from the CKRecord
                        
                        let data = NSMutableData()
                        let coder = NSKeyedArchiver.init(forWritingWith: data)
                        coder.requiresSecureCoding = true
                        record?.encodeSystemFields(with: coder)
                        
                        coder.finishEncoding()
                        
                        let key = "Record_"+meal.identifier
                        let url = DataStore.objectURLForKey(key: key)
                        NSKeyedArchiver.archiveRootObject(data as Any, toFile: url.path)
                        
                        HandleCoreData.updateSaveInCloudStatus(identifier: meal.identifier, savingStatus: true)
                        print("successfully save in icloud")
                    })
                }
                else {
                    //Save CKRecord
                    ZoneLocalCache.share.databases[2].cloudKitDB.save(record!, completionHandler: { (record, error) in
                        if error != nil {
                            // Insert error handling
                            print("failed save in icloud")
                            HandleCoreData.updateSaveInCloudStatus(identifier: meal.identifier, savingStatus: false)
                            return
                        }
                        // Insert successfully saved record code
                        // Write meladata to disk
                        // obtain the metadata from the CKRecord
                        
                        let data = NSMutableData()
                        let coder = NSKeyedArchiver.init(forWritingWith: data)
                        coder.requiresSecureCoding = true
                        record?.encodeSystemFields(with: coder)
                        
                        coder.finishEncoding()
                        
                        let key = "Record_"+meal.identifier
                        let url = DataStore.objectURLForKey(key: key)
                        NSKeyedArchiver.archiveRootObject(data as Any, toFile: url.path)
                        
                        HandleCoreData.updateSaveInCloudStatus(identifier: meal.identifier, savingStatus: true)
                        print("successfully save in icloud")
                    })
                }
                //option 2: Fetch CKRecord from icloud and save
//                let zoneIdURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: ICloudPropertyStore.keyForPrivateCustomZoneID)
//                let zoneID = NSKeyedUnarchiver.unarchiveObject(withFile: zoneIdURL.path) as? CKRecordZoneID ?? CKRecordZoneID(zoneName: ICloudPropertyStore.zoneName.privateCustomZoneName, ownerName: CKCurrentUserDefaultName)

//                print("the zone id of current meal is \(String(describing: zoneID))")
//
//                let recordID = CKRecordID(recordName: meal.identifier, zoneID: zoneID)
//                print("zone id is \(String(describing: zoneID))")
//
//                DatabaseLocalCache.share.sharedDB.fetch(withRecordID: recordID, completionHandler: { (record, error) in
//                    if error != nil {
//                        // Insert error handling
//                        print("Can't fetch record from shareDB in icloud")
//                    }
//                    else {
//                        //Update CKRecord
//                        record!["comment"] = meal.comment! as NSString
//                        if photochanged == true {
//                            let URL = DataStore().objectURLForKey(key: meal.identifier)
//                            let imageAsset = CKAsset(fileURL: URL)
//                            record!["image"] = imageAsset
//                        }
//                        record!["mealName"] = meal.mealName as NSString
//                        record!["mealType"] = meal.mealType as NSString
//                        record!["spicy"] = meal.spicy as CKRecordValue
//
//                        //Save CKRecord
//                        DatabaseLocalCache.share.sharedDB.save(record!, completionHandler: { (record, error) in
//                            if error != nil {
//                                // Insert error handling
//                                print("failed save in icloud")
//                                return
//                            }
//                            // Insert successfully saved record code
//                            print("successfully save in icloud")
//                        })
//                    }
//                })
//
//                DatabaseLocalCache.share.privateDB.fetch(withRecordID: recordID, completionHandler: { (record, error) in
//                    if error != nil {
//                        // Insert error handling
//                        print("Can't fetch record from privateDB in icloud")
//                    }
//                    else {
//                        //Update CKRecord
//                        record!["comment"] = meal.comment! as NSString
//                        if photochanged == true {
//                            let URL = DataStore().objectURLForKey(key: meal.identifier)
//                            let imageAsset = CKAsset(fileURL: URL)
//                            record!["image"] = imageAsset
//                        }
//                        record!["mealName"] = meal.mealName as NSString
//                        record!["mealType"] = meal.mealType as NSString
//                        record!["spicy"] = meal.spicy as CKRecordValue
//
//                        //Save CKRecord
//                        DatabaseLocalCache.share.privateDB.save(record!, completionHandler: { (record, error) in
//                            if error != nil {
//                                // Insert error handling
//                                print("failed save in icloud")
//                                return
//                            }
//                            // Insert successfully saved record code
//                            print("successfully save in icloud")
//                        })
//                    }
//                })
            }
            else {
                //Add a new meal
                if meal.mealType == "凉菜" {
                    let newIndexPath = IndexPath(row: dataSource.mealListBySections[0].meals.count, section: 0)
                    dataSource.mealListBySections[0].meals.append(meal)
                    firstTableView.insertRows(at: [newIndexPath], with: .automatic)
                }
                if meal.mealType == "热菜" {
                    let newIndexPath = IndexPath(row: dataSource.mealListBySections[1].meals.count, section: 1)
                    dataSource.mealListBySections[1].meals.append(meal)
                    firstTableView.insertRows(at: [newIndexPath], with: .automatic)
                }
                if meal.mealType == "汤" {
                    let newIndexPath = IndexPath(row: dataSource.mealListBySections[2].meals.count, section: 2)
                    dataSource.mealListBySections[2].meals.append(meal)
                    firstTableView.insertRows(at: [newIndexPath], with: .automatic)
                }
                if meal.mealType == "酒水" {
                    let newIndexPath = IndexPath(row: dataSource.mealListBySections[3].meals.count, section: 3)
                    dataSource.mealListBySections[3].meals.append(meal)
                    firstTableView.insertRows(at: [newIndexPath], with: .automatic)
                }
                //MARK: Save new meal to iCloud
                //Save record in icloud
                self.saveRecordIniCloud(meal: meal, uploadImage: uploadImage!)
            }
            //添加图片到Disk
            if photochanged == true {
                DataStore().saveImageInDisk(image: uploadImage!, forKey: meal.identifier)
            }
            
            // Save the meals to stateControler
            dataSource.updateMeals()
            stateController?.saveMeal(dataSource.meals!)
        }
    }
}

