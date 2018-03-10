//
//  DatabaseLocalCache.swift
//  私家厨房
//
//  Created by Will.Shan on 28/01/2018.
//  Copyright © 2018 待定. All rights reserved.
//

import Foundation
import CloudKit

final class ZoneLocalCache : BaseLocalCache{
    
    static let share = ZoneLocalCache()
    
    // Clients should call initialize(_:) to provide a container.
    // Otherwise trigger a crash.
    //
    // Define icloudKit
    var container: CKContainer!
    private(set) var databases: [Database]!
    
    // Store these to disk so that they persist across launches
    var createdPrivateCustomZone = ICloudPropertyStore.getICloudPropertyForKey(key: ICloudPropertyStore.keyForCreatedCustomZone) ?? false
    var createdShareZone = ICloudPropertyStore.getICloudPropertyForKey(key: ICloudPropertyStore.keyForCreatedShareZone) ?? false
    var subscribedToPrivateChanges = ICloudPropertyStore.getICloudPropertyForKey(key: ICloudPropertyStore.keyForSubscribedToPrivateChanges) ?? false
    var subscribedToSharedChanges = ICloudPropertyStore.getICloudPropertyForKey(key: ICloudPropertyStore.keyForSubscribedToSharedChanges) ?? false
    
    private override init() {} // Prevent clients from creating another instance.
    
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
        
        databases = [
            Database(cloudKitDB: container.publicCloudDatabase, container: container),
            Database(cloudKitDB: container.privateCloudDatabase, container: container),
            Database(cloudKitDB: container.sharedCloudDatabase, container: container)
        ]
        
        //creat custon zone for private database
        self.creatCustomZone(zoneName: ICloudPropertyStore.zoneName.privateCustomZoneName, database: databases[1]) { (error) in
            if error == nil {print(":-) creat private custom zone successfully")}
            else {
                print(":-( failed creat private custom zone")
            }
            self.fetchChanges(in: .private, completion: { (_) in
            })
        }

        //Use CKDatabaseSubscription to sync the changes on
        //sharedDB and custom zones of privateDB
//        Option 1:
        for database in databases where database.cloudKitDB.databaseScope != .public {
            if !self.subscribedToPrivateChanges && database.cloudKitDB.databaseScope == .private{
                database.cloudKitDB.addDatabaseSubscription(
                    subscriptionID: subscriptionIDs(database: database)!,
                    operationQueue: operationQueue) { error in
                        guard CloudKitError.share.handle(error: error, operation: .modifySubscriptions, alert: true) == nil else {return}

                        self.subscribedToPrivateChanges = true
                        ICloudPropertyStore.setICloudPropertyForKey(property: self.subscribedToPrivateChanges, forKey: ICloudPropertyStore.keyForSubscribedToPrivateChanges)
                        
                        self.fetchChanges(in: database.cloudKitDB.databaseScope, completion: { (_) in
                        })
                }
            }

            if !self.subscribedToSharedChanges && database.cloudKitDB.databaseScope == .shared{
                database.cloudKitDB.addDatabaseSubscription(
                    subscriptionID: subscriptionIDs(database: database)!,
                    operationQueue: operationQueue) { error in
                        guard CloudKitError.share.handle(error: error, operation: .modifySubscriptions, alert: true) == nil else {return}

                        self.subscribedToSharedChanges = true
                        ICloudPropertyStore.setICloudPropertyForKey(property: self.subscribedToSharedChanges, forKey: ICloudPropertyStore.keyForSubscribedToSharedChanges)
                        
                        self.fetchChanges(in: database.cloudKitDB.databaseScope, completion: { (_) in
                        })
                }
            }
        }
//        //Option 2:
//        for database in databases where database.cloudKitDB.databaseScope != .public {
//
//            database.cloudKitDB.addDatabaseSubscription(
//                subscriptionID: subscriptionIDs(database: database)!,
//                operationQueue: operationQueue) { error in
//                    guard CloudKitError.share.handle(error: error, operation: .modifySubscriptions, alert: true) == nil else {return}
//                    self.fetchChanges(in: database.cloudKitDB.databaseScope, completion: { (_) in
//                    })
//            }
//        }
        
//        if !self.subscribedToPrivateChanges {
//            let createSubscriptionOperation = self.createDatabaseSubscriptionOperation(subscriptionId: privateSubscriptionId)
//            createSubscriptionOperation.modifySubscriptionsCompletionBlock = { (subscriptions, deletedIds, error) in
//                if error == nil {
//                    self.subscribedToPrivateChanges = true
//                    ICloudPropertyStore.setICloudPropertyForKey(property: self.subscribedToPrivateChanges, forKey: ICloudPropertyStore.keyForSubscribedToPrivateChanges)
//                }
//                // else custom error handling
//            }
//            self.privateDB?.add(createSubscriptionOperation)
//        }
//
//        if !self.subscribedToSharedChanges {
//            let createSubscriptionOperation = self.createDatabaseSubscriptionOperation(subscriptionId: sharedSubscriptionId)
//            createSubscriptionOperation.modifySubscriptionsCompletionBlock = { (subscriptions, deletedIds, error) in
//
//                if error == nil {
//                    self.subscribedToSharedChanges = true
//                    ICloudPropertyStore.setICloudPropertyForKey(property: self.subscribedToSharedChanges, forKey: ICloudPropertyStore.keyForSubscribedToSharedChanges)
//                }
//                // else custom error handling
//            }
//            self.sharedDB?.add(createSubscriptionOperation)
//        }
//
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
            fetchDatabaseChanges(database: databases[1], databaseTokenKey: "privateDBToken", completion: completion)
            
        case .shared:
            fetchDatabaseChanges(database: databases[2], databaseTokenKey: "sharedDBToken", completion: completion)
            
        case .public:
            fatalError()
        }
    }
    
    //MARK: Fetch the database changes, serverChangeToken of different database is stored in different file
    func fetchDatabaseChanges(database: Database, databaseTokenKey: String, completion: @escaping (_ error : Error?) -> Void) {
        print("++++++++fetch \(databaseTokenKey) data begin")
        var zoneIDsChanged: [CKRecordZoneID] = []
        
        let databaseChangetokenURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: databaseTokenKey)
        //Be noted: this changeToken is database change token, not zone change token.
        let databaseChangeToken = NSKeyedUnarchiver.unarchiveObject(withFile: databaseChangetokenURL.path) as? CKServerChangeToken // Read change token from disk
        
        database.serverChangeToken = databaseChangeToken
        
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: database.serverChangeToken)
        print("++++++++\(databaseTokenKey) database change token is \(String(describing: databaseChangeToken))")
        
        operation.recordZoneWithIDChangedBlock = { (zoneID) in
            
            zoneIDsChanged.append(zoneID)
            // save zone id to disk
            if zoneID.zoneName == ICloudPropertyStore.zoneName.privateCustomZoneName {
                let zoneIdURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: ICloudPropertyStore.keyForPrivateCustomZoneID)

                NSKeyedArchiver.archiveRootObject(zoneID, toFile: zoneIdURL.path)
                
                print("+++++++zoneID to be saved is \(zoneID)")
            }
//            guard database.cloudKitDB === MealLocalCache.share.database &&
//                zoneID == MealLocalCache.share.zone.zoneID else {return}
//            MealLocalCache.share.fetchChanges()
        }
        
        operation.recordZoneWithIDWasDeletedBlock = { (zoneID) in
            // Write this zone deletion to memory
            
        }
        
        operation.changeTokenUpdatedBlock = { (serverChangeToken) in
            // Flush zone deletions for this database to disk
            
            //            NSKeyedArchiver.archiveRootObject(token, toFile: databaseChangetokenURL.path)
            //            print("After update, \(databaseTokenKey) database change token is \(token)")
            // Write this new database change token to memory
            database.serverChangeToken = serverChangeToken
        }
        
        operation.fetchDatabaseChangesCompletionBlock = { (serverChangeToken, moreComing, error) in
            if let error = error {
                print("Error during fetch \(databaseTokenKey) database changes operation", error)
                completion(error)
                return
            }
           
            // Write this new database change token to memory
            database.serverChangeToken = serverChangeToken
            
            // Flush this database change token into disk
            NSKeyedArchiver.archiveRootObject(serverChangeToken as Any, toFile: databaseChangetokenURL.path)
            print("Completed update, \(databaseTokenKey) database change token is \(String(describing: serverChangeToken))")
            
            guard moreComing == false else {return}
        
//            let newZoneIDs = zoneIDsChanged.filter() {zoneID in
//                let index = database.zones.index(where: { zone in zone.zoneID == zoneID})
//                return index == nil ? true : false
//            }
//
//            guard newZoneIDs.count > 0 else {return}
//
//            let fetchZonesOp = CKFetchRecordZonesOperation(recordZoneIDs: newZoneIDs)
//            fetchZonesOp.fetchRecordZonesCompletionBlock = { results, error in
//
//                guard CloudKitError.share.handle(error: error, operation: .fetchRecords) == nil,
//                    let zoneDictionary = results else {return}
//
//                for (_, zone) in zoneDictionary { database.zones.append(zone) }
//                database.zones.sort(){ $0.zoneID.zoneName < $1.zoneID.zoneName }
//            }
//
//            fetchZonesOp.database = database.cloudKitDB
//            self.operationQueue.addOperation(fetchZonesOp)
            
//            // Flush in-memory database change token to disk
//            NSKeyedArchiver.archiveRootObject(database.serverChangeToken as Any, toFile: databaseChangetokenURL.path)
            if database.name == "Private" {
                MealLocalCache.share.fetchChanges()
            }
            if database.name == "Shared" {
                SharedMealLocalCache.share.fetchChanges()
            }
            completion(error)
        }
        operation.database = database.cloudKitDB
        operation.qualityOfService = .userInitiated
        operationQueue.addOperation(operation)
    }
}

extension ZoneLocalCache {
    //creat custon zone
    func creatCustomZone (zoneName : String, database : Database, completion: @escaping (_ error : Error?) -> Void) {
        
        //creat custom zone for privateDB
        if database.cloudKitDB.databaseScope == .private {
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
    
                    //save custom zone to MealLocalCache
                    MealLocalCache.share.zone = zones![0]

                    //save custom zoneID in disk
                    NSKeyedArchiver.archiveRootObject(zones![0].zoneID, toFile: zoneIdURL.path)
                    
                    MealLocalCache.share.fetchChanges()
                }
                completion(error)
            }
            
            createZoneOperation.database = database.cloudKitDB
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

