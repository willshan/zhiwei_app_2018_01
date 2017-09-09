//
//  SignUpViewController.swift
//  ParseDemo
//
//  Created by Rumiya Murtazina on 7/30/15.
//  Copyright (c) 2015 abearablecode. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    //@IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var emailField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
private extension SignUpViewController{
    //MARK: -Hide keyboard
    private func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func dismissKeyBoard(_ sender: UITapGestureRecognizer){
        usernameField.resignFirstResponder()
        passwordField.resignFirstResponder()
        emailField.resignFirstResponder()
        
    }
    @IBAction func dismissKeyBoard2(_ sender: UITapGestureRecognizer){
        usernameField.resignFirstResponder()
        passwordField.resignFirstResponder()
        emailField.resignFirstResponder()
    }
    func dismissKeyBoard3(){
        usernameField.resignFirstResponder()
        passwordField.resignFirstResponder()
    }
}

private extension SignUpViewController{
    @IBAction func signUpAction(_ sender: AnyObject) {
        
        //let username = usernameField.text
        //let password = passwordField.text
        //let email = emailField.text
        //var finalEmail = email.stringByTrimmingCharactersInSet(CharacterSet.whitespaceCharacterSet())
        //let finalEmail = email?.trimmingCharacters(in: CharacterSet.whitespaces)
        
        let newUser = PFUser()
        newUser.username = usernameField.text
        newUser.password = passwordField.text
        newUser.email = emailField.text
        
        if (usernameField.text?.characters.count)! < 5 {
            let alert = UIAlertController(title: "Invalid", message: "Username must be greater than 5 characters", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            
        } else if (passwordField.text?.characters.count)! < 8 {
            let alert = UIAlertController(title: "Invalid", message: "Password must be greater than 8 characters", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            
        } else if (emailField.text?.characters.count)! < 8 {
            let alert = UIAlertController(title: "Invalid", message: "Please enter a valid email address", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            
        } else {
        
        //newUser.email = finalEmail
        newUser.signUpInBackground { [unowned self] succeeded, error in
            guard succeeded == true else {
                self.showErrorView(error)
                return
            }
            // Successful registration, display the wall
            UserDefaults.standard.set(newUser.username, forKey: "user_name")
            UserDefaults.standard.synchronize()
            
            let userName : String? = UserDefaults.standard.string(forKey: "user_name")
            
            //跳转到主页面
            self.dismissKeyBoard3()
            //注册环信
            let error = EMClient.shared().register(withUsername: newUser.username, password: newUser.password)
            if (error==nil) {
                print("注册成功")
            }
            
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let stateController = StateController(userName: userName!)
            
            let orderMealController = mainStoryboard.instantiateViewController(withIdentifier: "OrderMealController") as! OrderMealController
            orderMealController.stateController = stateController
            let nav0 = UINavigationController(rootViewController: orderMealController)
            nav0.tabBarItem.image = UIImage(named: "OrderMeal")
            nav0.title = "有啥吃的"
            
            let shoppingCartController = mainStoryboard.instantiateViewController(withIdentifier: "ShoppingCartViewController") as! ShoppingCartViewController
            shoppingCartController.stateController = stateController
            let nav1 = UINavigationController(rootViewController: shoppingCartController)
            nav1.tabBarItem.image = UIImage(named: "Shopping Cart")
            if stateController.mealOrderList.count != 0 {
                nav1.tabBarItem.badgeValue = "\(stateController.mealOrderList.count)"
            }
            nav1.title = "点了啥"
            
            let conversationListVC = ConversationListVC()
            let nav2 = UINavigationController(rootViewController: conversationListVC)
            
            nav2.tabBarItem.image = UIImage(named: "Message")
            nav2.title = "消息"
            
            let conversations = EMClient.shared().chatManager.getAllConversations() as? [EMConversation]
            var unreadMessageCount = 0
            if conversations != nil {
                for conv in conversations! {
                    unreadMessageCount += Int(conv.unreadMessagesCount)
                }
            }
            if unreadMessageCount == 0 {
                nav2.tabBarItem.badgeValue = nil
            }
            else {
                nav2.tabBarItem.badgeValue = "\(unreadMessageCount)"
            }
            
            let personalCenterController = mainStoryboard.instantiateViewController(withIdentifier: "PersonalCenterViewController") as! PersonalCenterViewController
            personalCenterController.stateController = stateController
            let nav3 = UINavigationController(rootViewController: personalCenterController)
            nav3.tabBarItem.image = UIImage(named: "Message")
            nav3.title = "个人中心"
            
            
            //登陆环信
            EMClient.shared().login(withUsername: newUser.username, password: newUser.password, completion: { (userName, emError) in
                if (emError == nil) {
                    print("登陆成功")
                    EMClient.shared().options.isAutoLogin = true
                    let conversations = EMClient.shared().chatManager.getAllConversations() as! [EMConversation]
                    var unreadMessageCount = 0
                    for conv in conversations {
                        unreadMessageCount += Int(conv.unreadMessagesCount)
                    }
                    if unreadMessageCount == 0 {
                        nav2.tabBarItem.badgeValue = nil
                    }
                    else {
                        nav2.tabBarItem.badgeValue = "\(unreadMessageCount)"
                    }
                }else {
                    print("登陆失败")
                }
            })
            
            let tabNav = UITabBarController()
            let viewControllerArray = [nav0, nav1, nav2, nav3]
            //tabNav.addChildViewController(nav0)
            //tabNav.addChildViewController(nav1)
            //tabNav.addChildViewController(nav3)
            tabNav.viewControllers = viewControllerArray
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            appDelegate.window?.rootViewController = tabNav

            //self.performSegue(withIdentifier: Segue.tableViewWallSegue, sender: nil)
            }
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
