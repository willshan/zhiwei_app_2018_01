//
//  MealToServer.swift
//  私家厨房
//
//  Created by Will.Shan on 23/07/2017.
//  Copyright © 2017 待定. All rights reserved.
//
import Foundation
import os.log

final class MealToServer: PFObject {
    //MARK: Properties
    @NSManaged var mealName: String
    @NSManaged var photo: PFFile?
    @NSManaged var userName: String
    @NSManaged var spicy: Int
    @NSManaged var date : NSDate
    @NSManaged var comment : String?
    @NSManaged var mealType : String
    @NSManaged var cellSelected : Bool
    @NSManaged var identifier : String
    @NSManaged var invitationCode : String?
    
    init?(mealname: String, photo: PFFile?, spicy : Int, comment : String?, mealType : String, userName : String, date: NSDate, identifier : String, invitationCode : String?) {
        super.init()
        // Initialize stored properties.
        self.mealName = mealname
        self.photo = photo!
        self.spicy = spicy
        self.date = date
        self.comment = comment
        self.mealType = mealType
        self.userName = userName
        self.cellSelected = false
        self.invitationCode = invitationCode
    }
    
    // Required otherwise the application crashes
    override init() {
        super.init()
    }
    
    // MARK: - Overridden
    override class func query() -> PFQuery<PFObject>? {
        let query = PFQuery(className: MealToServer.parseClassName())
        query.includeKey("userName")
        //query.includeKey("identifier")
        query.order(byDescending: "createdAt")
        return query
    }
}
// MARK: - PFSubclassing
extension MealToServer: PFSubclassing {
    static func parseClassName() -> String {
        //return "MealToServer"
        return "MealToServerTest"
    }
}
