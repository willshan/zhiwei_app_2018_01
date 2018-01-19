//
//  DetailMealViewController.swift
//  私家厨房
//
//  Created by Will.Shan on 08/03/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit
import os.log
import CoreData
import CloudKit

class EditMealVC: UIViewController {
    
    //MARK: -Properties
    @IBOutlet weak var mealName: UITextField!
    @IBOutlet weak var spicy: Spicy!
    @IBOutlet weak var date: UILabel!

    @IBOutlet weak var comment: UITextView!
    //stackView的上约束
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var mealType: UILabel!
    @IBAction func selectMealCatagory(_ sender: UITapGestureRecognizer) {
        mealName.resignFirstResponder()
        let storyBoard = UIStoryboard(name: "CatagoryPopUpSB", bundle: nil)
        let popUpVC = storyBoard.instantiateInitialViewController()! as! CatagoryPopUpVC
        popUpVC.delegate = self
        popUpVC.catagory = ["凉菜","热菜","汤","酒水"]
        
        self.present(popUpVC, animated: true)
    }
    
    
    var meal: Meal?
    var photoFromOrderMeal : UIImage?
    var photochanged : Bool = false
    var mealShouldSaveInServer = false
    //var photoFile : PFFile!
    //let user = PFUser.current()
    
    let mealTypeAsset = ["凉菜","热菜","汤","酒水"]
    
    let dateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
        
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

extension EditMealVC : UITextFieldDelegate, UITextViewDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //MARK: -LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        //设置通知
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(EditMealVC.keyboardWillChange(_:)),
                                               name: .UIKeyboardWillChangeFrame, object: nil)
        // Handle the text field’s user input through delegate callbacks.
        mealName.delegate = self
        comment.delegate = self
        
        // Set up views if editing an existing Meal.
        if let meal = meal {
            navigationItem.title = meal.mealName
            mealName.text = meal.mealName
            spicy.spicy = Int(meal.spicy)
            date.text = dateFormatter.string(from: meal.date as Date)
            comment.text = meal.comment
            photo.image = photoFromOrderMeal
            mealType.text = meal.mealType
        }
        
        // Enable the Save button only if the text field has a valid Meal name.
        updateSaveButtonState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        print("will will appear")
        if mealType.text != "点击选择" {
            mealType.backgroundColor = UIColor.white
        }
        updateSaveButtonState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        dismissKeyBoard()
        //saveMealsToServer()
    }
}

extension EditMealVC : DataTransferBackProtocol {
    func stringTransferBack(string: String) {
        self.mealType.text = string
        updateSaveButtonState()
    }
}

extension EditMealVC {
    //MARK: -Text and keyboard control
    // 键盘改变，通过键盘出现的通知
    @objc func keyboardWillChange(_ notification: Notification) {
        if mealName.isEditing {
            return
        }
            
        else{
            if let userInfo = notification.userInfo,
                let value = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue,
                let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double,
                let curve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? UInt {
                
                let frame = value.cgRectValue
                let intersection = frame.intersection(self.view.frame)
                
                //self.view.setNeedsLayout()
                //改变上约束
                self.topConstraint.constant = -intersection.height
                
                UIView.animate(withDuration: duration, delay: 0.0,
                               options: UIViewAnimationOptions(rawValue: curve), animations: {
                                
                                self.view.layoutIfNeeded()
                }, completion: nil)
            }
        }
    }
    
    //MARK: UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Disable the Save button while editing.
        saveButton.isEnabled = false
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func dismissKeyBoard(_ sender: UITapGestureRecognizer){
        comment.resignFirstResponder()
        mealName.resignFirstResponder()
        updateSaveButtonState()
        
    }
    func dismissKeyBoard() {
        comment.resignFirstResponder()
        mealName.resignFirstResponder()
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        navigationItem.title = textField.text
        updateSaveButtonState()
    }
    
    //MARK: UITextViewDelegate
//    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        if text == "\n" {
//            comment.resignFirstResponder()
//            return false
//        }
//        else {
//            return true
//        }
//    }
    
    //MARK: UIImagePickerControllerDelegate
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
        let compressedImage = ImageHelper.resizeImage(originalImg: selectedImage)
        //let compressedImageData = UIImageJPEGRepresentation(compressedImage, 0.4)
        let compressedImageData = ImageHelper.compressImageSize(image: compressedImage)
        let finalCompressedImage = UIImage(data: compressedImageData)

        // Set photoImageView to display the selected image.
        photo.image = finalCompressedImage

        // Dismiss the picker.
        dismiss(animated: true, completion: nil)
    }
}
extension EditMealVC{
    //MARK: -Segues
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        // Configure the destination view controller only when the save button is pressed.
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
        
        mealShouldSaveInServer = true
        
        let name = mealName.text ?? ""
        let spicy = self.spicy.spicy
        let comment = self.comment.text
        let mealType = self.mealType.text
        let date = self.meal?.date ?? NSDate()
        
        // Set the meal to be passed to MealTableViewController after the unwind segue.
        //meal.cellSelected = false
        if self.meal == nil {
            let EntityName = "Meal"
            let mealToAdd = NSEntityDescription.insertNewObject(forEntityName: EntityName, into:HandleCoreData.context) as! Meal
            mealToAdd.cellSelected = false
            mealToAdd.mealName = name
            mealToAdd.comment = comment
            mealToAdd.date = date
            mealToAdd.mealType = mealType!
            mealToAdd.spicy = Int64(spicy)
            mealToAdd.userName = CKCurrentUserDefaultName
            
            //mealToAdd.identifier = HandleCoreData.RandomString()
            mealToAdd.identifier = "notAssigned"
            print("the user of the meal is \(mealToAdd.userName)")
            print("the identifer of the meal is \(mealToAdd.identifier)")

            self.meal = mealToAdd
            //测试HandleCoreData不会占用app太长时间
            HandleCoreData.saveContext()
        }
        else {
            self.meal!.cellSelected = false
            self.meal!.mealName = name
            self.meal!.comment = comment
            self.meal!.mealType = mealType!
            self.meal!.spicy = Int64(spicy)
            
            HandleCoreData.updateData(meal: self.meal, record: nil)
        }
        if self.photoFromOrderMeal != photo.image {
            photochanged = true
            photoFromOrderMeal = self.photo.image
        }
        print("prepare for segue in DetailMealVC")
    }
}

extension EditMealVC{
    //MARK: -Actions
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        dismiss(animated: true, completion: nil)
        /*let isPresentingInAddMealMode = presentingViewController is UINavigationController
        if isPresentingInAddMealMode {
            dismiss(animated: true, completion: nil)
        }*/
        //如果是Navigation的形式，则释放popViewController
        if let owningNavigationController = navigationController{
            owningNavigationController.popViewController(animated: true)
        }
        else {
            fatalError("The MealViewController is not inside a navigation controller.")
        }
    }
    
    @IBAction func selectImageFromPhotoLibrary(_ sender: UITapGestureRecognizer) {
        // Hide the keyboard.
        mealName.resignFirstResponder()
        
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()

        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        
        let useCamera = UIAlertAction(title: "拍照", style: .destructive, handler: {
            (action) -> Void in
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true, completion: nil)
        })
        
        let usePhotoLibrary = UIAlertAction(title: "本地相册", style: .destructive, handler: {
            (action) -> Void in
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        })

        ac.addAction(cancelAction)
        ac.addAction(useCamera)
        ac.addAction(usePhotoLibrary)
        
        self.present(ac, animated: true, completion: nil)
        
        // Make sure ViewController is notified when the user picks an image.
        imagePickerController.delegate = self
        //present(imagePickerController, animated: true, completion: nil)
    }
    
    fileprivate func updateSaveButtonState() {
        // Disable the Save button if the text field is empty.
        let text = mealName.text ?? ""
        saveButton.isEnabled = !text.isEmpty && mealType.text != "点击选择"
    }
}
