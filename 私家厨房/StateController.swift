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

class StateController {
    
    fileprivate(set) var meals : [Meal]?
    fileprivate(set) var selectedMeals : [Meal]?
    fileprivate(set) var orderLists : [OrderListStruct]
    fileprivate(set) var mealOrderList : [IndexPath : OrderedMeal]!
    private let userName = CKCurrentUserDefaultName
    fileprivate(set) var accountStatus = false
    fileprivate(set) var selectedMealsCount : Int

    //init(_ mealStorage : MealStorage) {
    init() {
        print("+++++CKCurrentUserDefaultName is \(userName)+++++")
        self.meals = HandleCoreData.queryDataWithUserName(userName)
        self.selectedMeals = HandleCoreData.querySelectedMealsWithUserName(userName)
        self.orderLists = [OrderListStruct]()
        self.mealOrderList = [IndexPath : OrderedMeal]()
        self.selectedMealsCount = selectedMeals?.count ?? 0
        
        print("+++++stateController initiation completed++++++")
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
    
    func addOrderList(_ orderTime : String, _ orderList : [[OrderedMeal]], _ mealsIdentifiers : [String]){
        self.orderLists.append(OrderListStruct(orderTime, orderList, mealsIdentifiers))
    }
    
    func loadOrderList() -> [OrderListStruct]{
        return orderLists
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
        let meals = HandleCoreData.querySelectedMealsWithUserName(userName)
        return meals
    }
    
    func getAllMeals() -> [Meal] {
        let meals = HandleCoreData.queryDataWithUserName(userName)
        return meals
    }
}
