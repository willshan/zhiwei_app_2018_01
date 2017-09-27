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

class DetailMealViewController: UIViewController {
    
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
    @IBOutlet weak var pickerView : UIPickerView!
    
    var meal: Meal?
    var photoFromOrderMeal : UIImage?
    var photochanged : Bool = false
    var mealShouldSaveInServer = false
    //var photoFile : PFFile!
    let user = PFUser.current()
    
    let mealTypeAsset = ["凉菜","热菜","汤","酒水"]
    
    let dateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
        
    }()
}

extension DetailMealViewController : UITextFieldDelegate, UITextViewDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIPickerViewDelegate, UIPickerViewDataSource {
    //MARK: -LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        //设置通知
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(DetailMealViewController.keyboardWillChange(_:)),
                                               name: .UIKeyboardWillChangeFrame, object: nil)
        // Handle the text field’s user input through delegate callbacks.
        mealName.delegate = self
        comment.delegate = self
        pickerView.delegate = self
        pickerView.dataSource = self

        // Set up views if editing an existing Meal.
        if let meal = meal {
            navigationItem.title = meal.mealName
            mealName.text = meal.mealName
            spicy.spicy = Int(meal.spicy)
            date.text = dateFormatter.string(from: meal.date! as Date)
            comment.text = meal.comment
            photo.image = photoFromOrderMeal
            mealType.text = meal.mealType
            
        }
        
        // Enable the Save button only if the text field has a valid Meal name.
        updateSaveButtonState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if mealType.text != "点击选择" {
            mealType.backgroundColor = UIColor.white
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        //saveMealsToServer()
    }
}

extension DetailMealViewController {
    //MARK: -Text and keyboard control
    // 键盘改变，通过键盘出现的通知
    func keyboardWillChange(_ notification: Notification) {
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
                                _ in
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
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButtonState()
        navigationItem.title = textField.text
    }
    
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
        let compressedImage = AppImageHelper.resizeImage(originalImg: selectedImage)
        //let compressedImageData = UIImageJPEGRepresentation(compressedImage, 0.4)
        let compressedImageData = AppImageHelper.compressImageSize(image: compressedImage)

        //0.1 缩小20倍
        //0.3
        /*
        let test1 = UIImageJPEGRepresentation(compressedImage, 1)
        let test2 = UIImageJPEGRepresentation(compressedImage, 0.9)
        let test3 = UIImageJPEGRepresentation(compressedImage, 0.8)
        let test4 = UIImageJPEGRepresentation(compressedImage, 0.7)
        let test5 = UIImageJPEGRepresentation(compressedImage, 0.6)
        let test6 = UIImageJPEGRepresentation(compressedImage, 0.5)
        let test7 = UIImageJPEGRepresentation(compressedImage, 0.4)
        let test8 = UIImageJPEGRepresentation(compressedImage, 0.3)
        let test9 = UIImageJPEGRepresentation(compressedImage, 0.2)
        let test10 = UIImageJPEGRepresentation(compressedImage, 0.1)
        let test11 = UIImageJPEGRepresentation(compressedImage, 0.01)
        */
        
        let finalCompressedImage = UIImage(data: compressedImageData)

        print("photo size is \(compressedImageData)")
    
        /*
        print("原图压缩1后为 \(test1)")
        print("原图压缩0.9后为 \(test2)")
        print("原图压缩0.8后为 \(test3)")
        print("原图压缩0.7后为 \(test4)")
        print("原图压缩0.6后为 \(test5)")
        print("原图压缩0.5后为 \(test6)")
        print("原图压缩0.4后为 \(test7)")
        print("原图压缩0.3后为 \(test8)")
        print("原图压缩0.2后为 \(test9)")
        print("原图压缩0.1后为 \(test10)")
        print("原图压缩0.01后为 \(test11)")
         */
        
        
        // Set photoImageView to display the selected image.
        photo.image = finalCompressedImage
        photoFromOrderMeal = finalCompressedImage
        
        // Dismiss the picker.
        dismiss(animated: true, completion: nil)
    }
}
extension DetailMealViewController{
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
        
        /*guard let uploadImage = self.photo.image,
            let pictureData = UIImagePNGRepresentation(uploadImage),
            let file = PFFile(name: "photo", data: pictureData) else {
                return
        }*/
        photoFromOrderMeal = self.photo.image
        
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
            mealToAdd.objectIDinServer = "TBD"
            mealToAdd.userName = user?.username
            mealToAdd.identifier = HandleCoreData.RandomString()
            
            /*
            let userName : String? = UserDefaults.standard.string(forKey: "user_name")
            
            let code = InvitationCodeStorage().invitationCodeForKey(key: "invitationCode", userName: userName!)
            if code != nil {
                mealToAdd.invitationCode = code
            }
            else {
                mealToAdd.invitationCode = HandleCoreData.RandomString()
                InvitationCodeStorage().saveInvitaionCode(code: mealToAdd.invitationCode!, forKey: "invitationCode", userName: userName!)
            }*/
            
            print("待保存的meal的识别号为：\(String(describing: mealToAdd.identifier))")
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
            
            HandleCoreData.updateData(self.meal!)
        }
        if self.photoFromOrderMeal != photo.image {
            photochanged = true
        }
        print("prepare for segue in DetailMealVC")
    }
}

extension DetailMealViewController{
    //MARK: -UIPickView
    //设置选择框的列数为1列,继承于UIPickerViewDataSource协议
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    //设置选择框的行数为3行，继承于UIPickerViewDataSource协议
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return mealTypeAsset.count
    }
    //设置选择框各选项的内容，继承于UIPickerViewDelegate协议
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int,
                    forComponent component: Int) -> String? {
        
        return mealTypeAsset[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        mealType.text = mealTypeAsset[row]
        
        self.pickerView.isHidden = true
        mealType.backgroundColor = UIColor.white
        updateSaveButtonState()
    }
    
    fileprivate func updateSaveButtonState() {
        // Disable the Save button if the text field is empty.
        let text = mealName.text ?? ""
        saveButton.isEnabled = !text.isEmpty && mealType.text != "点击选择"
    }
}

extension DetailMealViewController{
    //MARK: -Actions
    @IBAction func getPickerViewValue(_ sender: UITapGestureRecognizer){
        mealName.resignFirstResponder()
        print("taped the label")
        self.pickerView.isHidden = false
        
    }
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
}
