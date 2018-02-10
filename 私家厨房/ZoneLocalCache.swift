/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Zone local cache class, managing the zone local cache.
 */

import Foundation
import CloudKit

final class ZoneLocalCache: BaseLocalCache {
    
    static let share = ZoneLocalCache()
    
    // Clients should call initialize(_:) to provide a container.
    // Otherwise trigger a crash.
    //
    var container: CKContainer!
    private(set) var databases: [Database]!
    
    // Store these to disk so that they persist across launches
    var createdCustomZone = ICloudPropertyStore.getICloudPropertyForKey(key: ICloudPropertyStore.keyForCreatedCustomZone) ?? false
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
        
        //Use CKDatabaseSubscription to sync the changes on
        //sharedDB and custom zones of privateDB
        for database in databases where database.cloudKitDB.databaseScope != .public {
            
//            subscriptionID结构： databaseName.zoneName.recordType
//                        private struct DatabaseName {
//                            static let privateDB = "Private"
//                            static let publicDB = "Public"
//                            static let sharedDB = "Shared"
//                        }
//            if zone = nil , subscriptionID = "Private"
//            if zoneName = Meals, subscriptionID = "Private.Meals"
//            if recordType = Meal, subscriptionID = "Private.Meals.Meal"
//            because one zone can have differenct recordTypes
//                            func subscriptionIDs(databaseName: String, zone: CKRecordZone? = nil, recordType: String? = nil) -> [String]
            if database.name == "Private" && subscribedToPrivateChanges == false {
                database.cloudKitDB.addDatabaseSubscription(
                    subscriptionID: subscriptionIDs(databaseName: database.name)[0],
                    operationQueue: operationQueue) { error in
                        guard CloudKitError.share.handle(error: error, operation: .modifySubscriptions, alert: true) == nil else {return}
                        self.subscribedToPrivateChanges = true
                        //save "subscribedToPrivateChanges"
                        ICloudPropertyStore.setICloudPropertyForKey(property: self.subscribedToPrivateChanges, forKey: ICloudPropertyStore.keyForSubscribedToPrivateChanges)
                        
                        self.fetchChanges(from: database)
                }
            }
            
            if database.name == "Shared" && subscribedToPrivateChanges == false {
                database.cloudKitDB.addDatabaseSubscription(
                    subscriptionID: subscriptionIDs(databaseName: database.name)[0],
                    operationQueue: operationQueue) { error in
                        guard CloudKitError.share.handle(error: error, operation: .modifySubscriptions, alert: true) == nil else {return}
                        self.subscribedToSharedChanges = true
                        //save "subscribedToSharedChanges"
                        ICloudPropertyStore.setICloudPropertyForKey(property: self.subscribedToSharedChanges, forKey: ICloudPropertyStore.keyForSubscribedToSharedChanges)
                        
                        self.fetchChanges(from: database)
                }
            }
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
    }
    
    // Update the cache by fetching the database changes.
    //
    func fetchChanges(from database: Database) {
        
        //MARK: serverChangeToken must be saved in disk
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: database.serverChangeToken)
        let serverChangeTokenURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: database.name)
        
        //set up a array for changed zones
        var zoneIDsChanged = [CKRecordZoneID]()
        
        //update serverChangeToken in memory
        //update serverChangeToken in disk
        operation.changeTokenUpdatedBlock = { serverChangeToken in
            database.serverChangeToken = serverChangeToken
            
            NSKeyedArchiver.archiveRootObject(serverChangeToken, toFile: serverChangeTokenURL.path)
            print("After update, database change token is \(serverChangeToken)")
        }
        
        operation.recordZoneWithIDChangedBlock = { zoneID in
            
            zoneIDsChanged.append(zoneID)
            //save zoneID for "Meals" in disk
            if zoneID.zoneName == "Meals" {
                
                let zoneIdURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: ICloudPropertyStore.keyForPrivateCustomZoneID)
                NSKeyedArchiver.archiveRootObject(zoneID, toFile: zoneIdURL.path)
                
                print("+++++++zoneID to be saved is \(zoneID)")
            }
            
            // Sync TopicLocalCache if the current zone is changed.
            // Note that TopicLocalCache has an independent operation queue.
            //
//            guard database.cloudKitDB === TopicLocalCache.share.database &&
//                zoneID == TopicLocalCache.share.zone.zoneID else {return}
//
//            TopicLocalCache.share.fetchChanges()
        }
        
        //record zone will not be deleted in this app, so ignore the func
        operation.recordZoneWithIDWasDeletedBlock = { zoneID in
//            if let index = database.zones.index(where: {$0.zoneID == zoneID}) {
//                database.zones.remove(at: index)
//            }
//
//            guard database.cloudKitDB === TopicLocalCache.share.database &&
//                zoneID == TopicLocalCache.share.zone.zoneID else {return}
//
//            // Post a notification if the current zone is removed.
//            // Note that TopicLocalCache has an independent operation queue.
//            //
//            let notificationUserInfo = NSMutableDictionary()
//            notificationUserInfo.setValue(NotificationReason.zoneNotFound,
//                                          forKey: NotificationObjectKey.reason)
//            TopicLocalCache.share.postNotificationWhenAllOperationsAreFinished(
//                name: .topicCacheDidChange, object: notificationUserInfo)
        }

        operation.fetchDatabaseChangesCompletionBlock = { serverChangeToken, moreComing, error in
            
            if CloudKitError.share.handle(error: error, operation: .fetchChanges, alert: true) != nil {
                if let ckError = error as? CKError, ckError.code == .changeTokenExpired {
                    database.serverChangeToken = nil
                    self.fetchChanges(from: database) // Fetch changes again with nil token.
                }
                return
            }
            
            database.serverChangeToken = serverChangeToken
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
        }
        operation.database = database.cloudKitDB
        operationQueue.addOperation(operation)
        postNotificationWhenAllOperationsAreFinished(name: .zoneCacheDidChange)
    }
}

extension ZoneLocalCache {
    
    // Add a zone.
    // A single-operation task, use completion handler to notify the clients. Not used in this sample.
    //
    func addZone(with zoneName: String, ownerName: String, to database: Database,
                 completionHandler:@escaping ([CKRecordZone]?, [CKRecordZoneID]?, Error?) -> Void) {
        
        database.cloudKitDB.createRecordZone(with: zoneName, ownerName: ownerName){ zones, zoneIDs, error in
            
            if CloudKitError.share.handle(error: error, operation: .modifyZones, alert: true) == nil {
                database.zones.append(zones![0])
                database.zones.sort(by:{ $0.zoneID.zoneName < $1.zoneID.zoneName })
            }
            completionHandler(zones, zoneIDs, error)
        }
    }
    
    func saveZone(with zoneName: String, ownerName: String, to database: Database) {
        
        let zoneID = CKRecordZoneID(zoneName: zoneName, ownerName: ownerName)
        let newZone = CKRecordZone(zoneID: zoneID)
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [newZone], recordZoneIDsToDelete: nil)
        
        operation.modifyRecordZonesCompletionBlock = { (zones, zoneIDs, error) in
            guard CloudKitError.share.handle(error: error, operation: .modifyZones, alert: true) == nil,
                let savedZone = zones?[0] else {return}
            
            if database.zones.index(where: {$0 == savedZone}) == nil {
                database.zones.append(savedZone)
            }
            database.zones.sort(by:{ $0.zoneID.zoneName < $1.zoneID.zoneName })

        }
        operation.database = database.cloudKitDB
        operationQueue.addOperation(operation)
        postNotificationWhenAllOperationsAreFinished(name: .zoneCacheDidChange)
    }
    
    // Delete a zone.
    // A single-operation task, use completion handler to notify the clients. Not used in this sample.
    //
    func delete(_ zone: CKRecordZone, from database: Database,
                completionHandler: @escaping ([CKRecordZone]?, [CKRecordZoneID]?, Error?) -> Void) {
        
        database.cloudKitDB.delete(zone.zoneID) { zones, zoneIDs, error in
            
            if CloudKitError.share.handle(error: error, operation: .modifyZones, alert: true) == nil {
                if let index = database.zones.index(of: zone) {
                    database.zones.remove(at: index)
                }
            }
            completionHandler(zones, zoneIDs, error)
        }
    }
    
    func deleteZone(_ zone: CKRecordZone, from database: Database) {
        
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: nil, recordZoneIDsToDelete: [zone.zoneID])
        operation.modifyRecordZonesCompletionBlock = { (_, _, error) in
            
            guard CloudKitError.share.handle(error: error, operation: .modifyRecords, alert: true) == nil,
                let index = database.zones.index(of: zone) else {return}
            database.zones.remove(at: index)
        }
        operation.database = database.cloudKitDB
        operationQueue.addOperation(operation)
        postNotificationWhenAllOperationsAreFinished(name: .zoneCacheDidChange)
    }
    
    func deleteCachedZone(_ zone: CKRecordZone, database: Database) {
        
        if let index = database.zones.index(of: zone) {
            database.zones.remove(at: index)
            postNotificationWhenAllOperationsAreFinished(name: .zoneCacheDidChange)
        }
    }
}
