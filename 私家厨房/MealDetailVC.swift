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

    var meal: Meal!
    var photoFromOrderMeal : UIImage!
    //var delegate : MealDataTransferDelegate?
    
    // Define icloudKit
    let myContainer = CKContainer.default()
    var privateDB : CKDatabase!
    var sharedDB : CKDatabase!
    

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
        
        self.privateDB = myContainer.privateCloudDatabase
        self.sharedDB = myContainer.sharedCloudDatabase
        
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
}

extension MealDetailVC : UICloudSharingControllerDelegate{
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        print("\(error)")
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        return meal.mealName
    }
    
    //MARK: -Actions
    //func editMeal(_ sender : UIBarButtonItem){
    @objc func editMeal(_ sender : UIBarButtonItem){
        print("edit func was performed")
        
        UIView.animate(withDuration: 0.3) {
            self.performSegue(withIdentifier: SegueID.editMealDetail, sender: nil)
        }
        //}
    }
    
    //MARK: Init sharing view controller
    @objc func shareWithFamilyMember(_ sender : UIBarButtonItem) {
        print("init sharing")
        
        let zoneIdURL = ICloudPropertyStore.iCloudProtpertyForKey(key: "zoneID_Meals")
        let zoneID = NSKeyedUnarchiver.unarchiveObject(withFile: zoneIdURL.path) as? CKRecordZoneID
        print("the zone id of current meal is \(String(describing: zoneID))")
        
        let recordID = CKRecordID(recordName: meal.identifier, zoneID: zoneID!)
        print("zone id is \(String(describing: zoneID))")
        privateDB.fetch(withRecordID: recordID, completionHandler: { (record, error) in
            if error != nil {
                // Insert error handling
                print("Can't fetch record from icloud")
            }
            else {
                //Creat Share
                let shareRecord = CKShare(rootRecord: record!)
//                shareRecord[CKShareTitleKey] = "\(self.meal.mealName)" as CKRecordValue
                
                
                let sharingController = UICloudSharingController() {
                    (controller: UICloudSharingController,
                    prepareCompletionHandler : @escaping (CKShare?, CKContainer?, NSError?) -> Void) in
                    let modifyOp = CKModifyRecordsOperation(recordsToSave: [record!, shareRecord],
                                                            recordIDsToDelete: nil)
                    
                    modifyOp.modifyRecordsCompletionBlock = { (_, _, error) in
                        if error == nil {
                            prepareCompletionHandler(shareRecord, self.myContainer, nil)
                        }
                    }
                    
                    self.myContainer.privateCloudDatabase.add(modifyOp)
                }
                                                                 
                sharingController.availablePermissions = [.allowPublic, .allowReadWrite]
                sharingController.popoverPresentationController?.sourceView = self.navigationItem.titleView
                sharingController.delegate = self
                self.present(sharingController, animated:true, completion:nil)
                
                //Save CKRecord

            }
        })
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
