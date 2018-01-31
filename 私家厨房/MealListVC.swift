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
    var selectedIndexPath : IndexPath!
}

extension MealListVC{
    //MARK: -Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Use the edit button item provided by the table view controller.
        
        navigationItem.leftBarButtonItem = editButtonItem
        
        setSearchController()
        
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
        DataStore().setImage(image: uploadImage, forKey: mealRecord.recordID.recordName)
        //update meal identifier in local
        HandleCoreData.updateMealIdentifer(identifier: meal.identifier, recordName: mealRecord.recordID.recordName)
        
        mealRecord["cellSelected"] = Int64(0) as CKRecordValue
        mealRecord["comment"] = meal.comment! as NSString
        
        let URL = DataStore().objectURLForKey(key: mealRecord.recordID.recordName)
        let imageAsset = CKAsset(fileURL: URL)
        mealRecord["image"] = imageAsset
        
        mealRecord["mealCreatedAt"] = meal.date
        mealRecord["mealIdentifier"] = mealRecord.recordID.recordName as NSString
        mealRecord["mealName"] = meal.mealName as NSString
        mealRecord["mealType"] = meal.mealType as NSString
        mealRecord["spicy"] = meal.spicy as CKRecordValue
        
        //Creat custom Zone and Save CKRecord
        DatabaseLocalCache.share.creatCustomZone(zoneName: "Meals", database: nil) { (error) in
            if error == nil {
                DatabaseLocalCache.share.privateDB.save(mealRecord, completionHandler: { (record, error) in
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
        
        if DatabaseLocalCache.share.createdCustomZone == true {
            DatabaseLocalCache.share.privateDB.save(mealRecord, completionHandler: { (record, error) in
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
            var selectedMeal = Meal()
            print(dataSource.searchedMeals.count)
            if dataSource.searchedMeals.count == 0 {
                selectedMeal = self.dataSource.mealListBySections[selectedIndexPath.section][selectedIndexPath.row]
            }
            else {
                selectedMeal = self.dataSource.searchMealsBySections[selectedIndexPath.section][selectedIndexPath.row]
            }
            
            print("***************\(selectedMeal)")
            
            viewDetailVC.meal = selectedMeal
            
            viewDetailVC.photoFromOrderMeal = DataStore().imageForKey(key: selectedMeal.identifier)
            
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
                let zoneIdURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: "zoneID_Meals")
                let zoneID = NSKeyedUnarchiver.unarchiveObject(withFile: zoneIdURL.path) as? CKRecordZoneID ?? CKRecordZoneID(zoneName: "Meals", ownerName: CKCurrentUserDefaultName)
//                let zoneID = NSKeyedUnarchiver.unarchiveObject(withFile: zoneIdURL.path) as? CKRecordZoneID
                print("the zone id of current meal is \(String(describing: zoneID))")

                let recordID = CKRecordID(recordName: meal.identifier, zoneID: zoneID)
                print("zone id is \(String(describing: zoneID))")
                DatabaseLocalCache.share.privateDB.fetch(withRecordID: recordID, completionHandler: { (record, error) in
                    if error != nil {
                        // Insert error handling
                        print("Can't fetch record from icloud")
                    }
                    else {
                        //Update CKRecord
                        record!["comment"] = meal.comment! as NSString
                        if photochanged == true {
                            let URL = DataStore().objectURLForKey(key: meal.identifier)
                            let imageAsset = CKAsset(fileURL: URL)
                            record!["image"] = imageAsset
                        }
                        record!["mealName"] = meal.mealName as NSString
                        record!["mealType"] = meal.mealType as NSString
                        record!["spicy"] = meal.spicy as CKRecordValue
                        
                        //Save CKRecord
                        DatabaseLocalCache.share.privateDB.save(record!, completionHandler: { (record, error) in
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
                DataStore().setImage(image: uploadImage!, forKey: meal.identifier)
            }
            
            // Save the meals to stateControler
            dataSource.updateMeals()
            stateController?.saveMeal(dataSource.meals!)
        }
    }
}

