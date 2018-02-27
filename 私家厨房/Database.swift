/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A database wrapper for local caches.
 */

import Foundation
import CloudKit


// CloudKit database schema name constants.
//
//struct Schema {
//    struct RecordType {
//        static let meal = "Meal"
//        static let note = "Note"
//    }
//    struct Topic {
//        static let name = "name"
//    }
//    struct Note {
//        static let title = "title"
//        static let topic = "topic"
//    }
//}

class Database {
    var serverChangeToken: CKServerChangeToken? = nil
    let name: String
    let cloudKitDB: CKDatabase
    var zones: [CKRecordZone]
    
    init(cloudKitDB: CKDatabase, container: CKContainer) {
        
        self.name = container.displayName(of: cloudKitDB)
        self.cloudKitDB = cloudKitDB
        zones = [CKRecordZone]()
        
        // Put the default zone as initial data because:
        // 1. Public database dosen't support custom zone.
        // 2. CKDatabaseSubscription doesn't capture the changes in the privateDB's default zone.
        //
        if cloudKitDB === container.publicCloudDatabase ||
            cloudKitDB === container.privateCloudDatabase {
            zones = [CKRecordZone.default()]
        }
    }    
}
