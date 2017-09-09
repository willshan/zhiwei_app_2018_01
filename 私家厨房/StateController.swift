//
//  MealListController.swift
//  私家厨房
//
//  Created by Will.Shan on 23/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit
import CoreData

class StateController {
    
    fileprivate(set) var meals : [Meal]?
    fileprivate(set) var orderLists : [OrderListStruct]
    fileprivate(set) var mealOrderList : [IndexPath : OrderedMeal]!

    //变量太多，难以维护，因此不用mealListBySections
    //fileprivate(set) var mealListBySections : [[Meal]]

    //init(_ mealStorage : MealStorage) {
    init(userName : String) {
        self.meals = HandleCoreData.queryData(userName)
        self.orderLists = [OrderListStruct]()
        self.mealOrderList = [IndexPath : OrderedMeal]()
        
        //print("stateController initiation completed")
    }
    
    func saveMeal(_ meals : [Meal]) {
        self.meals = meals
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
        var orderedMealCount = 0
        for meal in mealOrderList {
            orderedMealCount = orderedMealCount + meal.value.mealCount
        }
        return orderedMealCount
	}
	
	
    func saveMealOrderList(_ mealOrderList:[IndexPath : OrderedMeal]) {
        self.mealOrderList = mealOrderList
    }
    
    func removeMealOrderList() {
        self.mealOrderList.removeAll()
    }
}
