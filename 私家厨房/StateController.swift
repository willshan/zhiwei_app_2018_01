//
//  MealListController.swift
//  私家厨房
//
//  Created by Will.Shan on 23/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

final class StateController {
    
    static let share = StateController()
    
    fileprivate(set) var meals : [Meal]?
    fileprivate(set) var selectedMeals : [Meal]?
    fileprivate(set) var mealOrderList : [IndexPath : OrderedMeal]!
    private let userName = CKCurrentUserDefaultName
    fileprivate(set) var accountStatus = false
//    fileprivate(set) var selectedMealsCount : Int
    fileprivate(set) var reservedMeals : ReservedMeals?
    fileprivate(set) var reservedMealsHistory : [ReservedMeals]?
    
    private init() {}
    
    func initialize() {
        print("+++++CKCurrentUserDefaultName is \(userName)+++++")
        self.meals = HandleCoreData.queryDataWithUserName(userName)
        self.selectedMeals = HandleCoreData.querySelectedMealsWithUserName(userName)
//        self.orderLists = [OrderListStruct]()
        self.mealOrderList = [IndexPath : OrderedMeal]()
//        self.selectedMealsCount = selectedMeals?.count ?? 0
        self.reservedMealsHistory = readReservedMealsHistoryFromDisk()
        print("+++++stateController initiation completed++++++")
    }
    func saveReservedMeals(_ reservedMeals : ReservedMeals?) {
        self.reservedMeals = reservedMeals
    }
    
    func readReservedMealsHistoryFromDisk() -> [ReservedMeals]? {
        let key = "reservedMealsHistory"
        let archiveURL = DataStore.objectURLForKey(key: key)
        var reservedMealsHistory = [ReservedMeals]()
        if let historyList = NSKeyedUnarchiver.unarchiveObject(withFile: archiveURL.path) as? [String] {
            for list in historyList {
                let archiveURL1 = DataStore.objectURLForKey(key: list)
                let reservedMeals = NSKeyedUnarchiver.unarchiveObject(withFile: archiveURL1.path) as! ReservedMeals
                reservedMealsHistory.append(reservedMeals)
            }
        }
        reservedMealsHistory.sort { (meals1, meals2) -> Bool in
            return (meals1.date + meals1.mealCatagory) > (meals2.date + meals2.mealCatagory)
        }
        
        print("从硬盘读取到\(reservedMealsHistory.count)个预定数据！")
        return reservedMealsHistory
    }
    
    func saveMeal(_ meals : [Meal]) {
        self.meals = meals
    }
    
    func changeAccountStatus(_ status : Bool) {
        self.accountStatus = status
    }
    
    func addMeal(_ meal : Meal){
        self.meals?.append(meal)
    }
    
    func countOrderedMealCount()-> Int {
        let meals = HandleCoreData.querySelectedMealsWithUserName(userName)
        return meals.count
    }
	
    func saveMealOrderList(_ mealOrderList:[IndexPath : OrderedMeal]) {
        self.mealOrderList = mealOrderList
    }
    
    func removeMealOrderList() {
        self.mealOrderList.removeAll()
    }
    
    func getSelectedMeals() -> [Meal] {
        var meals = HandleCoreData.querySelectedMealsWithUserName(userName)
        meals.sort { (meal1, meal2) -> Bool in
            return meal1.mealName > meal2.mealName
        }
        return meals
    }
    
    func getAllMeals() -> [Meal] {
        var meals = HandleCoreData.queryDataWithUserName(userName)
        
        meals.sort { (meal1, meal2) -> Bool in
            return meal1.mealName > meal2.mealName
        }
        
        return meals
    }
}
