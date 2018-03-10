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
import CloudKit

class PersonalCenterVC: UIViewController {
    //Mark: -Properties
    var stateController : StateController!
    let userName : String = CKCurrentUserDefaultName
    
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    @IBOutlet weak var button4: UIButton!
    @IBOutlet weak var buttonHeight: NSLayoutConstraint!
    @IBOutlet weak var buttonWidth: NSLayoutConstraint!
    @IBOutlet weak var personalPhoto: UIImageView!


    override func viewDidLoad() {
        super.viewDidLoad()
        let screenWidth = UIScreen.main.bounds.width
        buttonHeight.constant = (screenWidth - 50)/4
        buttonWidth.constant = buttonHeight.constant
        button1.layer.cornerRadius = buttonWidth.constant/2
        button2.layer.cornerRadius = buttonWidth.constant/2
        button3.layer.cornerRadius = buttonWidth.constant/2
        button4.layer.cornerRadius = buttonWidth.constant/2
        
        personalPhoto.image = DataStore().getImageForKey(key: userName) ?? UIImage(named: AssetNames.defaultPhoto)!
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
extension PersonalCenterVC : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
        let resizeImage = ImageHelper.resizeImage(originalImg: selectedImage)
        
        let compressedImageData = ImageHelper.compressImageSize(image: resizeImage)
        
        let compressedImage = UIImage(data: compressedImageData)
        // Set photoImageView to display the selected image.
        //photo.image = selectedImage

        personalPhoto.image = compressedImage
        DataStore().saveImageInDisk(image: compressedImage!, forKey: userName)
        
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

extension PersonalCenterVC {
    //MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
        case SegueID.showOrderListDetail:
            guard let orderListCenterController = segue.destination as? OrderListCenterVC else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            orderListCenterController.orderList = stateController.loadOrderList()
            
            print("即将传递数据到orderListCenter")
            print("传递的数据为\(String(describing: orderListCenterController.orderList))")
           
        case SegueID.showFamilyList:
            print("Show family list")
            
        case SegueID.personalSet:
            os_log("Adding a new meal.", log: OSLog.default, type: .debug)
           
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
    
    //unwindSegue from orderList
    @IBAction func exit(sender : UIStoryboardSegue){
        let sourceViewController = sender.source as? OrderListVC
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


