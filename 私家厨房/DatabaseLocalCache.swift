//
//  DatabaseLocalCache.swift
//  私家厨房
//
//  Created by Will.Shan on 28/01/2018.
//  Copyright © 2018 待定. All rights reserved.
//

import Foundation
import CloudKit

final class DatabaseLocalCache {
    
    static let share = DatabaseLocalCache()
    
    // Clients should call initialize(_:) to provide a container.
    // Otherwise trigger a crash.
    //
    // Define icloudKit
    var container: CKContainer!
    var privateDB : CKDatabase!
    var sharedDB : CKDatabase!

    lazy var operationQueue: OperationQueue = {
        return OperationQueue()
    }()
    
    // Store these to disk so that they persist across launches
    var createdPrivateCustomZone = ICloudPropertyStore.getICloudPropertyForKey(key: ICloudPropertyStore.keyForCreatedCustomZone) ?? false
    var createdShareZone = ICloudPropertyStore.getICloudPropertyForKey(key: ICloudPropertyStore.keyForCreatedShareZone) ?? false
    var subscribedToPrivateChanges = ICloudPropertyStore.getICloudPropertyForKey(key: ICloudPropertyStore.keyForSubscribedToPrivateChanges) ?? false
    var subscribedToSharedChanges = ICloudPropertyStore.getICloudPropertyForKey(key: ICloudPropertyStore.keyForSubscribedToSharedChanges) ?? false
    
    let privateSubscriptionId = "private-changes"
    let sharedSubscriptionId = "shared-changes"
    
    private init() {} // Prevent clients from creating another instance.
    
    // Subscribe the database changes and do the first fetch from server to build up the cache
    // Rely on the notificaiton update to sync the cache later on.
    // A known issue: CKDatabaseSubscription doesn't work for default zone of the private db yet.
    //
    // Subscribe the changes on the zone
    // The cache is built after the subscriptions are created to avoid losing the changes made
    // during the inteval.
    //
    // For changes on publicDB and the default zone of privateDB: CKQuerySubscription
    // For changes on a custom zone of privateDB: CKDatabaseSubscription
    // For changes on sharedDB: CKDatabaseSubscription.
    //
    // We use CKDatabaseSubscription to sync the changes on sharedDB and custom zones of privateDB
    // CKRecordZoneSubscription is thus not used here.
    //
    // Note that CKRecordZoneSubscription doesn't support the default zone and sharedDB,
    // and CKQuerySubscription doesn't support shardDB.
    //
    func initialize(container: CKContainer) {
        
        guard self.container == nil else {return}
        self.container = container
        
        self.privateDB = container.privateCloudDatabase
        self.sharedDB = container.sharedCloudDatabase
        
        //creat custon zone
        self.creatCustomZone(zoneName: ICloudPropertyStore.zoneName.privateCustomZoneName, database: privateDB) { (error) in
            if error == nil {print(":-) creat private custom zone successfully")}
            else {
                print(":-( failed creat private custom zone")
            }
            self.fetchChanges(in: .private) {_ in }
        }
//        self.creatCustomZone(zoneName: ICloudPropertyStore.zoneName.sharedCustomZoneName, database: sharedDB) { (error) in
//            if error == nil {print(":-) creat share custom zone successfully")}
//            else {
//                print(":-( failed creat shared custom zone")
//            }
//            self.fetchChanges(in: .shared) {_ in }
//            //            self.fetchChanges(in: .shared) {}
//        }

        //Use CKDatabaseSubscription to sync the changes on
        //sharedDB and custom zones of privateDB
        if !self.subscribedToPrivateChanges {
            let createSubscriptionOperation = self.createDatabaseSubscriptionOperation(subscriptionId: privateSubscriptionId)
            createSubscriptionOperation.modifySubscriptionsCompletionBlock = { (subscriptions, deletedIds, error) in
                if error == nil {
                    self.subscribedToPrivateChanges = true
                    ICloudPropertyStore.setICloudPropertyForKey(property: self.subscribedToPrivateChanges, forKey: ICloudPropertyStore.keyForSubscribedToPrivateChanges)
                }
                // else custom error handling
            }
            self.privateDB?.add(createSubscriptionOperation)
        }
        
        if !self.subscribedToSharedChanges {
            let createSubscriptionOperation = self.createDatabaseSubscriptionOperation(subscriptionId: sharedSubscriptionId)
            createSubscriptionOperation.modifySubscriptionsCompletionBlock = { (subscriptions, deletedIds, error) in
                
                if error == nil {
                    self.subscribedToSharedChanges = true
                    ICloudPropertyStore.setICloudPropertyForKey(property: self.subscribedToSharedChanges, forKey: ICloudPropertyStore.keyForSubscribedToSharedChanges)
                }
                // else custom error handling
            }
            self.sharedDB?.add(createSubscriptionOperation)
        }
        
        //Not used yet
        //Use CKQuerySubscription to sync the changes on
        //publicDB and the default zone of privateDB
        //        for database in [container.publicCloudDatabase, container.privateCloudDatabase] {
        //
        //            let databaseName = container.displayName(of: database)
        //            for recordType in [Schema.RecordType.topic, Schema.RecordType.note] {
        //
        //                let validIDs = subscriptionIDs(databaseName: databaseName,
        //                                               zone: CKRecordZone.default(), recordType: recordType)
        //                database.addQuerySubscription(
        //                    recordType: recordType, subscriptionID: validIDs[0],
        //                    options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion],
        //                    operationQueue: operationQueue) { error in
        //                        guard CloudKitError.share.handle(error: error, operation: .modifySubscriptions, alert: true) == nil else {return}
        //                }
        //            }
        //        }
        
//        fetch changes when start
        self.fetchChanges(in: .private) {_ in}
        self.fetchChanges(in: .shared) {_ in}
    }
    
    //creat database subscription
    func createDatabaseSubscriptionOperation(subscriptionId: String) -> CKModifySubscriptionsOperation {
        let subscription = CKDatabaseSubscription.init(subscriptionID: subscriptionId)
        let notificationInfo = CKNotificationInfo()
        
        // send a silent notification
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
        operation.qualityOfService = .utility
        
        return operation
    }
    
    //fetch changes
    func fetchChanges(in databaseScope: CKDatabaseScope, completion: @escaping (_ error : Error?) -> Void) {
        switch databaseScope {
        case .private:
            fetchDatabaseChanges(database: self.privateDB, databaseTokenKey: "privateDBToken", completion: completion)
            
        case .shared:
            fetchDatabaseChanges(database: self.sharedDB, databaseTokenKey: "sharedDBToken", completion: completion)
            
        case .public:
            fatalError()
        }
    }
    
    //MARK: Fetch the database changes:
    func fetchDatabaseChanges(database: CKDatabase, databaseTokenKey: String, completion: @escaping (_ error : Error?) -> Void) {
        print("++++++++fetch \(databaseTokenKey) data begin")
        var changedZoneIDs: [CKRecordZoneID] = []
        
        let databaseChangetokenURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: databaseTokenKey)
        //Be noted: this changeToken is database change token, not zone change token.
        let databaseChangeToken = NSKeyedUnarchiver.unarchiveObject(withFile: databaseChangetokenURL.path) as? CKServerChangeToken // Read change token from disk
        
        var databaseChangeTokenInMemory = databaseChangeToken
        
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: databaseChangeToken)
        print("++++++++\(databaseTokenKey) database change token is \(String(describing: databaseChangeToken))")
        
        operation.recordZoneWithIDChangedBlock = { (zoneID) in
            changedZoneIDs.append(zoneID)
            // save zone id to disk
            if zoneID.zoneName == ICloudPropertyStore.zoneName.privateCustomZoneName {
                let zoneIdURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: ICloudPropertyStore.keyForPrivateCustomZoneID)

                NSKeyedArchiver.archiveRootObject(zoneID, toFile: zoneIdURL.path)
                
                print("+++++++zoneID to be saved is \(zoneID)")
            }
        }
        
        operation.recordZoneWithIDWasDeletedBlock = { (zoneID) in
            // Write this zone deletion to memory
            
        }
        
        operation.changeTokenUpdatedBlock = { (serverChangeToken) in
            // Flush zone deletions for this database to disk
            
            //            NSKeyedArchiver.archiveRootObject(token, toFile: databaseChangetokenURL.path)
            //            print("After update, \(databaseTokenKey) database change token is \(token)")
            // Write this new database change token to memory
            databaseChangeTokenInMemory = serverChangeToken
        }
        
        operation.fetchDatabaseChangesCompletionBlock = { (serverChangeToken, moreComing, error) in
            if let error = error {
                print("Error during fetch \(databaseTokenKey) database changes operation", error)
                completion(error)
                return
            }
            // Flush zone deletions for this database to disk
            //            NSKeyedArchiver.archiveRootObject(serverChangeToken as Any, toFile: databaseChangetokenURL.path)
            //            print("Completed update, \(databaseTokenKey) database change token is \(String(describing: serverChangeToken))")
            // Write this new database change token to memory
            databaseChangeTokenInMemory = serverChangeToken
            
            self.fetchZoneChanges(database: database, databaseTokenKey: databaseTokenKey, zoneIDs: changedZoneIDs) {error in
                // Flush in-memory database change token to disk
                NSKeyedArchiver.archiveRootObject(databaseChangeTokenInMemory as Any, toFile: databaseChangetokenURL.path)
                print("Completed update, \(databaseTokenKey) database change token is \(String(describing: serverChangeToken))")
                completion(error)
            }
        }
        operation.database = database
        operation.qualityOfService = .userInitiated
        operationQueue.addOperation(operation)
    }
    
    //MARK: Fetch the zone changes:
    func fetchZoneChanges(database: CKDatabase, databaseTokenKey: String, zoneIDs: [CKRecordZoneID], completion: @escaping (_ error : Error?) -> Void) {
        // Look up the previous change token for each zone
        print("++++++++fetch zone begin")
        var optionsByRecordZoneID = [CKRecordZoneID: CKFetchRecordZoneChangesOptions]()
        var recordsChanged = [CKRecord]()
        var recordIDsDeleted = [CKRecordID]()
        
        for zoneID in zoneIDs {
            print("+++++++the zoneID is \(zoneID)")
            let key = "zone_" + zoneID.zoneName
            let tokenURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: key)
            print("++++++++the zoneID change token key is \(key)")
            let changeToken = NSKeyedUnarchiver.unarchiveObject(withFile: tokenURL.path) as? CKServerChangeToken
            let options = CKFetchRecordZoneChangesOptions()
            options.previousServerChangeToken = changeToken // Read change token from disk
            optionsByRecordZoneID[zoneID] = options
        }
        
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: zoneIDs, optionsByRecordZoneID: optionsByRecordZoneID)
        
        operation.recordChangedBlock = { (record) in
//            print("++++++++Record changed: \(record["mealName"] as! String)")
            
            // Write this record change to memery
            recordsChanged.append(record)
            
        }
        
        //    open var recordWithIDWasDeletedBlock: ((CKRecordID, String) -> Swift.Void)?
        operation.recordWithIDWasDeletedBlock = { (recordId, string) in
            print("++++++++Record deleted:", string)
            recordIDsDeleted.append(recordId)
            
        }
        
        operation.recordZoneChangeTokensUpdatedBlock = { (zoneId, token, data) in
            // Flush record changes and deletions for this zone to disk
            // Write this new zone change token to disk
            //Be noted: this changeToken is zone change token, not database change token
            var key = ""
            if self.container.displayName(of: database) == "Private" {
                key = ICloudPropertyStore.changeTokenKey.privateCustomeZone
            }
            
            if self.container.displayName(of: database) == "Shared" {
                key = ICloudPropertyStore.changeTokenKey.sharedCustomeZone
            }
            
            let tokenURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: key)
            NSKeyedArchiver.archiveRootObject(token as Any, toFile: tokenURL.path)
            //print("After update, zone change token is \(String(describing: token))")
        }
        
        operation.recordZoneFetchCompletionBlock = { (zoneId, changeToken, _, _, error) in
            if let error = error {
                print("++++++++1-Error fetching zone changes for \(databaseTokenKey) database:", error)
                return
            }
            // Flush record changes and deletions for this zone to disk
            
            // Write this new zone change token to disk
            var key = ""
            if self.container.displayName(of: database) == "Private" {
                key = ICloudPropertyStore.changeTokenKey.privateCustomeZone
            }
            
            if self.container.displayName(of: database) == "Shared" {
                key = ICloudPropertyStore.changeTokenKey.sharedCustomeZone
            }
            
            let tokenURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: key)
            NSKeyedArchiver.archiveRootObject(changeToken as Any, toFile: tokenURL.path)
            
        }
        
        //the last function being used
        operation.fetchRecordZoneChangesCompletionBlock = { (error) in
            if let error = error {
                print("++++++++2-Error fetching zone changes for \(databaseTokenKey) database:", error)
            }
            else {
                print("++++++++Successfully fetching zone changes for \(databaseTokenKey) database:")
                
                // Do the update.
                self.update(withRecordIDsDeleted: recordIDsDeleted, database: database)
                self.update(withRecordsChanged: recordsChanged, database: database)
            }
            completion(error)
        }
        operation.database = database
        operationQueue.addOperation(operation)
    }
}
extension DatabaseLocalCache {
    func update(withRecordIDsDeleted : [CKRecordID], database : CKDatabase) {
        // Write this record deletion to memory
        for recordId in withRecordIDsDeleted {
            HandleCoreData.deleteMealWithIdentifier(recordId.recordName)
        }
    }
    
    func update(withRecordsChanged : [CKRecord], database : CKDatabase) {
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
}

extension DatabaseLocalCache {
    //creat custon zone
    func creatCustomZone (zoneName : String, database : CKDatabase, completion: @escaping (_ error : Error?) -> Void) {
        
        //creat custom zone for privateDB
        if database.databaseScope == .private {
            guard self.createdPrivateCustomZone == false else {return}
            
            // Fetch any changes from the server that happened while the app wasn't running
            let zoneIdURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: ICloudPropertyStore.keyForPrivateCustomZoneID)
            let zoneID = NSKeyedUnarchiver.unarchiveObject(withFile: zoneIdURL.path) as? CKRecordZoneID ?? CKRecordZoneID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
            let privateCustomZone = CKRecordZone(zoneID: zoneID)
            let createZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: [privateCustomZone], recordZoneIDsToDelete: [] )
            
            createZoneOperation.modifyRecordZonesCompletionBlock = { (zones, zoneIDs, error) in
                if (error == nil) {
                    self.createdPrivateCustomZone = true
                    ICloudPropertyStore.setICloudPropertyForKey(property: self.createdPrivateCustomZone, forKey: ICloudPropertyStore.keyForCreatedCustomZone)
                }
                completion(error)
            }
            
            createZoneOperation.database = database
            createZoneOperation.qualityOfService = .userInitiated
            operationQueue.addOperation(createZoneOperation)
        }
        //creat custom zone for sharedDB
        else {
//            guard self.createdShareZone == false else {return}
//            // Fetch any changes from the server that happened while the app wasn't running
//            let zoneIdURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: ICloudPropertyStore.keyForSharedCustomZoneID)
//            let zoneID = NSKeyedUnarchiver.unarchiveObject(withFile: zoneIdURL.path) as? CKRecordZoneID ?? CKRecordZoneID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
//            let shareCustomZone = CKRecordZone(zoneID: zoneID)
//            let createZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: [shareCustomZone], recordZoneIDsToDelete: [] )
//
//            createZoneOperation.modifyRecordZonesCompletionBlock = { (zones, zoneIDs, error) in
//                if (error == nil) {
//                    self.createdShareZone = true
//                    ICloudPropertyStore.setICloudPropertyForKey(property: self.createdShareZone, forKey: ICloudPropertyStore.keyForCreatedShareZone)
//                }
//                completion(error)
//            }
//
//            createZoneOperation.database = database
//            createZoneOperation.qualityOfService = .userInitiated
//            operationQueue.addOperation(createZoneOperation)
        }
    }
}
