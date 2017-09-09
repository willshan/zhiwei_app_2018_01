//
//  OrderList.swift
//  私家厨房
//
//  Created by Will.Shan on 24/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit


class OrderListMealStorage {
    
    //MARK: Archiving Paths
    fileprivate let orderListMealArchiveURL : URL = {
        let documentsDirectories = FileManager().urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentsDirectories.first!
        return documentDirectory.appendingPathComponent("orderListMeals.archive")
    }()
    
    func saveChanges(_ OrderListMeal : [OrderedMeal]) ->Bool {
        print("Saving items to: \(orderListMealArchiveURL.path)")
        return NSKeyedArchiver.archiveRootObject(OrderListMeal, toFile: orderListMealArchiveURL.path)
    }
    
    func loadMeals() -> [OrderedMeal]?  {
        return NSKeyedUnarchiver.unarchiveObject(withFile: orderListMealArchiveURL.path) as? [OrderedMeal]
    }
    
}

