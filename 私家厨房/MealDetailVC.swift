//
//  ViewDetailVC.swift
//  私家厨房
//
//  Created by Will.Shan on 28/07/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

class MealDetailVC: UIViewController {

    //MARK: -Properties
    @IBOutlet weak var mealName: UILabel!
    @IBOutlet weak var spicy: Spicy!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var comment: UITextView!
    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var mealType: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    
    var meal: Meal!
    var photoFromOrderMeal : UIImage!

    let dateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

extension MealDetailVC {
    //MARK: -LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
    
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .always
        } else {
            // Fallback on earlier versions
        }
        var editButtonItem : UIBarButtonItem {
            return UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(MealDetailVC.editMeal(_:)))
        }
        
        var shareButtonItem : UIBarButtonItem {
            return UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(MealDetailVC.shareWithFamilyMember(_:)))
        }

        navigationItem.rightBarButtonItems = [editButtonItem,shareButtonItem]

        navigationItem.title = meal.mealName
        mealName.text = meal.mealName
        mealType.text = meal.mealType
        spicy.spicy = Int(meal.spicy)
        spicy.spicyCount = Int(meal.spicy)
        comment.text = meal.comment
        date.text = dateFormatter.string(from: meal.date as Date)
        photo.image = photoFromOrderMeal

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
      
        spinner.center = CGPoint(x: UIScreen().bounds.size.width / 2, y: UIScreen().bounds.size.height / 2 - 88)
    }
}

extension MealDetailVC {
    //MARK: -Actions
    //func editMeal(_ sender : UIBarButtonItem){
    @objc func editMeal(_ sender : UIBarButtonItem){
        print("edit func was performed")
        
        UIView.animate(withDuration: 0.3) {
            self.performSegue(withIdentifier: SegueID.editMealDetail, sender: nil)
        }
        //}
    }
}

extension MealDetailVC : UICloudSharingControllerDelegate{
    
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        print("\(error)")
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        return meal.mealName
    }
    
    // When a topic is shared successfully, this method is called, the CKShare should have been created,
    // and the whole share hierarchy should have been updated in server side. So fetch the changes and
    // update the local cache.
    //
    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {

    }
    
    // When a share is stopped and this method is called, the CKShare record should have been removed and
    // the root record should have been updated in the server side. So fetch the changes and update
    // the local cache.
    //
    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        
        // Stop sharing can happen on two scenarios, a ower stop a share or a participant removes self from a share.
        // In the former case, no visual things will be changed in the owner side (privateDB);
        // in the latter case, the share will disappear from the sharedDB; and if the share is the only item in the
        // current zone, the zone should also be removed.
        // Note fetching immediately here may not get all the changes because the server side needs a while to index.

    }
    
    func presentOrAlertOnMainQueue(sharingController: UICloudSharingController?) {
        if let sharingController = sharingController {
            DispatchQueue.main.async {
                sharingController.delegate = self
//                sharingController.popoverPresentationController?.sourceView = self.navigationItem.titleView
                sharingController.availablePermissions = [.allowPublic, .allowPrivate, .allowReadOnly, .allowReadWrite]
                self.present(sharingController, animated: true) {
                    self.spinner.stopAnimating()
                }
            }
        }
            
        else {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Failed to share.",
                                              message: "Can't set up a valid share object.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true) {
                    self.spinner.stopAnimating()
                }
            }
        }
    }
    
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
            fetchParticipantsOp.container = ZoneLocalCache.share.container
            operationQueue.addOperation(fetchParticipantsOp)
        }
    }
    
    //MARK: Init sharing view controller
    @objc func shareWithFamilyMember(_ sender : UIBarButtonItem) {
        print("init sharing")
//        let operationQueue = OperationQueue()
        
        spinner.startAnimating()
        // Option 1: set up the CKRecord with its metadata
        // used record meta data stored in disk to get root record ID
        let key = "Record_"+meal.identifier
        let url = DataStore().objectURLForKey(key: key)
        let meladata = NSKeyedUnarchiver.unarchiveObject(withFile: url.path) as? NSMutableData
        let coder = NSKeyedUnarchiver(forReadingWith: meladata! as Data)
        coder.requiresSecureCoding = true
        let record = CKRecord(coder: coder)
        coder.finishDecoding()
        
//        let participantLookupInfos = [CKUserIdentityLookupInfo(emailAddress: "willshan.ws@hotmail.com"),
//                                      CKUserIdentityLookupInfo(phoneNumber: "1234567890")]
        let shareTitle = "\(meal.mealName) 与您共享"
        
        DispatchQueue.main.async {
            ZoneLocalCache.share.container.prepareSharingController(
                rootRecord: record!, uniqueName: UUID().uuidString, shareTitle: shareTitle,
                participantLookupInfos: nil, database: MealLocalCache.share.database) { controller in
                    
                    if let popover = controller?.popoverPresentationController {
                        popover.barButtonItem = sender
                    }
                    
                    self.presentOrAlertOnMainQueue(sharingController: controller)
//                    controller?.popoverPresentationController?.sourceView = self.navigationItem.titleView
//                    controller?.delegate = self
//                    self.present(controller!, animated:true) {
//                        self.spinner.stopAnimating()
 //                    }
            }
        }
//        let participantLookupInfos = [CKUserIdentityLookupInfo(emailAddress: "willshan.ws@hotmail.com")]
//
//        let zoneIdURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: ICloudPropertyStore.keyForPrivateCustomZoneID)
//        let zoneID = NSKeyedUnarchiver.unarchiveObject(withFile: zoneIdURL.path) as? CKRecordZoneID
//        let shareID = CKRecordID(recordName: UUID().uuidString, zoneID: zoneID!)
//        var shareRecord = CKShare(rootRecord: record!, shareID: shareID)
//        shareRecord.publicPermission = .none
//
//        let participantLookupInfos = [CKUserIdentityLookupInfo(emailAddress: "willshan.ws@hotmail.com"),
//                                      CKUserIdentityLookupInfo(phoneNumber: "1234567890")]
//        self.addParticipants(to: shareRecord, lookupInfos: participantLookupInfos, operationQueue: operationQueue)
//
//        let sharingController = UICloudSharingController() {
//            (controller: UICloudSharingController,
//            prepareCompletionHandler : @escaping (CKShare?, CKContainer?, NSError?) -> Void) in
//            let modifyOp = CKModifyRecordsOperation(recordsToSave: [record!, shareRecord],
//                                                    recordIDsToDelete: nil)
//
//            modifyOp.modifyRecordsCompletionBlock = { (_, _, error) in
//                if error == nil {
//                    prepareCompletionHandler(shareRecord, DatabaseLocalCache.share.container, nil)
//                }
//            }
//            modifyOp.database = DatabaseLocalCache.share.privateDB
//            operationQueue.addOperation(modifyOp)
////            DatabaseLocalCache.share.privateDB.add(modifyOp)
//        }
//
////        sharingController.availablePermissions = [.allowPublic, .allowReadWrite]
//        sharingController.popoverPresentationController?.sourceView = self.navigationItem.titleView
//        sharingController.delegate = self
//        self.present(sharingController, animated:true) {
//            self.spinner.stopAnimating()
//        }
//
//        Option 2: get CKRecord from icloud and then share
//        let zoneIdURL = ICloudPropertyStore.URLofiCloudPropertyForKey(key: ICloudPropertyStore.keyForPrivateCustomZoneID)
//        let zoneID = NSKeyedUnarchiver.unarchiveObject(withFile: zoneIdURL.path) as? CKRecordZoneID
//        print("the zone id of current meal is \(String(describing: zoneID))")
//
//        let recordID = CKRecordID(recordName: meal.identifier, zoneID: zoneID!)
//
//        DatabaseLocalCache.share.privateDB.fetch(withRecordID: recordID, completionHandler: { (record, error) in
//            if error != nil {
//                // Insert error handling
//                print("Can't fetch record from icloud")
//            }
//            else {
//                //Creat Share
//                let shareRecord = CKShare(rootRecord: record!)
//                shareRecord[CKShareTitleKey] = "\(self.meal.mealName)" as CKRecordValue
//
//                let sharingController = UICloudSharingController() {
//                    (controller: UICloudSharingController,
//                    prepareCompletionHandler : @escaping (CKShare?, CKContainer?, NSError?) -> Void) in
//                    let modifyOp = CKModifyRecordsOperation(recordsToSave: [record!, shareRecord],
//                                                            recordIDsToDelete: nil)
//
//                    modifyOp.modifyRecordsCompletionBlock = { (_, _, error) in
//                        if error == nil {
//                            print("+++++++share successfully")
//                            prepareCompletionHandler(shareRecord, DatabaseLocalCache.share.container, nil)
//                        }
//                    }
//
//                    DatabaseLocalCache.share.privateDB.add(modifyOp)
//                }
//
//                sharingController.availablePermissions = [.allowPublic, .allowReadWrite]
//                sharingController.popoverPresentationController?.sourceView = self.navigationItem.titleView
//                sharingController.delegate = self
//                self.present(sharingController, animated:true) {
//                    self.spinner.stopAnimating()
//                }
//
//                //Save CKRecord
//
//            }
//        })//
    }
}

extension MealDetailVC {
    //MARK: -Segues
    //Add New Meal and show meal details
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case SegueID.editMealDetail:
            guard let nav = segue.destination as? UINavigationController,let detailMealVC = nav.topViewController as? EditMealVC else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            detailMealVC.meal = meal
            
            detailMealVC.photoFromOrderMeal = photoFromOrderMeal
            
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
    
}
