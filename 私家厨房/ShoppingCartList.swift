//
//  File.swift
//  私家厨房
//
//  Created by Will.Shan on 20/01/2018.
//  Copyright © 2018 待定. All rights reserved.
//
import Foundation

class ShoppingCartList : NSObject, NSCoding{
    
    var date : Date
    var mealCatagory : String?
    var mealsIdentifiers : [String]?
    static let dateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
        
    }()
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("shoppingCartList")
    
//    //MARK: Archiving Paths
//    class func generateArchiveURL(date : Date, mealCategory : String) -> URL{
//        let date1 = dateFormatter.string(from: date)
//        let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
//        let ArchiveURL = DocumentsDirectory.appendingPathComponent("shoppingCartList_"+"\(date1)"+"_\(mealCategory)")
//        return ArchiveURL
//    }
    
    //MARK: Types
    struct PropertyKey {
        static let date = "date"
        static let mealCatagory = "mealCatagory"
        static let mealsIdentifiers = "mealsIdentifiers"
    }
    
    //MARK: Initialization
    init?(date: Date, mealCatagory: String?, mealsIdentifiers: [String]?) {
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
        let date = aDecoder.decodeObject(forKey: PropertyKey.date) as! Date
        
        // Because photo is an optional property of Meal, just use conditional cast.
        let mealCatagory = aDecoder.decodeObject(forKey: PropertyKey.mealCatagory) as? String
        
        let mealsIdentifiers = aDecoder.decodeObject(forKey: PropertyKey.mealsIdentifiers) as? [String]
        
        // Must call designated initializer.
        self.init(date: date, mealCatagory: mealCatagory, mealsIdentifiers: mealsIdentifiers)

    }
}
