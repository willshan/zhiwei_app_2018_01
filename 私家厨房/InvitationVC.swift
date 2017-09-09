//
//  InvitationVC.swift
//  私家厨房
//
//  Created by Will.Shan on 26/08/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit

class InvitationVC: UIViewController {

    //MARK: -Properties
    //var meals : [Meal]!
    
    @IBOutlet weak var invitationCode: UITextView!
    @IBOutlet weak var generateButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        //print(meals.first)
        generateButton.addTarget(self, action: #selector(generateInvitationCode(_:)), for: .touchUpInside)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension InvitationVC {
    func generateInvitationCode(_ sender: UIButton) {
        generateButton.isEnabled = false
        
        let userName : String? = UserDefaults.standard.string(forKey: "user_name")
        
        let code = InvitationCodeStorage().invitationCodeForKey(key: "invitationCode", userName : userName!)
        if code != nil {
            invitationCode.text = code
        }
        else {
            invitationCode.text = HandleCoreData.RandomString()
            InvitationCodeStorage().saveInvitaionCode(code: invitationCode.text!, forKey: "invitationCode", userName : userName!)
        }
        
        //向服务器上传菜
        let meals = HandleCoreData.queryData(userName!)
        
        //example
        for meal in meals {
            let image = ImageStore().imageForKey(key: meal.identifier)
            
            let pictureData = UIImagePNGRepresentation(image!)
            let file = PFFile(name: "photo", data: pictureData!)
            
            let mealToShare = MealToServer(mealname: meal.mealName, photo: file, spicy: Int(meal.spicy), comment: meal.comment, mealType: meal.mealType, userName: userName!, date: meal.date!, identifier : meal.identifier, invitationCode : invitationCode.text)
            
            //先删除可能已经存在的
            MealToServer.query()?.getObjectInBackground(withId: meal.objectIDinServer!) { [unowned self] object, error in
                if error == nil {
                    let mealToServer = object as? MealToServer
                    print("服务器有这道菜\(meal.identifier)")
                    mealToServer?.deleteInBackground { [unowned self] succeeded, error in
                        if succeeded {
                            print("***Deleted in server successfully***")
                            //再将现有的上传上去
                            mealToShare!.saveInBackground { [unowned self] succeeded, error in
                                if succeeded {
                                    HandleCoreData.updateObjectIDinServer(identifier : mealToShare!.identifier, objectIDinServer : mealToShare!.objectId!)
                                    print("***共享上传成功\(meal.identifier)***")
                                } else if let error = error {
                                    self.showErrorView(error)
                                    print("***共享上传失败***")
                                }
                            }
                        } else if let error = error {
                            self.showErrorView(error)
                            print("***failed to delete in server***")
                        }
                    }
                }
                else {
                    print("服务器中目前没有这道菜\(meal.identifier)")
                    //再将现有的上传上去
                    mealToShare!.saveInBackground { [unowned self] succeeded, error in
                        if succeeded {
                            HandleCoreData.updateObjectIDinServer(identifier : mealToShare!.identifier, objectIDinServer : mealToShare!.objectId!)
                            print("***共享上传成功\(meal.identifier)***")
                        } else if let error = error {
                            self.showErrorView(error)
                            print("***共享上传失败***")
                        }
                    }
                }
            }
        }
    }
}
