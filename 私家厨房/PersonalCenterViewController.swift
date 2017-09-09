//
//  PersonalCenterViewController.swift
//  私家厨房
//
//  Created by Will.Shan on 16/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit
import CoreData
import os.log


class PersonalCenterViewController: UIViewController {
    //Mark: -Properties
    var stateController : StateController!
    let userName : String? = UserDefaults.standard.string(forKey: "user_name")
    
    @IBOutlet weak var personalPhoto: UIImageView!
    
    
    @IBAction func goToContactVC(_ sender: Any) {

        let contactVC = ContactVC()
        self.navigationController?.pushViewController(contactVC, animated: true)
    }
    
    //var stateController = StateController(MealStorage())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //添加聊天管理代理
        EMClient.shared().chatManager.add(self, delegateQueue: nil)
        //personalPhoto.image = ImageStore().imageForKey(key: PFUser.current()!.username!) ?? UIImage(named: "defaultPhoto")!
        
        personalPhoto.image = ImageStore().imageForKey(key: userName!) ?? UIImage(named: "defaultPhoto")!
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
extension PersonalCenterViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK: -UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Dismiss the picker if the user canceled.
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // The info dictionary may contain multiple representations of the image. You want to use the original.
        guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        //Compress photo quality to decrease disk size.
        let resizeImage = AppImageHelper.resizeImage(originalImg: selectedImage)
        
        let compressedImageData = AppImageHelper.compressImageSize(image: resizeImage)
        
        let compressedImage = UIImage(data: compressedImageData)
        // Set photoImageView to display the selected image.
        //photo.image = selectedImage

        personalPhoto.image = compressedImage
        ImageStore().setImage(image: compressedImage!, forKey: userName!)
        
        // Dismiss the picker.
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func selectImageFromPhotoLibrary(_ sender: UITapGestureRecognizer) {
    
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        
        // Allow photos to be picked
        imagePickerController.sourceType = .photoLibrary
        
        // Make sure ViewController is notified when the user picks an image.
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
}

extension PersonalCenterViewController {
    //MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
        case "MyOrderList":
            guard let orderListCenterController = segue.destination as? OrderListCenterController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            orderListCenterController.orderList = stateController.loadOrderList()
            
            print("即将传递数据到orderListCenter")
            print("传递的数据为\(String(describing: orderListCenterController.orderList))")
            
        case "PersonalSet":
            os_log("Adding a new meal.", log: OSLog.default, type: .debug)
           
        case "invitationSegue":
            guard let invitationVC = segue.destination as? InvitationVC else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            //invitationVC.meals = stateController.meals
            
        case "LogOut":
            print("Will transport to logOut page")
            
        case "loadFamilyMealListSegue":
            guard let loadMealVC = segue.destination as? LoadFamilyMealListVC else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            loadMealVC.stateController = stateController
            print("Will transport to loading page")
            
            
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
    
    //unwindSegue from orderList
    @IBAction func exit(sender : UIStoryboardSegue){
        let sourceViewController = sender.source as? OrderListViewController
        let mealListBySections = sourceViewController?.mealListBySections
		//将刚刚下的订单加入到历史订单中
        stateController.addOrderList((sourceViewController?.orderTime.text)!, mealListBySections!, (sourceViewController?.photosIdentifiers)!)
		//将购物车中的内容清空
        stateController.removeMealOrderList()
        //将菜单中的按钮全变为“加入菜单”
        for meal in stateController.meals! {
            meal.cellSelected = false
        }
        print("Link to personal center")
        //将图标数量设为nil
        let nav3 = self.navigationController
        //let tabNav = UITabBarController()
        let tabNav = nav3?.tabBarController
        let nav1 = tabNav?.viewControllers?[1]
        nav1?.tabBarItem.badgeValue = nil
    }
}

//MARK: -监听消息列表
extension PersonalCenterViewController : EMChatManagerDelegate{
    func conversationListDidUpdate(_ aConversationList: [Any]!) {
        self.showTabBarBadge()
    }
    
    func messagesDidReceive(_ aMessages: [Any]!) {
        self.showTabBarBadge()
    }
    
    func showTabBarBadge() {
        /*
        let conversations = EMClient.shared().chatManager.getAllConversations() as? [EMConversation]
        var unreadMessageCount = 0
        if conversations != nil {
            for conv in conversations! {
                unreadMessageCount += Int(conv.unreadMessagesCount)
            }
            let nav3 = self.navigationController
            let tabNav = nav3?.tabBarController
            let nav2 = tabNav?.viewControllers?[2]
            
            if unreadMessageCount == 0 {
                nav2?.tabBarItem.badgeValue = nil
            }
            else {
                
                nav2?.tabBarItem.badgeValue = "\(unreadMessageCount)"
            }
        }*/
        
        let conversations = EMClient.shared().chatManager.getAllConversations() as! [EMConversation]
        var unreadMessageCount = 0
        for conv in conversations {
            unreadMessageCount += Int(conv.unreadMessagesCount)
        }
        let nav3 = self.navigationController
        let tabNav = nav3?.tabBarController
        let nav2 = tabNav?.viewControllers?[2]
        
        if unreadMessageCount == 0 {
            nav2?.tabBarItem.badgeValue = nil
        }
        else {
            
            nav2?.tabBarItem.badgeValue = "\(unreadMessageCount)"
        }
    }
}
