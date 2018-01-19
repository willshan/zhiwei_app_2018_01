//
//  File.swift
//  私家厨房
//
//  Created by Will.Shan on 30/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import Foundation

struct OrderListStruct {
    var orderTime : String
    var orderList : [[OrderedMeal]]
    var mealsIdentifiers : [String]
    
    init(_ orderTime : String, _ orderList : [[OrderedMeal]], _ mealsIdentifiers : [String]){
        self.orderList = orderList
        self.orderTime = orderTime
        self.mealsIdentifiers = mealsIdentifiers
    }
}

struct OrderedMeal {
    var mealName : String
    var mealIdentifier : String
    var mealCount : Int
    var index : IndexPath
    
    init(mealName : String, mealIdentifier : String, mealCount : Int, index : IndexPath){
        self.mealName = mealName
        self.mealCount = mealCount
        self.index = index
        self.mealIdentifier = mealIdentifier
    }
}

struct TableCellReusableID {
    static let basic = "Basic"
    static let mealCell = "MealCell"
    static let shoppingCart = "ShoppingCart"
    static let order = "Order"
    static let orderCenter = "OrderCenter"
    static let orderDetail = "OrderDetail"
}

// Storybard ID constants.
//
struct StoryboardID {
    static let main = "Main"
    static let datePopUpSB = "DatePopUpSB"
    static let catagoryPopUpSB = "CatagoryPopUpSB"
    static let mealListVC = "MealListVC"
    static let viewDetailVC = "MealDetailVC"
    static let editMealDetailVC = "EditMealDetailVC"
    static let shoppingCartVC = "ShoppingCartVC"
    static let orderListVC = "OrderListVC"
    static let personalCenterVC = "PersonalCenterVC"
    static let orderListCenterVC = "OrderListCenterVC"
    static let orderListDetailVC = "OrderListDetailVC"
    static let loadFamilyMealListVC = "LoadFamilyMealListVC"
    static let invitationVC = "InvitationVC"
    static let personalSetVC = "PersonalSetVC"
}

// Segue ID constants.
//
struct SegueID {
    static let addNewMeal = "AddNewMeal"
    static let showMealDetail = "ShowMealDetail"
    static let editMealDetail = "EditMeal"
    static let comfirmOrderList = "ComfirmOrderList"
    static let showOrderListDetail = "ShowOrderListDetail"
    static let loadFamilyMealList = "LoadFamilyMealList"
    static let invitation = "Invitation"
    static let personalSet = "PersonalSet"
    
}

struct AssetNames {
    static let defaultPhoto = "defaultPhoto"
    static let graySpicy = "graySpicy"
    static let redSpicy = "redSpicy"
    static let menu = "menu"
    static let message = "message"
    static let personalCenter = "personalCenter"
    static let shoppingCart = "shoppingCart"
}
