//
//  ICloudPropertyStore.swift
//  私家厨房
//
//  Created by Will.Shan on 07/10/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit
import CloudKit

class ICloudPropertyStore : NSObject{
    
    static let keyForCreatedCustomZone = "createdPrivateCustomZone"
    static let keyForCreatedShareZone = "createdShareZone"
    static let keyForSubscribedToPrivateChanges = "setSubscribedToPrivateChanges"
    static let keyForSubscribedToSharedChanges = "setSubscribedToSharedChanges"
    static let keyForPrivateCustomZoneID = "private_zoneID_Meals"
    static let keyForReservedMealsZoneID = "private_zoneID_ReservedMeals"
    static let keyForSharedCustomZoneID = "shared_zoneID_Meals"
    
    struct zoneName {
        static let privateCustomZoneName = "Meals"
        static let sharedCustomZoneName = "SharedMeals"
        static let reservedMealsZoneName = "ReservedMeals"
    }
    struct recordType {
        static let meal = "Meal"
        static let share = "cloudkit.share"
        static let reservedMeals = "ReservedMeals"
    }
    struct changeTokenKey {
        static let privateDB = "privateDBChangeToken"
        static let privateCustomeZone = "privateCustomeZoneChangeToken"
        static let sharedDB = "sharedDBChangeToken"
        static let sharedCustomeZone = "sharedCustomeZoneChangeToken"
    }
    /*
    var changeToken : CKServerChangeToken?
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(changeToken, forKey: "changeToken")
    }
    
    required init(coder aDecoder : NSCoder) {
        changeToken = aDecoder.decodeObject(forKey: "changeToken") as CKServerChangeToken
        super.init()
    }
    */
    
    class func URLofiCloudPropertyForKey(key : String)-> URL {
        let documentsDirectories = FileManager().urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentsDirectories.first!
        return documentDirectory.appendingPathComponent(key)
    }
    
    //save property
    class func setICloudPropertyForKey(property : Bool, forKey key: String){

        let propertyURL = URLofiCloudPropertyForKey(key: key)

        NSKeyedArchiver.archiveRootObject(property, toFile: propertyURL.path)

    }

    //use property
    class func getICloudPropertyForKey(key : String) -> Bool? {

        let propertyURL = URLofiCloudPropertyForKey(key: key)

        return NSKeyedUnarchiver.unarchiveObject(withFile: propertyURL.path) as? Bool
    }
}
