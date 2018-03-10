//
//  ShoppingCartViewController.swift
//  私家厨房
//
//  Created by Will.Shan on 02/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit

class ShoppingCartVC: UIViewController, UITableViewDelegate{

    @IBOutlet weak var firstTableView: UITableView!

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var catagoryLabel: UILabel!

    @IBAction func sentOut(_ sender: UIBarButtonItem) {
        saveToLocal()
    }
    
    @IBAction func saveMealList(_ sender: UIButton) {
    }
    
    @IBAction func cancelMealList(_ sender: UIButton) {
        cancelMealList()
    }
    
    
    var stateController : StateController!
    var dataSource: ShoppingCartDataSource!
    var shoppingCartList : ShoppingCartList?
    
    let dateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
        
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = editButtonItem
//        comment.delegate = self
//        //设置通知
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(keyboardWillChange(_:)),
//                                               name: .UIKeyboardWillChangeFrame, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)

        print("view appear in shoppingCart vc")
        
        //get date and catagory informaton from disk
        shoppingCartList = NSKeyedUnarchiver.unarchiveObject(withFile: ShoppingCartList.ArchiveURL.path) as? ShoppingCartList
        if shoppingCartList != nil
        {
            dateLabel.text = dateFormatter.string(from: shoppingCartList!.date)
            catagoryLabel.text = shoppingCartList!.mealCatagory ?? "晚餐"
        }
        else {
            print("++++++++shoppingCartList is nil")
        }
//        let dateFormatter : DateFormatter = {
//            let formatter = DateFormatter()
//            formatter.dateStyle = .none
//            formatter.timeStyle = .short
//            return formatter
//
//        }()
//
//        let time = NSDate()
//
//        let time1 = dateFormatter.string(from: time as Date!)
        
        dataSource = ShoppingCartDataSource(selectedMeals: stateController.getSelectedMeals())
        dataSource.shoppingCartController = self

        firstTableView.dataSource = dataSource
        firstTableView.delegate = dataSource

        firstTableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        print("+++++++++++shoppingCartVC will disappear")
    }

    override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
            // Dispose of any resources that can be recreated.
        }
//
//    deinit {
//        NotificationCenter.default.removeObserver(self)
//    }
}
extension ShoppingCartVC {
    func saveMealList() {
        
    }
    
    func cancelMealList() {
        
        let title = "删除已点菜单?"
        let message = "确认删除当前日期内所有菜品么?"
        let ac = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        ac.addAction(cancelAction)
        
        let deleteAction = UIAlertAction(title: "删除", style: .destructive, handler: {
            (action) -> Void in
            
            let meals = self.stateController.getSelectedMeals()
            for meal in meals {
                HandleCoreData.updateMealSelectionStatus(identifier: meal.identifier)
            }

            self.dataSource = ShoppingCartDataSource(selectedMeals: [Meal]())

            self.firstTableView.reloadData()
            
            //update shopping cart badge number
//            self.dataSource.updateShoppingCartIconBadgeNumber(orderedMealCount: 0)
            //find shopping cart badge
            let nav0 = self.navigationController
            let nav0TabBar = nav0?.tabBarItem
            nav0TabBar?.badgeValue = nil

        })
        ac.addAction(deleteAction)
        self.present(ac, animated: true, completion: nil)
    }
}
extension ShoppingCartVC : DataTransferBackProtocol{
    //MARK: -Actions
    @IBAction func selectMealCatagory(_ sender: UITapGestureRecognizer) {
        
        let storyBoard = UIStoryboard(name: StoryboardID.catagoryPopUpSB, bundle: nil)
        let popUpVC = storyBoard.instantiateInitialViewController()! as! CatagoryPopUpVC
        popUpVC.delegate = self
        popUpVC.catagory = ["早餐","午餐","晚餐"]
        
        self.present(popUpVC, animated: true)
    }
    
    func stringTransferBack(string: String) {
        catagoryLabel.text = string
        
        //save catagory label to disk
        //save datelabel to disk
        if shoppingCartList != nil {
            shoppingCartList?.mealCatagory = string
        }
        else {
            shoppingCartList = ShoppingCartList(date: Date(), mealCatagory: string, mealsIdentifiers: nil)
        }

        NSKeyedArchiver.archiveRootObject(shoppingCartList, toFile: ShoppingCartList.ArchiveURL.path)
        //save catagory label to icloud
        
    }

    @IBAction func selectDate(_ sender: UITapGestureRecognizer) {
        
        let storyBoard = UIStoryboard(name: StoryboardID.datePopUpSB, bundle: nil)
        let popUpVC = storyBoard.instantiateInitialViewController()! as! DatePopUpVC
        popUpVC.delegate = self
        
        self.present(popUpVC, animated: true)
    }
    
    func dateTransferBack(date: Date) {
        print("dataTransferBack was running")
        
        dateLabel.text = dateFormatter.string(from: date)
        
//        let dateFormatter : DateFormatter = {
//            let formatter = DateFormatter()
//            formatter.dateStyle = .medium
//            formatter.timeStyle = .none
//            return formatter
//
//        }()
        
//        //save datelabel to disk
        if shoppingCartList != nil {
            shoppingCartList?.date = date
        }
        else {
            shoppingCartList = ShoppingCartList(date: date, mealCatagory: nil, mealsIdentifiers: nil)
        }

        NSKeyedArchiver.archiveRootObject(shoppingCartList, toFile: ShoppingCartList.ArchiveURL.path)
        
        //save datelabel to icloud
        
    }
}

extension ShoppingCartVC : UITextViewDelegate{
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        if navigationItem.leftBarButtonItem?.title == "Edit" {
            firstTableView.setEditing(true, animated: false)
            navigationItem.leftBarButtonItem?.title = "Done"
        }
        else {
            firstTableView.setEditing(false, animated: false)
            navigationItem.leftBarButtonItem?.title = "Edit"
        }
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
    
//    //MARK: -Text and keyboard control
//    // 键盘改变，通过键盘出现的通知
//    @objc func keyboardWillChange(_ notification: Notification) {
//
//        if let userInfo = notification.userInfo,
//            let value = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue,
//            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double,
//            let curve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? UInt {
//
//            let frame = value.cgRectValue
//            let intersection = frame.intersection(self.view.frame)
//
//            //self.view.setNeedsLayout()
//            //改变上约束
//            self.topConstraint.constant = -intersection.height
//
//            UIView.animate(withDuration: duration, delay: 0.0,
//                           options: UIViewAnimationOptions(rawValue: curve), animations: {
//
//                            self.view.layoutIfNeeded()
//            }, completion: nil)
//        }
//    }
}

extension ShoppingCartVC {
    func saveToLocal() {
        //截屏
        
        let screenRect = UIScreen.main.bounds
        UIGraphicsBeginImageContext(screenRect.size)
        let ctx:CGContext = UIGraphicsGetCurrentContext()!
        self.view.layer.render(in: ctx)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        
        let activityController = UIActivityViewController(activityItems: [image as Any], applicationActivities: nil)
        
        self.present(activityController, animated: true)
//        保存相册
//        UIImageWriteToSavedPhotosAlbum(image!, self, #selector(image(image:didFinishSavingWithError:contextInfo:)), nil)
        
    }
    
    func image(image:UIImage,didFinishSavingWithError error:NSError?,contextInfo:AnyObject) {
        
        if error != nil {
            let title = "保存失败"
            let ac = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            ac.addAction(cancelAction)
        } else {
            let title = "保存成功"
            let ac = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
            let successAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            ac.addAction(successAction)
        }
    }
}


