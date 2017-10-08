//
//  LoadFamilyMealListVC.swift
//  私家厨房
//
//  Created by Will.Shan on 07/09/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit

class LoadFamilyMealListVC: UIViewController {

    //MARK: -Properties
    //var meals : [Meal]!
    var stateController : StateController!
    
    @IBOutlet weak var invitationCode: UITextField!
    @IBOutlet weak var loadFamlilyMealList: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        navigationItem.title = "载入家庭菜单"
        updateButtonState()
        invitationCode.delegate = self
        
        //print(meals.first)
        //loadFamlilyMealList.addTarget(self, action: #selector(loadFamlilyMealList(_:)), for: .touchUpInside)
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension LoadFamilyMealListVC : UITextFieldDelegate{
    
    //MARK: UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Disable the Save button while editing.
        //loadFamlilyMealList.isEnabled = true
 
        loadFamlilyMealList.isEnabled = false

    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        updateButtonState()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateButtonState()
    }
    
    @IBAction func dismissKeyBoard(_ sender: UITapGestureRecognizer){
        invitationCode.resignFirstResponder()
        //updateButtonState()
    }
    
    fileprivate func updateButtonState() {
        // Disable the Save button if the text field is empty.
        let text = invitationCode.text ?? ""
        loadFamlilyMealList.isEnabled = !text.isEmpty
    }
    /*
    func loadFamlilyMealList(_ sender: UIButton) {
        loadFamlilyMealList.isEnabled = false
        invitationCode.isEnabled = false
        
        let query = MealToServer.query()
        
        query?.findObjectsInBackground { [unowned self] objects, error in
            guard let objects = objects as? [MealToServer]
                else {
                    self.showErrorView(error)
                    return
            }
            //download from server
            for object in objects {
                if object.invitationCode == self.invitationCode.text! {
                    //如果identifier相同，则不变，否则则添加
                    
                    let userName : String? = UserDefaults.standard.string(forKey: "user_name")
                    //queryDataWithIdentiferAndUser(_ userName : String, _ identifier : String)
                    print("注意了\(HandleCoreData.queryDataWithIdentiferAndUser(userName!,object.identifier)?.count)")
                    if HandleCoreData.queryDataWithIdentiferAndUser(userName!,object.identifier)?.count == 0{
                        
                        //添加数据到coreData
                        let meal = HandleCoreData.insertData(mealToServer: object, meal: nil)
                        print("***the identifier for the meal is \(String(describing: meal.identifier))")
                        
                        //添加到stateController
                        self.stateController.addMeal(meal)
                        
                        object.photo?.getDataInBackground { [unowned self] data, error in
                            guard let data = data,
                                let image = UIImage(data: data) else {
                                    return
                            }
                            //添加图片到Disk
                            ImageStore().setImage(image: image, forKey: meal.identifier)
                            
                            //从服务器删除
                            //object.deleteInBackground()
                            object.deleteInBackground { [unowned self] succeeded, error in
                                if succeeded {
                                    print("***Deleted in server successfully01***")
                                } else if let error = error {
                                    self.showErrorView(error)
                                    print("***failed to delete in server***")
                                }
                                
                            }
                        }
                    }
                    else {
                        //从服务器删除
                        //object.deleteInBackground()
                        
                        object.deleteInBackground { [unowned self] succeeded, error in
                            if succeeded {
                                print("***Deleted in server successfully02***")
                            } else if let error = error {
                                self.showErrorView(error)
                                print("***failed to delete in server***")
                            }
                        }

                    }
                }
            }
        }
    }*/
}
