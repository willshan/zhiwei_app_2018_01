//
//  File.swift
//  私家厨房
//
//  Created by Will.Shan on 06/09/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit

class InvitationCodeStorage : NSObject {
    
    func InvitationCodeURLForKey(key : String, userName : String)-> URL {
        let documentsDirectories = FileManager().urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentsDirectories.first!
        return documentDirectory.appendingPathComponent(key+userName)
    }
    
    //save images
    func saveInvitaionCode(code : String, forKey key: String, userName : String){
        
        let uRL = InvitationCodeURLForKey(key: key, userName: userName)
        
        if let data = code.data(using: String.Encoding.utf8) {
            do {
                try data.write(to: uRL)
            }
            catch let saveError {
                print("邀请码本地保存发生错误: \(saveError)")
            }
        }
    }
    
    
    //use images
    func invitationCodeForKey(key : String, userName : String) -> String? {
        
        let uRL = InvitationCodeURLForKey(key: key, userName: userName)
        let codeFromDisk : Data?
        let string : String?
        do {
            codeFromDisk = try Data.init(contentsOf: uRL)
            string = String(data: codeFromDisk!, encoding: String.Encoding.utf8)
            return string
        }
        catch let error {
            print("邀请码本地保存发生错误: \(error)")
            return nil
        }

    }
}
