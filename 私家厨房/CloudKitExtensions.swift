/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Extensions of some CloudKit classes, implementing some reusable and convenient code.
 */

import UIKit
import CloudKit

extension CKDatabase {
    
    // Add operation to the specified operation queue, or the database internal queue if 
    // there is no operation queue specified.
    //
    fileprivate func add(_ operation: CKDatabaseOperation, to queue: OperationQueue?) {
        
        if let operationQueue = queue {
            operation.database = self
            operationQueue.addOperation(operation)
        }
        else {
            add(operation)
        }
    }
    
    fileprivate func configureQueryOperation(for operation: CKQueryOperation, results: NSMutableArray,
                                             operationQueue: OperationQueue? = nil,
                                         completionHandler: @escaping ((_ results: [CKRecord], _ moreComing: Bool, _ error: NSError?)->Void)) {
        
        // recordFetchedBlock is called every time one record is fetched,
        // so simply append the new record to the result set.
        //
        operation.recordFetchedBlock = { (record: CKRecord) in results.add(record) }
        
        // Query completion block, continue to fetch if the cursor is not nil
        //
        operation.queryCompletionBlock = { (cursor, error) in
            
            let moreComing = (cursor == nil) ? false : true
            completionHandler(results as [AnyObject] as! [CKRecord], moreComing, error as NSError?)
            if let cursor = cursor {
                self.continueFetch(with: cursor, results: results, completionHandler: completionHandler)
            }
        }
    }
    
    fileprivate func continueFetch(with queryCursor: CKQueryCursor, results: NSMutableArray, operationQueue: OperationQueue? = nil,
                                         completionHandler: @escaping ((_ results: [CKRecord], _ moreComing: Bool, _ error: NSError?)->Void)) {
        
        let operation = CKQueryOperation(cursor: queryCursor)
        configureQueryOperation(for: operation, results: results, completionHandler: completionHandler)
        add(operation, to: operationQueue)
    }
    
    func fetchRecords(with recordType: String, desiredKeys: [String]? = nil, predicate: NSPredicate? = nil,
                             sortDescriptors: [NSSortDescriptor]? = nil, zoneID: CKRecordZoneID? = nil,
                             operationQueue: OperationQueue? = nil,
                             completionHandler: @escaping ((_ results: [CKRecord], _ moreComing: Bool, _ error: NSError?)->Void)) {
        
        let query = CKQuery(recordType: recordType, predicate: predicate ?? NSPredicate(value: true))
        query.sortDescriptors = sortDescriptors
        
        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = desiredKeys
        operation.zoneID = zoneID
        
        // Using NSMutableArray, rather than [CKRecord] + inout parameter because
        // 1. results will be captured in the recordFetchedBlock closure and pass out the data gathered there.
        // 2. ther is no good way to use inout parameter in @escaping closure.
        //
        let results = NSMutableArray()
        configureQueryOperation(for: operation, results: results, operationQueue: operationQueue, completionHandler: completionHandler)
        add(operation, to: operationQueue)
    }
    
    // Use subscriptionID to create a subscriotion. Expect to hit an error of the subscritopn with the same ID
    // already exists.
    // Note that CKQuerySubscription is not supported in a sharedDB.
    //
    func addQuerySubscription(recordType: String, predicate: NSPredicate? = nil, subscriptionID: String,
                                     options: CKQuerySubscriptionOptions, zoneID: CKRecordZoneID? = nil,
                                     operationQueue: OperationQueue? = nil,
                                     completionHandler:@escaping (NSError?) -> Void) {
        
        let predicate = predicate ?? NSPredicate(value: true)
        
        let subscription = CKQuerySubscription(recordType: recordType, predicate: predicate,
                                               subscriptionID: subscriptionID, options: options)
        subscription.zoneID = zoneID
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldBadge = true
        notificationInfo.alertBody = "A \(recordType) record was changed."
        
        subscription.notificationInfo = notificationInfo
        
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil)
        
        operation.modifySubscriptionsCompletionBlock = { _, _, error in
            completionHandler(error as NSError?)
        }
        
        add(operation, to: operationQueue)
    }
    
    func addDatabaseSubscription(subscriptionID: String, operationQueue: OperationQueue? = nil,
                                        completionHandler: @escaping (NSError?) -> Void) {

        let subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldBadge = true
        notificationInfo.alertBody = "Database (\(subscriptionID)) was changed!"
        
        subscription.notificationInfo = notificationInfo
        
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil)
        
        operation.modifySubscriptionsCompletionBlock = { _, _, error in
            completionHandler(error as NSError?)
        }
        
        add(operation, to: operationQueue)
    }

    func addRecordZoneSubscription(zoneID: CKRecordZoneID, subscriptionID: String? = nil,
                                          operationQueue: OperationQueue? = nil,
                                          completionHandler:@escaping (NSError?) -> Void) {
        
        let subscription: CKRecordZoneSubscription
        if subscriptionID == nil {
            subscription = CKRecordZoneSubscription(zoneID: zoneID)
        }
        else {
            subscription = CKRecordZoneSubscription(zoneID: zoneID, subscriptionID: subscriptionID!)
        }
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldBadge = true
        notificationInfo.alertBody = "A record zone (\(zoneID)) was changed!"
        
        subscription.notificationInfo = notificationInfo
        
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil)

        operation.modifySubscriptionsCompletionBlock = { _, _, error in
            completionHandler(error as NSError?)
        }
        
        add(operation, to: operationQueue)
    }

    
    func delete(withSubscriptionIDs: [String], operationQueue: OperationQueue? = nil,
                       completionHandler:@escaping (NSError?) -> Void) {
        
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: nil, subscriptionIDsToDelete: withSubscriptionIDs)
        operation.modifySubscriptionsCompletionBlock = { _, _, error in
            completionHandler(error as NSError?)
        }
        add(operation, to: operationQueue)
    }
    
    // Fetch subscriptions with subscriptionIDs.
    //
    func fetchSubscriptions(with subscriptionIDs: [String]? = nil, operationQueue: OperationQueue? = nil,
                            completionHandler: (([String : CKSubscription]?, Error?) -> Void)? = nil) {
        
        let operation: CKFetchSubscriptionsOperation
        
        if let subscriptionIDs = subscriptionIDs {
            operation = CKFetchSubscriptionsOperation(subscriptionIDs: subscriptionIDs)
        }
        else {
            operation = CKFetchSubscriptionsOperation.fetchAllSubscriptionsOperation()
        }
        operation.fetchSubscriptionCompletionBlock = completionHandler
        add(operation, to: operationQueue)
    }
    
    // Create a record zone with zone name and owner name.
    //
    func createRecordZone(with zoneName: String, ownerName: String, operationQueue: OperationQueue? = nil,
                          completionHandler: (([CKRecordZone]?, [CKRecordZoneID]?, Error?) -> Void)?) {
        
        let zoneID = CKRecordZoneID(zoneName: zoneName, ownerName: ownerName)
        let zone = CKRecordZone(zoneID: zoneID)
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [zone], recordZoneIDsToDelete: nil)
        operation.modifyRecordZonesCompletionBlock = completionHandler
        
        add(operation, to: operationQueue)
    }
    
    // Delete a record zone.
    //
    func delete(_ zoneID: CKRecordZoneID, operationQueue: OperationQueue? = nil,
                completionHandler: (([CKRecordZone]?, [CKRecordZoneID]?, Error?) -> Void)?) {
        
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: nil, recordZoneIDsToDelete: [zoneID])
        operation.modifyRecordZonesCompletionBlock = completionHandler
        
        add(operation, to: operationQueue)
    }
}


extension CKContainer {
    
    // Database display names.
    //
    private struct DatabaseName {
        static let privateDB = "Private"
        static let publicDB = "Public"
        static let sharedDB = "Shared"
    }
    
    func displayName(of database: CKDatabase) -> String {
        
        if database.databaseScope == .public {
            return DatabaseName.publicDB
        }
        else if database.databaseScope == .private {
            return DatabaseName.privateDB
        }
        else if database.databaseScope == .shared {
            return DatabaseName.sharedDB
        }
        else {
            return ""
        }
    }

    // When userIdentityLookupInfos contains an email that doesn't exist, userIdentityDiscoveredBlock
    // will be called with uninitialized identity, causing an exception.
    //
    func discoverUserIdentities(with userIdentityLookupInfos: [CKUserIdentityLookupInfo]) {
        
        let operation = CKDiscoverUserIdentitiesOperation(userIdentityLookupInfos: userIdentityLookupInfos)
        
        operation.userIdentityDiscoveredBlock = { (identity, lookupInfo) in
            
            if (identity as CKUserIdentity?) != nil {
                print("userIdentityDiscoveredBlock: identity = \(identity), lookupInfo = \(lookupInfo)")
            }
        }
        
        operation.discoverUserIdentitiesCompletionBlock = { error in
            print("discoverUserIdentitiesCompletionBlock called!")
        }
        
        add(operation)
    }
    
    // Fetch participants from container and add them if the share is private.
    // If a participant with a matching userIdentity already exists in this share,
    // that existing participant’s properties are updated; no new participant is added
    // Note that private users cannot be added to a public share.
    //
    fileprivate func addParticipants(to share: CKShare,
                                     lookupInfos: [CKUserIdentityLookupInfo],
                                     operationQueue: OperationQueue) {
        
        if lookupInfos.count > 0 && share.publicPermission == .none {
            
            let fetchParticipantsOp = CKFetchShareParticipantsOperation(userIdentityLookupInfos: lookupInfos)
            fetchParticipantsOp.shareParticipantFetchedBlock = { participant in
                share.addParticipant(participant)
            }
            fetchParticipantsOp.fetchShareParticipantsCompletionBlock = { error in
                guard CloudKitError.share.handle(error: error, operation: .fetchRecords) == nil else {return}
            }
            fetchParticipantsOp.container = self
            operationQueue.addOperation(fetchParticipantsOp)
        }
    }
    
    // Set up UICloudSharingController for a root record. This is synchronous but can be called
    // from any queue.
    //
    func prepareSharingController(rootRecord: CKRecord, uniqueName: String, shareTitle: String,
                                  participantLookupInfos: [CKUserIdentityLookupInfo]? = nil,
                                  database: CKDatabase? = nil,
                                  completionHandler:@escaping (UICloudSharingController?) -> Void) {
        
        let cloudDB = database ?? privateCloudDatabase
        
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        
        // Share setup: fetch the share if the root record has been shared, or create a new one.
        //
        var sharingController: UICloudSharingController? = nil
        var share: CKShare! = nil
        
        if let shareRef = rootRecord.share {
            // Fetch CKShare record if the root record has alreaad shared.
            //
            let fetchRecordsOp = CKFetchRecordsOperation(recordIDs: [shareRef.recordID])
            fetchRecordsOp.fetchRecordsCompletionBlock = {recordsByRecordID, error in
                
                let ret = CloudKitError.share.handle(error: error, operation: .fetchRecords, affectedObjects: [shareRef.recordID])
                guard  ret == nil, let result = recordsByRecordID?[shareRef.recordID] as? CKShare else {return}
                
                share = result
                
                if let lookupInfos = participantLookupInfos {
                    self.addParticipants(to: share, lookupInfos: lookupInfos, operationQueue: operationQueue)
                }
            }
            fetchRecordsOp.database = cloudDB
            operationQueue.addOperation(fetchRecordsOp)
            
            // Wait until all operation are finished.
            // If share is still nil when all operations done, then there are errors.
            //
            operationQueue.waitUntilAllOperationsAreFinished()
            
            if let share = share {
                sharingController = UICloudSharingController(share: share, container: self)
            }
        }
        else {
            
            sharingController = UICloudSharingController(){(controller, prepareCompletionHandler) in
                
                let shareID = CKRecordID(recordName: uniqueName, zoneID: TopicLocalCache.share.zone.zoneID)
                share = CKShare(rootRecord: rootRecord, share: shareID)
                share[CKShareTitleKey] = shareTitle as CKRecordValue
                share.publicPermission = .none // default value.
                
                // addParticipants is asynchronous, but will be executed before modifyRecordsOp because
                // the operationqueue is serial.
                //
                if let lookupInfos = participantLookupInfos{
                    self.addParticipants(to: share, lookupInfos: lookupInfos, operationQueue: operationQueue)
                }
                
                // Clear the parent property because root record is now sharing independently.
                // Restore it when the sharing is stoped if necessary (cloudSharingControllerDidStopSharing).
                //
                rootRecord.parent = nil
                
                let modifyRecordsOp = CKModifyRecordsOperation(recordsToSave: [share, rootRecord], recordIDsToDelete: nil)
                modifyRecordsOp.modifyRecordsCompletionBlock = { records, recordIDs, error in
                    
                    // Use the serverRecord when a partial failure caused by .serverRecordChanged occurs.
                    // Let UICloudSharingController handle the other error, until failedToSaveShareWithError is called.
                    //
                    if let result = CloudKitError.share.handle(error: error, operation: .modifyRecords,affectedObjects: [shareID]) {
                        if let ckError = result[CloudKitError.Result.ckError] as? CKError,
                            let serverVersion = ckError.serverRecord as? CKShare {
                            share = serverVersion
                        }
                    }
                    prepareCompletionHandler(share, self, error)
                }
                modifyRecordsOp.database = cloudDB
                operationQueue.addOperation(modifyRecordsOp)
            }
        }
        completionHandler(sharingController)
    }
}

