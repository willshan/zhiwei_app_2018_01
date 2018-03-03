//
//  MealLocalCache.swift
//  私家厨房
//
//  Created by Will.Shan on 27/02/2018.
//  Copyright © 2018 待定. All rights reserved.
//

import Foundation
import CloudKit

final class MealLocalCache: BaseLocalCache {
    static let share = MealLocalCache()
    
    var container: CKContainer!
    var database: CKDatabase!
    var zone = CKRecordZone.default()
    
    var serverChangeToken: CKServerChangeToken? = nil
    
    var meals = [Meal]()
    
    private override init() {} // Prevent clients from creating another instance.
    
    func initialize(container: CKContainer, database: CKDatabase, zone: CKRecordZone) {
        
        guard self.container == nil else {
            print("This call is ignored because local cache singleton has be initialized!")
            return
        }
        self.container = container
        
        switchZone(newDatabase: database, newZone: zone)
    }
    
    private func update(withRecordIDsDeleted : [CKRecordID]) {
        // Write this record deletion to memory
        for recordId in withRecordIDsDeleted {
            print(recordId.recordName)
            HandleCoreData.deleteMealWithIdentifier(recordId.recordName)
        }
    }
    
    private func update(withRecordsChanged : [CKRecord], database : CKDatabase) {
        for record in withRecordsChanged {
            print(record.recordType)
            if record.recordType == ICloudPropertyStore.recordType.meal {
                let identifier = record["mealIdentifier"] as! String
                print("\(identifier)")
                print("\(container.displayName(of: database))")
                let meals = HandleCoreData.queryDataWithIdentifer(identifier)
                if meals.count == 0 {
                    let _ = HandleCoreData.insertData(meal: nil, record: record, database: container.displayName(of: database))
                    
                }
                else {
                    HandleCoreData.updateData(meal: nil, record: record)
                }
                
                // Write meladata to disk
                // obtain the metadata from the CKRecord
                
                let data = NSMutableData()
                let coder = NSKeyedArchiver.init(forWritingWith: data)
                coder.requiresSecureCoding = true
                record.encodeSystemFields(with: coder)
                
                coder.finishEncoding()
                
                let key = "Record_"+identifier
                let url = DataStore().objectURLForKey(key: key)
                NSKeyedArchiver.archiveRootObject(data as Any, toFile: url.path)
            }
            else {
                continue
            }
        }
    }
    // Update the cache by fetching the database changes.
    // Note that fetching changes is only supported in custom zones.
    //
    func fetchChanges() {
        
        // Use NSMutableDictionary, rather than Swift dictionary
        // because this may be changed in the completion handler.
        //
        print("Fetching changed records begining")
        let notificationObject = NSMutableDictionary()
        
        var optionsByRecordZoneID = [CKRecordZoneID: CKFetchRecordZoneChangesOptions]()
        let options = CKFetchRecordZoneChangesOptions()
        
        if serverChangeToken == nil {
            
            let key = "zone_" + zoneID.zoneName
            let tokenURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: key)
            print("++++++++the zoneID change token key is \(key)")
            let changeToken = NSKeyedUnarchiver.unarchiveObject(withFile: tokenURL.path) as? CKServerChangeToken
            options.previousServerChangeToken = changeToken // Read change token from disk
            optionsByRecordZoneID[zoneID] = options
        }
        else {
            options.previousServerChangeToken = serverChangeToken
        }
        
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zone.zoneID],
                                                          optionsByRecordZoneID: [zone.zoneID: options])
        
        // Gather the changed records for processing in a batch.
        //
        var recordsChanged = [CKRecord]()
        operation.recordChangedBlock = { record in
            recordsChanged.append(record)
        }
        
        var recordIDsDeleted = [CKRecordID]()
        operation.recordWithIDWasDeletedBlock = { (recordID, string) in
            recordIDsDeleted.append(recordID)
        }
        
        operation.recordZoneChangeTokensUpdatedBlock = {(zoneID, serverChangeToken, clientChangeTokenData) in
            assert(zoneID == self.zone.zoneID)
            self.serverChangeToken = serverChangeToken
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
        }
        
        operation.fetchRecordZoneChangesCompletionBlock = { error in
            
            // The zone has been deleted, notify the clients so that they can update UI.
            //
            if let result = CloudKitError.share.handle(error: error, operation: .fetchChanges,
                                                       affectedObjects: [self.zone.zoneID], alert: true) {
                
                if let ckError = result[CloudKitError.Result.ckError] as? CKError, ckError.code == .zoneNotFound {
                    
                    notificationObject.setValue(NotificationReason.zoneNotFound,
                                                forKey: NotificationObjectKey.reason)
                }
                return
            }
            // Push recordIDsDeleted and recordsChanged into notification payload.
            //
            notificationObject.setValue(recordIDsDeleted, forKey: NotificationObjectKey.recordIDsDeleted)
            notificationObject.setValue(recordsChanged, forKey: NotificationObjectKey.recordsChanged)
            
            // Do the update.
            //
            self.update(withRecordIDsDeleted: recordIDsDeleted)
            self.update(withRecordsChanged: recordsChanged, database: self.database)
        }
        operation.database = database
        operationQueue.addOperation(operation)
        postNotificationWhenAllOperationsAreFinished(name: .mealCacheDidChange, object: notificationObject)
    }
    
    // Convenient method to update the cache with one specified record ID.
    //
    func update(withRecordID recordID: CKRecordID) {
        
        let fetchRecordsOp = CKFetchRecordsOperation(recordIDs: [recordID])
        fetchRecordsOp.fetchRecordsCompletionBlock = {recordsByRecordID, error in
            
            let ret = CloudKitError.share.handle(error: error, operation: .fetchRecords, affectedObjects: [recordID])
            guard  ret == nil, let record = recordsByRecordID?[recordID]  else {return}
            
            self.update(withRecordsChanged: [record], database: self.database)
            
        }
        fetchRecordsOp.database = database
        operationQueue.addOperation(fetchRecordsOp)
        postNotificationWhenAllOperationsAreFinished(name: .mealCacheDidChange)
    }
    
    // Update the cache with CKQueryNotification. For defaults zones that don't support fetching changes,
    // including the privateDB's default zone and publicDB.
    // Fetching changes is not supported in the default zone, so use CKQuerySubscription to get notified of changes.
    // Since push notifications can be coalesced, CKFetchNotificationChangesOperation is used to get the coalesced
    // notifications (if any) and keep the data synced.
    // Otherwise, we have to fetch the whole zone,
    // or move the data to custom zones which are only supported in the private database.
    //
    func update(withNotification notification: CKQueryNotification) {
        
        // Use NSMutableDictionary, rather than Swift dictionary
        // because this may be changed in the completion handler.
        //
        let notificationObject = NSMutableDictionary()
        
        let operation = CKFetchNotificationChangesOperation(previousServerChangeToken: serverChangeToken)
        
        var notifications: [CKNotification] = [notification]
        operation.notificationChangedBlock = {
            notification in notifications.append(notification)
        }
        
        operation.fetchNotificationChangesCompletionBlock = { (token, error) in
            guard CloudKitError.share.handle(error: error, operation: .fetchChanges) == nil else {return}
            
            self.serverChangeToken = token // Save the change token, which will be used in next time fetch.
            
            var recordIDsDeleted = [CKRecordID](), recordIDsChanged = [CKRecordID]()
            
            for aNotification in notifications where aNotification.notificationType != .readNotification {
                
                guard let queryNotification = aNotification as? CKQueryNotification else {continue}
                
                if queryNotification.queryNotificationReason == .recordDeleted {
                    recordIDsDeleted.append(queryNotification.recordID!)
                }
                else {
                    recordIDsChanged.append(queryNotification.recordID!)
                }
            }
            
            // Update the cache with recordIDsDeleted.
            //
            if recordIDsDeleted.count > 0 {
                notificationObject.setValue(recordIDsDeleted, forKey: NotificationObjectKey.recordIDsDeleted)
                self.update(withRecordIDsDeleted: recordIDsDeleted)
                
                recordIDsChanged = recordIDsChanged.filter({
                    recordIDsDeleted.index(of: $0) == nil ? true : false
                })
            }
            
            // Fetch the changed record with record IDs and update the cache with the records.
            // In the iCloud environment, .unknownItem errors may happen because the items are removed by other peers,
            // so simply igore the error.
            //
            if recordIDsChanged.count > 0 {
                
                let fetchRecordsOp = CKFetchRecordsOperation(recordIDs: recordIDsChanged)
                var recordsChanged = [CKRecord]()
                fetchRecordsOp.fetchRecordsCompletionBlock = { recordsByRecordID, error in
                    
                    if let result = CloudKitError.share.handle(error: error, operation: .fetchRecords,
                                                               affectedObjects: recordIDsChanged) {
                        
                        if let ckError = result[CloudKitError.Result.ckError] as? CKError,
                            ckError.code != .unknownItem {
                            return
                        }
                    }
                    if let records = recordsByRecordID?.values {
                        recordsChanged = Array(records)
                    }
                    notificationObject.setValue(recordsChanged, forKey: NotificationObjectKey.recordsChanged)
                    self.update(withRecordsChanged: recordsChanged, database: self.database)
                }
                fetchRecordsOp.database = self.database
                self.operationQueue.addOperation(fetchRecordsOp)
            }
            
            // Mark the notifications read so that they won't appear in the future fetch.
            //
            let notificationIDs = notifications.flatMap{$0.notificationID} //flatMap: filter nil values.
            let markReadOp = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: notificationIDs)
            markReadOp.markNotificationsReadCompletionBlock = { notificationIDs, error in
                guard CloudKitError.share.handle(error: error, operation: .markRead) == nil else {return}
            }
            self.container.add(markReadOp) // No impact on UI so use the internal queue.
            
            // Push recordIDsDeleted and recordsChanged into notification payload.
            //
        }
        
        operation.container = container
        operationQueue.addOperation(operation)
        postNotificationWhenAllOperationsAreFinished(name: .mealCacheDidChange, object: notificationObject)
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

