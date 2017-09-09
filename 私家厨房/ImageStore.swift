//
//  ImageStore.swift
//  Homepwner
//
//  Created by Will.Shan on 04/02/2017.
//  Copyright © 2017 ThreeToThousands. All rights reserved.
//

import UIKit

class ImageStore : NSObject {
    
    let cache = NSCache<AnyObject, AnyObject>()
    
    func imageURLForKey(key : String)-> URL {
        let documentsDirectories = FileManager().urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentsDirectories.first!
        return documentDirectory.appendingPathComponent(key)
    }
    
    //save images
    func setImage(image : UIImage, forKey key: String){
        cache.setObject(image, forKey : key as AnyObject)
        
        let imageURL = imageURLForKey(key: key)
        
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
    func imageForKey(key : String) -> UIImage? {
        
        //如果cache中有这个图片，从cache中取
        if let exitingImage = cache.object(forKey: key as AnyObject) as? UIImage{
            return exitingImage
        }
        
        let imageURL = imageURLForKey(key: key)
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
        
        let imageURL = imageURLForKey(key: key)
        
        do {
            //从fileSystem中删除
            try FileManager().removeItem(at: imageURL)
        }
        catch let deleteError{
            print ("图片本地删除发生错误: \(deleteError)")
        }
    }
}
