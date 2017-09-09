//
//  Meal+CoreDataProperties.swift
//  
//
//  Created by Will.Shan on 07/09/2017.
//
//

import Foundation
import CoreData


extension Meal {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Meal> {
        return NSFetchRequest<Meal>(entityName: "Meal")
    }

    @NSManaged public var cellSelected: Bool
    @NSManaged public var comment: String?
    @NSManaged public var date: NSDate?
    @NSManaged public var identifier: String
    @NSManaged public var mealName: String
    @NSManaged public var mealType: String
    @NSManaged public var objectIDinServer: String?
    @NSManaged public var spicy: Int16
    @NSManaged public var userName: String?

}
