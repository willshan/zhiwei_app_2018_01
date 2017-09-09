//
//  File.swift
//  私家厨房
//
//  Created by Will.Shan on 30/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit

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
    
