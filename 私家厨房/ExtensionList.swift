
import UIKit
import CloudKit

// Use the TableView style name as the reusable ID.
// For a custom cell, use the class name.


//
extension UIViewController {
    func showErrorView(_ error: Error?) {
        guard let error = error as NSError?, let errorMessage = error.userInfo["error"] as? String else {
            return
        }
        
        let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""),
                                                message: errorMessage,
                                                preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""),
                                                style: .default))
        
        present(alertController, animated: true)
    }
}

/*
class SpinnerViewController: UITableViewController {
    
    lazy var spinner: UIActivityIndicatorView = {
        return UIActivityIndicatorView(activityIndicatorStyle: .gray)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        tableView.addSubview(spinner)
        tableView.bringSubview(toFront: spinner)
        spinner.hidesWhenStopped = true
        spinner.color = .blue
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        spinner.center = CGPoint(x: tableView.frame.size.width / 2, y: tableView.frame.size.height / 2 - 88)
    }
    
    func alertCacheUpdating() {
        let alert = UIAlertController(title: "Local cache is updating.",
                                      message: "Try again after the update is done.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        present(alert, animated: true)
        
        // Automatically dismiss after 1.5 second.
        //
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5){
            alert.dismiss(animated: true, completion: nil)
        }
    }
}

class ShareViewController: SpinnerViewController, UICloudSharingControllerDelegate {
    
    // Clients should set this before presenting UICloudSharingCloudller (presentOrAlertOnMainQueue)
    // so that delegate method can access info in the root record.
    //
    var rootRecord: CKRecord?
    
    func presentOrAlertOnMainQueue(sharingController: UICloudSharingController?) {
        
        if let sharingController = sharingController {
            DispatchQueue.main.async {
                sharingController.delegate = self
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
    
    func alertZoneDeleted(completionHandler: (()->Void)? = nil) {
        
        let alert = UIAlertController(title: "The current zone was deleted.",
                                      message: "Switching to the default zone of the private database.",
                                      preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {_ in
            
            // Stopping the last share in a zone seems to trigger two notifications. So at the moment when
            // the user taps OK, the cache may have been updated, so have a check here.
            //
            if TopicLocalCache.share.database.databaseScope != .private ||
                TopicLocalCache.share.zone.zoneID != CKRecordZone.default().zoneID {
                
                self.spinner.startAnimating()
                DispatchQueue.global().async {
                    TopicLocalCache.share.switchZone(newDatabase: TopicLocalCache.share.container.privateCloudDatabase,
                                                     newZone: CKRecordZone.default())
                }
            }
            if let completionHandler = completionHandler { completionHandler() }
            
            // After the local cache is updated, another notification will come to update the UI.
        })
        present(alert, animated: true)
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        guard let record = rootRecord else {return nil}
        
        if record.recordType == Schema.RecordType.topic {
            return record[Schema.Topic.name] as? String
        }
        else {
            return record[Schema.Note.title] as? String
        }
    }
    
    // When a topic is shared successfully, this method is called, the CKShare should have been created,
    // and the whole share hierarchy should have been updated in server side. So fetch the changes and
    // update the local cache.
    //
    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        TopicLocalCache.share.fetchChanges()
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
        //
        if TopicLocalCache.share.database.databaseScope == .shared, let record = rootRecord {
            
            TopicLocalCache.share.deleteCachedRecord(record)
            
            if TopicLocalCache.share.topics.count == 0, TopicLocalCache.share.orphanNoteTopic.notes.count == 0,
                TopicLocalCache.share.database.databaseScope == .shared {
            
                if let index = ZoneLocalCache.share.databases.index(where: {$0.cloudKitDB.databaseScope == .shared}) {
                    ZoneLocalCache.share.deleteCachedZone(TopicLocalCache.share.zone,
                                                          database: ZoneLocalCache.share.databases[index])
                }
            }
        }
        TopicLocalCache.share.fetchChanges() // Zone might not exist, which will trigger zone switching.
    }
    
    // Failing to save a share, show an alert and refersh the cache to avoid inconsistent status.
    //
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        
        // Use error message directly for better debugging the error.
        //
        let alert = UIAlertController(title: "Failed to save a share.",
                                      message: "\(error) ", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true) {
            self.spinner.stopAnimating()
        }
        
        // Fetch the root record from server and upate the rootRecord sliently.
        // .fetchChanges doesn't return anything here, so fetch with the recordID.
        //
        if let rootRecordID = rootRecord?.recordID {
            TopicLocalCache.share.update(withRecordID: rootRecordID)
        }
    }
}
*/
