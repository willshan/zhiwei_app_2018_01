//
//  File.swift
//  私家厨房
//
//  Created by Will.Shan on 20/01/2018.
//  Copyright © 2018 待定. All rights reserved.
//
import Foundation

class ReservedMeals : NSObject, NSCoding{
    
    var date : String
    var mealCatagory : String
    var mealsIdentifiers : [String]?

    //MARK: Types
    struct PropertyKey {
        static let date = "date"
        static let mealCatagory = "mealCatagory"
        static let mealsIdentifiers = "mealsIdentifiers"
    }
    
    //MARK: Initialization
    init?(_ date: String, _ mealCatagory: String, _ mealsIdentifiers: [String]?) {
        // Initialize stored properties.
        self.date = date
        self.mealCatagory = mealCatagory
        self.mealsIdentifiers = mealsIdentifiers
    }
    
    //MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(date, forKey: PropertyKey.date)
        aCoder.encode(mealCatagory, forKey: PropertyKey.mealCatagory)
        aCoder.encode(mealsIdentifiers, forKey: PropertyKey.mealsIdentifiers)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        // The name is required. If we cannot decode a name string, the initializer should fail.
        let date = aDecoder.decodeObject(forKey: PropertyKey.date) as! String
        
        // Because photo is an optional property of Meal, just use conditional cast.
        let mealCatagory = aDecoder.decodeObject(forKey: PropertyKey.mealCatagory) as! String
        
        let mealsIdentifiers = aDecoder.decodeObject(forKey: PropertyKey.mealsIdentifiers) as? [String]
        
        // Must call designated initializer.
        self.init(date, mealCatagory, mealsIdentifiers)

    }
}
