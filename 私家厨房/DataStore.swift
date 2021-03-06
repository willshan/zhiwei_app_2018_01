//
//  ImageStore.swift
//  Homepwner
//
//  Created by Will.Shan on 04/02/2017.
//  Copyright © 2017 ThreeToThousands. All rights reserved.
//

import UIKit
import CloudKit

class DataStore : NSObject {
    
    let cache = NSCache<AnyObject, AnyObject>()
    
    class func objectURLForKey(key : String)-> URL {
        let documentsDirectories = FileManager().urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentsDirectories.first!
        return documentDirectory.appendingPathComponent(key)
    }
    
//    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
//    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("shoppingCartList")
    
    //save Metadata of CKRecord
//    func setMetadataOfRecord(record : CKRecord, forKey key : String){
//        cache.setObject(record, forKey : key as AnyObject)
//
//        let url = objectURLForKey(key: key)
//
//
//    }
    
    //save images
    func saveImageInDisk(image : UIImage, forKey key: String){
        cache.setObject(image, forKey : key as AnyObject)
        
        let imageURL = DataStore.objectURLForKey(key: key)
        
        if let data = UIImageJPEGRepresentation(image, 0.5) {
            do {
            try data.write(to: imageURL)
            }
            catch let saveError {
                print("图片本地保存发生错误: \(saveError)")
            }
        }
    }
    
    
    //use images
    func getImageForKey(key : String) -> UIImage? {
        
        //如果cache中有这个图片，从cache中取
        if let exitingImage = cache.object(forKey: key as AnyObject) as? UIImage{
            return exitingImage
        }
        
        let imageURL = DataStore.objectURLForKey(key: key)
        guard let imageFromDisk = UIImage(contentsOfFile: imageURL.path) else {
            return nil
        }
        
        //保存到cache中
        cache.setObject(imageFromDisk, forKey: key as AnyObject)
        
        return imageFromDisk
    }
    
    
    //delete images
    func deleteImageForKey(key : String) {
        //从cache中删除
        cache.removeObject(forKey: key as AnyObject)
        
        let imageURL = DataStore.objectURLForKey(key: key)
        
        do {
            //从fileSystem中删除
            try FileManager().removeItem(at: imageURL)
        }
        catch let deleteError{
            print ("图片本地删除发生错误: \(deleteError)")
        }
    }
}
