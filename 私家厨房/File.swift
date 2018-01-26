//
//  File.swift
//  私家厨房
//
//  Created by Will.Shan on 20/01/2018.
//  Copyright © 2018 待定. All rights reserved.
//
import Foundation

class ArchiveAndUnarchive : NSObject{
    
    
    class func setURL(key : String)-> URL {
        let documentsDirectories = FileManager().urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentsDirectories.first!
        return documentDirectory.appendingPathComponent(key)
    }
    
    //save property
    class func archive(data : Any, forKey key: String){
        
        let dataURL = setURL(key: key)
        
        NSKeyedArchiver.archiveRootObject(data, toFile: dataURL.path)
        
    }
    
    //use property
    class func unarchive(key : String) -> Any? {
        
        let dataURL = setURL(key: key)
        
        return NSKeyedUnarchiver.unarchiveObject(withFile: dataURL.path)
    }
}
