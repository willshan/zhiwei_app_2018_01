//
//  SharedMealLocalCache.swift
//  私家厨房
//
//  Created by Will.Shan on 10/03/2018.
//  Copyright © 2018 待定. All rights reserved.
//
import Foundation
import CloudKit

final class SharedMealLocalCache: BaseLocalCache {
    static let share = SharedMealLocalCache()
    
    var container: CKContainer!
    var database: CKDatabase!
    var zone = CKRecordZone.default()
    let key = "sharedDB_defaultZone_tokenKey"
    
    var serverChangeToken: CKServerChangeToken? = nil
    
    var meals = [Meal]()
    
    private override init() {} // Prevent clients from creating another instance.
    
    func initialize(container: CKContainer, database: CKDatabase, zone: CKRecordZone) {
        
        guard self.container == nil else {
            print("This call is ignored because local cache singleton has be initialized!")
            return
        }
        self.container = container
        let tokenURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: key)
        serverChangeToken = NSKeyedUnarchiver.unarchiveObject(withFile: tokenURL.path) as? CKServerChangeToken
        
        switchZone(newDatabase: database, newZone: zone)
    }
    
    // Update the cache by fetching the database changes.
    // Note that fetching changes is only supported in custom zones.
    //
    func fetchChanges() {
        
        // Use NSMutableDictionary, rather than Swift dictionary
        // because this may be changed in the completion handler.
        //
        print("Fetching shared changed records begining")
        let notificationObject = NSMutableDictionary()
        
        let options = CKFetchRecordZoneChangesOptions()
        options.previousServerChangeToken = serverChangeToken
        
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zone.zoneID],
                                                          optionsByRecordZoneID: [zone.zoneID: options])
        
        // Gather the changed records for processing in a batch.
        //
        var recordsChanged = [CKRecord]()
        operation.recordChangedBlock = { record in
            print("++++++++Record changed: \(record.recordID.recordName)")
            
            recordsChanged.append(record)
            
            //单个meal变化即发送
            notificationObject.setValue([record], forKey: NotificationObjectKey.sharedRecordChanged)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .mealCacheDidChange, object: notificationObject)
            }
        }
        
        var recordIDsDeleted = [CKRecordID]()
        operation.recordWithIDWasDeletedBlock = { (recordID, string) in
            print("++++++++Record deleted:", string)
            
            recordIDsDeleted.append(recordID)
            
            //单个meal变化即发送
            notificationObject.setValue([recordID], forKey: NotificationObjectKey.recordIDsDeleted)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .mealCacheDidChange, object: notificationObject)
            }
        }
        
        operation.recordZoneChangeTokensUpdatedBlock = {(zoneID, serverChangeToken, clientChangeTokenData) in
            assert(zoneID == self.zone.zoneID)
            self.serverChangeToken = serverChangeToken

            let tokenURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: self.key)
            NSKeyedArchiver.archiveRootObject(serverChangeToken as Any, toFile: tokenURL.path)
        }
        
        operation.recordZoneFetchCompletionBlock = {
            (zoneID, serverChangeToken, clientChangeTokenData, moreComing, error) in
            
            if CloudKitError.share.handle(error: error, operation: .fetchChanges) != nil,
                let ckError = error as? CKError  {
                
                // Fetch changes again with nil token if the token has expired.
                // .zoneNotfound error is handled in fetchRecordZoneChangesCompletionBlock as a partial error.
                //
                if ckError.code == .changeTokenExpired {
                    self.serverChangeToken = nil
                    self.fetchChanges()
                }
                return
            }
            assert(zoneID == self.zone.zoneID && moreComing == false)
            self.serverChangeToken = serverChangeToken
            
            //save serverChangeToken to disk
            let tokenURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: self.key)
            NSKeyedArchiver.archiveRootObject(serverChangeToken as Any, toFile: tokenURL.path)
        }
        
        operation.fetchRecordZoneChangesCompletionBlock = { error in
            
            // Push recordIDsDeleted and recordsChanged into notification payload.
            // 所有的record全部下载后一起更新
            //            notificationObject.setValue(recordIDsDeleted, forKey: NotificationObjectKey.recordIDsDeleted)
            //            notificationObject.setValue(recordsChanged, forKey: NotificationObjectKey.recordsChanged)
            
        }
        operation.database = database
        operationQueue.addOperation(operation)
        
        // 所有的record全部下载后一起更新
        //        postNotificationWhenAllOperationsAreFinished(name: .mealCacheDidChange, object: notificationObject)
    }
    
    
    // Subscribe the changes of the specified zone and do the first-time fetch to build up the cache.
    //
    func switchZone(newDatabase: CKDatabase, newZone: CKRecordZone) {
        
        // Update the zone info.
        //
        database = newDatabase
        zone = newZone
        
        if newZone == CKRecordZone.default() {
            //            fetchCurrentZone() // Fetch all records at the very beginning.
        }
        else {
            serverChangeToken = nil
            fetchChanges() // Fetching changes with nil token to build up the cache.
        }
    }
}
