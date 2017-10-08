//
//  ICloudPropertyStore.swift
//  私家厨房
//
//  Created by Will.Shan on 07/10/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit
class ICloudPropertyStore : NSObject{
    
    static let keyForCreatedCustomZone = "createdCustomZone"
    static let keyForSubscribedToPrivateChanges = "createdCustomZone"
    static let keyForSubscribedToSharedChanges = "createdCustomZone"
    
    class func iCloudProtpertyForKey(key : String)-> URL {
        let documentsDirectories = FileManager().urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentsDirectories.first!
        return documentDirectory.appendingPathComponent(key)
    }
    
    //save property
    class func setiCloudProperty(property : Bool, forKey key: String){
        
        let propertyURL = iCloudProtpertyForKey(key: key)
        
        NSKeyedArchiver.archiveRootObject(property, toFile: propertyURL.path)
        
    }
    
    //use property
    class func propertyForKey(key : String) -> Bool? {
        
        let propertyURL = iCloudProtpertyForKey(key: key)
        
        return NSKeyedUnarchiver.unarchiveObject(withFile: propertyURL.path) as? Bool
    }
}
