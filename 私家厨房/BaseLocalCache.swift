/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Base class for local caches.
 */

import Foundation
import CloudKit

class BaseLocalCache {
    
    // A CloudKit task can be a single operation (CKDatabaseOperation) or multiple operations chained together.
    // For a single-operation task, a completion handler can be enough because CKDatabaseOperation normally
    // has a completeion handler to notify the client the task has been completed.
    // For tasks that have chained operations, we need an operation queue to waitUntilAllOperationsAreFinished
    // to know all the operations are done. This is useful for clients that need to update UI when everything is done.
    //
    lazy var operationQueue: OperationQueue = {
        return OperationQueue()
    }()
    
    // This variable can be accessed from different queue
    // > 0: TopicLocalCahce is changing and will be positing notifications. The cache is likely out of sync
    //      with UI, so users should not edit the data based on what they see.
    // ==0: No notification is pending. If there isn't any ongoing operation, the cache is synced.
    //
    private var pendingNotificationCount: Int = 0
    
    // Post the notification after all the operations are done so that observers can update the UI
    // This method can be tr-entried
    //
    func postNotificationWhenAllOperationsAreFinished(name: NSNotification.Name, object: NSDictionary? = nil) {

        pendingNotificationCount += 1 // This method can be re-entried!
        
        DispatchQueue.global().async {
            
            self.operationQueue.waitUntilAllOperationsAreFinished()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: name, object: object)
                
                self.pendingNotificationCount -= 1
                assert(self.pendingNotificationCount >= 0)
            }
        }
    }
    
    // Return the subscription IDs used for current local cache.
    func subscriptionIDs(database: Database) -> String? {
        if database.cloudKitDB.databaseScope == .private {
            return "private-changes"
        }
        if database.cloudKitDB.databaseScope == .shared {
            return "shared-changes"
        }
        else {
            return nil
        }
    }
    
//    func subscriptionIDs(databaseName: String, zone: CKRecordZone? = nil, recordType: String? = nil) -> [String] {
//
//        guard let zone = zone else { return [databaseName] }
//
//        let prefix = databaseName + "." + zone.zoneID.zoneName + "-" + zone.zoneID.ownerName
//        // Return identifier for the record type if it is specified.
//        //
//        if let recordType = recordType {
//            return [prefix + "." + recordType]
//        }
//        // If the record type is not specified, and the zone is the default one,
//        // return all valid IDs
//        //
//        if zone == CKRecordZone.default() {
//
//            return [prefix + "." + Schema.RecordType.topic,
//                    prefix + "." + Schema.RecordType.note]
//        }
//        return [prefix]
//    }
    
    // The cache is syncing if
    // 1. there is an ongoing operation, 
    // 2. there is a notification being posted.
    //
    func isUpdating() -> Bool {
        return operationQueue.operationCount > 0 || pendingNotificationCount > 0 ? true :  false
    }
}
