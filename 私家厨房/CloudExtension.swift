//
//  CloudExtension.swift
//  私家厨房
//
//  Created by Will.Shan on 31/01/2018.
//  Copyright © 2018 待定. All rights reserved.
//

import UIKit
import CloudKit

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
    /*
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
    }*/
}
