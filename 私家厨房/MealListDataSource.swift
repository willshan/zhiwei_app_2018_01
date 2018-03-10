//
//  OrderMealDataSource.swift
//  私家厨房
//
//  Created by Will.Shan on 26/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

class MealListDataSource : NSObject {
    //MARK: -Properties
    //meals是实际tableview中用到的数据
    var meals : [Meal]?
    var mealListBySections : [[Meal]]
    var mealListVC : MealListVC!
    var searchedMeals = [Meal]()
    var searchMealsBySections : [[Meal]]
    var orderedMealIdentifers = [String]()
    
    //OrderedMeal是一个struct，用来记录mealName和mealCount
    var mealOrderList = [IndexPath : OrderedMeal]()
 
    init(meals: [Meal]?) {
        self.meals = meals
        
        self.mealListBySections = [[Meal]]()
        self.searchMealsBySections = [[Meal]]()
        super.init()
        
        if self.meals != nil {
            self.updateMealListBySections()
            
        }
        else {
            self.meals = []
            self.updateMealListBySections()
        }
        
        //get orderedMealIdentifers from disk
        let shoppingCartList = NSKeyedUnarchiver.unarchiveObject(withFile: ShoppingCartList.ArchiveURL.path) as? ShoppingCartList
        orderedMealIdentifers = shoppingCartList?.mealsIdentifiers ?? [String]()
    }
}

//UISearchResultsUpdating
extension MealListDataSource : UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        print("******search results updating*******")
        searchedMeals = meals!.filter({ (meal : Meal) -> Bool in
            if meal.mealName.lowercased().contains(searchController.searchBar.text!.lowercased()) {
                return true
            }
            else {
                return false
            }
        })
        print("\(searchedMeals)*************")
        updateSearchedMealListBySections()
        print("\(searchMealsBySections)*************")
        
        mealListVC.resultsController.tableView.reloadData()
    }
}

//UITableViewDataSource, UITableViewDelegate
extension MealListDataSource : UITableViewDataSource, UITableViewDelegate {
    //MARK: -Table setting
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == mealListVC.firstTableView
        {
            return mealListBySections.count
            
        }
        else {
            return searchMealsBySections.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == mealListVC.firstTableView
        {
            return mealListBySections[section].first?.mealType
        }else {
            return searchMealsBySections[section].first?.mealType
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == mealListVC.firstTableView
        {
            return mealListBySections[section].count
        }
        else {
            return searchMealsBySections[section].count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = TableCellReusableID.mealCell
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MealCell  else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        
        // Fetches the appropriate meal for the data source layout.
        var meal = Meal()
        if tableView == mealListVC.firstTableView {
            meal = mealListBySections[indexPath.section][indexPath.row]
        }else {
            meal = searchMealsBySections[indexPath.section][indexPath.row]
        }
        
        cell.mealName.text = meal.mealName
        cell.spicy.spicy = Int(meal.spicy)
        cell.spicy.spicyCount = Int(meal.spicy)
        cell.photo.image = DataStore().getImageForKey(key: meal.identifier)
        //photos[meal.identifier!] = cell.photo.image
        
        //设置cell的背景和按钮
        cell.order?.isSelected = meal.cellSelected
        cell.order?.setTitle("加入菜单", for: .normal)
        cell.order?.setTitle("已加入", for: .selected)
        cell.order?.addTarget(self, action: #selector(addToShoppingCart(_:)), for: .touchUpInside)
//    #selector(MealDetailVC.editMeal(_:))
        //print("设定单元格")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        print("selected func was running")
        
        if tableView == mealListVC.firstTableView
        {
// 只有segue才能传递数据，下面这个传递方法是行不通的。
//                        let mealDetailVC = MealDetailVC(nibName: "MealDetailVC", bundle: nil)
//                        mealDetailVC.meal = selectedMeal
//                        mealDetailVC.photoFromOrderMeal = pic
//                        self.mealListVC.navigationController?.pushViewController(mealDetailVC, animated: false)

            self.mealListVC.selectedIndexPath = indexPath
            self.mealListVC.performSegue(withIdentifier: SegueID.showMealDetail, sender: nil)

        }
        else {
            
            self.mealListVC.selectedIndexPath = indexPath
            self.mealListVC.performSegue(withIdentifier: SegueID.showMealDetail, sender: nil)
        }
    }
    
    // Override to support editing the table view.
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            // mealList.mealList.remove(at: indexPath.row)
            print("调用删除公式")
            
            let meal = mealListBySections[indexPath.section][indexPath.row]
            let title = "删除 \(meal.mealName)?"
            let message = "确认删除这道菜么?"
            let ac = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            ac.addAction(cancelAction)
            
            let deleteAction = UIAlertAction(title: "删除", style: .destructive, handler: {
                (action) -> Void in
                
                self.mealListBySections[indexPath.section].remove(at: indexPath.row)

                print("selected meal was removed")
                
                self.updateMeals()
                
                tableView.deleteRows(at: [indexPath], with: .fade)
                
                //数据都在本地，因此无须在服务器删除
                self.deleteMealInServer(meal)
                
                //Delete meal in stateController
                self.mealListVC?.stateController.saveMeal(self.meals!) //added
                
                //Delete meal in coredata
                HandleCoreData.deleteMealWithIdentifier(meal.identifier)
                
                //update shopping cart badge number
                let orderedMealCount = self.mealListVC?.stateController.countOrderedMealCount()
                self.updateShoppingCartIconBadgeNumber(orderedMealCount: orderedMealCount!)
                
            })
            ac.addAction(deleteAction)
            mealListVC?.present(ac, animated: true, completion: nil)
        }
        else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
}

extension MealListDataSource {
    //MARK: -Delete data in server
    func deleteMealInServer(_ meal : Meal) {
        //option 1: use metadata in local
        let key = "Record_"+meal.identifier
        let url = DataStore().objectURLForKey(key: key)
        let meladata = NSKeyedUnarchiver.unarchiveObject(withFile: url.path) as? NSMutableData
        let coder = NSKeyedUnarchiver(forReadingWith: meladata! as Data)
        coder.requiresSecureCoding = true
        let record = CKRecord(coder: coder)
        coder.finishDecoding()
        
        print(meal.database)

        if meal.database == "Private" {
            //delete CKRecord
            ZoneLocalCache.share.databases[1].cloudKitDB.delete(withRecordID: record!.recordID) { (recordID, error) in
                if error != nil {
                    // Insert error handling
                    print("failed delete in icloud")
                    return
                }
                
                // Insert successfully saved record code
                print("successfully delete in icloud")
            }
        }
        if meal.database == "Shared" {
            //delete CKRecord
            ZoneLocalCache.share.databases[2].cloudKitDB.delete(withRecordID: record!.recordID) { (recordID, error) in
                if error != nil {
                    // Insert error handling
                    print("failed delete in icloud")
                    return
                }

                // Insert successfully saved record code
                print("successfully delete in icloud")
            }
        }
        
        if meal.database != "Private" && meal.database != "Shared" {
            print("Thiss is a bug, because the record to be deleted in not in PrivateDB and SharedDB")
        }
        //option 2:
//        // Delete in background
//        let zoneIdURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: ICloudPropertyStore.keyForPrivateCustomZoneID)
//        let zoneID = NSKeyedUnarchiver.unarchiveObject(withFile: zoneIdURL.path) as? CKRecordZoneID ?? CKRecordZoneID(zoneName: ICloudPropertyStore.zoneName.privateCustomZoneName, ownerName: CKCurrentUserDefaultName)
//        let mealRecordID = CKRecordID(recordName: meal.identifier, zoneID: zoneID)
//        //Delete CKRecord
//        let myContainer = CKContainer.default()
//        let privateDatebase = myContainer.privateCloudDatabase
//        privateDatebase.delete(withRecordID: mealRecordID) { (recordID, error) in
//            if error != nil {
//                // Insert error handling
//                print("failed delete in icloud")
//                return
//            }
//
//            // Insert successfully saved record code
//            print("successfully delete in icloud")
//        }
    }
}

extension MealListDataSource {
    //MARK: -Actions
    @objc func addToShoppingCart(_ sender : UIButton) {
        
        print("data source selected")

        let contentView = sender.superview
     
        let cell = contentView?.superview as! MealCell
        
        //这是一个非常牛逼的方法，用来找到cell的TableView
        func superTableView() -> UITableView? {
            for view in sequence(first: cell.superview, next: { $0?.superview }) {
                if let tableView = view as? UITableView {
                    return tableView
                }
            }
            return nil
        }
        
        let tableView = superTableView()
        
        let index = tableView?.indexPath(for: cell)!
        print("index信息是\(String(describing: index))")
        
        var meal = Meal()
        if tableView == mealListVC.firstTableView {
            meal = mealListBySections[index!.section][index!.row]
        }else {
            meal = searchMealsBySections[index!.section][index!.row]
        }
        
        //update meal selection status in coredata
        let identifier = meal.identifier
        HandleCoreData.updateMealSelectionStatus(identifier: identifier)
        
        //update [mealsIdentifiers] of ordered meals
        if sender.isEnabled == true && sender.isSelected == false{
            //将按钮设为“已加入”
            sender.isSelected = true
            orderedMealIdentifers.append(identifier)
            
        }
        else {
            //将按钮设为“加入菜单”
            sender.isSelected = false
            for i in 0..<(orderedMealIdentifers.count) {
                if orderedMealIdentifers[i] == identifier {
                    orderedMealIdentifers.remove(at: i)
                    break
                }
            }
        }
        //read shoppingCartList from disk
        var shoppingCartList = NSKeyedUnarchiver.unarchiveObject(withFile: ShoppingCartList.ArchiveURL.path) as? ShoppingCartList
        if shoppingCartList == nil {
            //save shoppingCartList to disk
            shoppingCartList = ShoppingCartList(date: Date(), mealCatagory: "晚餐", mealsIdentifiers: orderedMealIdentifers)
            NSKeyedArchiver.archiveRootObject(shoppingCartList, toFile: ShoppingCartList.ArchiveURL.path)
        }
        else {
            //save shoppingCartList to disk
            shoppingCartList?.mealsIdentifiers = orderedMealIdentifers
            NSKeyedArchiver.archiveRootObject(shoppingCartList, toFile: ShoppingCartList.ArchiveURL.path)
        }
 
        //update shopping cart badge number
        let orderedMealCount = mealListVC?.stateController.countOrderedMealCount()
        updateShoppingCartIconBadgeNumber(orderedMealCount: orderedMealCount!)
    }
    

    //更新数据
    func updateMealListBySections(){
        var coldDishes = [Meal]()
        var hotDishes = [Meal]()
        var soup = [Meal]()
        var drink = [Meal]()
        
        for meal in meals! {
            if meal.mealType == "凉菜" {
                coldDishes.append(meal)
            }
            if meal.mealType == "热菜" {
                hotDishes.append(meal)
            }
            if meal.mealType == "汤" {
                soup.append(meal)
            }
            if meal.mealType == "酒水" {
                drink.append(meal)
            }
        }
        mealListBySections = [coldDishes,hotDishes,soup,drink]
    }

    func updateSearchedMealListBySections(){
        var coldDishes = [Meal]()
        var hotDishes = [Meal]()
        var soup = [Meal]()
        var drink = [Meal]()
        
        for meal in searchedMeals {
            if meal.mealType == "凉菜" {
                coldDishes.append(meal)
            }
            if meal.mealType == "热菜" {
                hotDishes.append(meal)
            }
            if meal.mealType == "汤" {
                soup.append(meal)
            }
            if meal.mealType == "酒水" {
                drink.append(meal)
            }
        }
        searchMealsBySections = [coldDishes,hotDishes,soup,drink]
    }
    
    //更新数据
    func updateMeals(){
        let coldDishes = mealListBySections[0]
        let hotDishes = mealListBySections[1]
        let soup = mealListBySections[2]
        let drink = mealListBySections[3]
        
        meals = coldDishes + hotDishes + soup + drink
    }
    
    func updateShoppingCartIconBadgeNumber(orderedMealCount : Int) {
        //find shopping cart badge
        let nav0 = mealListVC?.navigationController
        let tabNav = nav0?.tabBarController
        let nav1TabBar = tabNav?.viewControllers?[1].tabBarItem
        if orderedMealCount == 0 {
            nav1TabBar?.badgeValue = nil
        }
        else {
            nav1TabBar?.badgeValue = "\(orderedMealCount)"
        }
    }
}


