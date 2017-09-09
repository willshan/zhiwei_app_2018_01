//
//  LoginViewController.swift
//  ParseDemo
//
//  Created by Rumiya Murtazina on 7/28/15.
//  Copyright (c) 2015 abearablecode. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate{
    
    //MARK: -Segue Identifiers
    fileprivate enum Segue {
        static let navigation = "LoginSuccesful"
    }
    
    //MARK: -IBOutlets
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

//MARK: -Life cycle
extension LoginViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

// MARK: - IBActions
private extension LoginViewController {

    //Hide Keyboard
    private func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    @IBAction func dismissKeyBoard(_ sender: UITapGestureRecognizer){
        usernameField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
    }
    @IBAction func dismissKeyBoard2(_ sender: UITapGestureRecognizer){
        usernameField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
    }
    func dismissKeyBoard3(){
        usernameField.resignFirstResponder()
        passwordField.resignFirstResponder()
    }
    
    //
    @IBAction func unwindToLogInScreen(_ segue:UIStoryboardSegue) {
    }
    
    //Login
    @IBAction func loginAction(_ sender: AnyObject) {
            guard let username = usernameField.text,
                let password = passwordField.text else {
                    displayAlertController(NSLocalizedString("Missing Information", comment: ""),
                                           message: NSLocalizedString("Username and Password fields cannot be empty. Please enter and try again!", comment: ""))
                    return
            }
            
            PFUser.logInWithUsername(inBackground: username, password: password) { [unowned self] user, error in
                guard let _ = user else {
                    self.showErrorView(error)
                    return
                }
                UserDefaults.standard.set(user?.username, forKey: "user_name")
                UserDefaults.standard.synchronize()
                
                let userName : String? = UserDefaults.standard.string(forKey: "user_name")
                //跳转到主页面
                self.dismissKeyBoard3()
                
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
                if stateController.mealOrderList.count != 0 {
                    nav1.tabBarItem.badgeValue = "\(stateController.mealOrderList.count)"
                }
                nav1.tabBarItem.image = UIImage(named: "Shopping Cart")
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
                nav3.tabBarItem.image = UIImage(named: "PersonalCenter")
                nav3.title = "个人中心"
                
                //登陆环信
                EMClient.shared().login(withUsername: username, password: password, completion: { (userName, emError) in
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

                //self.performSegue(withIdentifier: Segue.navigation, sender: nil)
            }
    }
}
// MARK: - Private
private extension LoginViewController {
    
    /**
     Helper method to present a **UIAlertController** to the user
     
     - parameter title: Title for the controller
     - parameter message: Message displayed inside the controller
     */
    func displayAlertController(_ title: String, message: String) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""), style: .cancel))
        present(controller, animated: true)
    }
}
