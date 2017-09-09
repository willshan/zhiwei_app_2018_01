//
//  OrderList.swift
//  私家厨房
//
//  Created by Will.Shan on 23/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit

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
