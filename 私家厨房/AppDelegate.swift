//
//  AppDelegate.swift
//  私家厨房
//
//  Created by Will.Shan on 04/03/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit
import UserNotifications
import CoreData
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    //fileprivate var stateController : StateController?
    var mealCountNumber = [IndexPath:Int]()
    var stateController : StateController?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        if UserDefaults.standard.string(forKey: "user_ID") == nil {
            CKContainer.default().fetchUserRecordID { (recordID, error) in
                if error == nil {
                    let userID = recordID?.recordName
                    print("current user's userID is \(String(describing: userID))")
                    
                    //注册环信
                    let error = EMClient.shared().register(withUsername: userID, password: "123")
                    if (error == nil) {
                        print("注册成功")
                        
                        UserDefaults.standard.set(userID, forKey: "user_ID")
                        UserDefaults.standard.synchronize()
                        
                        //登陆环信
                        EMClient.shared().login(withUsername: userID, password: "123", completion: { (userID, emError) in
                            if (emError == nil) {
                                print("登陆成功")
                                //set 自动登陆
                                EMClient.shared().options.isAutoLogin = true
                                
                            }else {
                                print("登陆失败")
                            }
                        })
                    }
                    else {
                        print("注册失败，\(error)")
                        //登陆环信
                        EMClient.shared().login(withUsername: userID, password: "123", completion: { (userID, emError) in
                            if (emError == nil) {
                                print("登陆成功")
                                //set 自动登陆
                                EMClient.shared().options.isAutoLogin = true
                                UserDefaults.standard.set(userID, forKey: "user_ID")
                                UserDefaults.standard.synchronize()
                                
                            }else {
                                print("登陆失败")
                            }
                        })
                    }
                }
                else {
                    print("\(String(describing: error))")
                }
            }
        }
        
        //环信初始化
        let options = EMOptions.init(appkey: "1113170714178362#nameless-beyond-49193")
        options?.apnsCertName = "Push_Certificate"
        let error1 = EMClient.shared().initializeSDK(with: options)
        if (error1 == nil) {
            print("初始化成功")
        }
        else {
            print("初始化失败")
        }
        
        //MARK: 注册离线推送
        // Silent push
        let notificationInfo = CKNotificationInfo()
        // Set only this property
        notificationInfo.shouldSendContentAvailable = true
        
        let userNotificationCenter = UNUserNotificationCenter.current()
        userNotificationCenter.delegate = self
        userNotificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { accepted, error in
            guard accepted == true else {
                print("User declined remote notifications")
                return
            }
        }
        
        application.registerForRemoteNotifications()

        //设置推送显示形式
        let emPushOptions : EMPushOptions = EMClient.shared().pushOptions
        emPushOptions.displayStyle = EMPushDisplayStyleMessageSummary // 显示消息内容
        // options.displayStyle == EMPushDisplayStyleSimpleBanner // 显示“您有一条新消息”
        let error2 = EMClient.shared().updatePushOptionsToServer() // 更新配置到服务器，该方法为同步方法，如果需要，请放到单独线程
        if error2 == nil {
            // 更新配置成功
        }else {
            // 更新配置失败
        }

        let rootViewController = self.window!.rootViewController as! UITabBarController
        let stateController = StateController()
        //tab0
        let nav0 = rootViewController.viewControllers?[0] as! UINavigationController
        let orderMealController = nav0.viewControllers.first as! OrderMealController
        orderMealController.stateController = stateController
        nav0.tabBarItem.image = UIImage(named: "OrderMeal")
        nav0.title = "有啥吃的"
        //tab1
        let nav1 = rootViewController.viewControllers?[1] as! UINavigationController
        let shoppingCartController = nav1.viewControllers.first as! ShoppingCartViewController
        shoppingCartController.stateController = stateController
        if stateController.mealOrderList.count != 0 {
            nav1.tabBarItem.badgeValue = "\(stateController.mealOrderList.count)"
        }
        nav1.tabBarItem.image = UIImage(named: "Shopping Cart")
        nav1.title = "点了啥"
        //tab2
        let nav2 = rootViewController.viewControllers?[2] as! UINavigationController
        //let conversationListVC = nav2.viewControllers.first as! ConversationListVC
        nav2.tabBarItem.image = UIImage(named: "Message")
        nav2.title = "消息"
        /*
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
        }*/
        //tab3
        let nav3 = rootViewController.viewControllers?[3] as! UINavigationController
        let personalCenterController = nav3.viewControllers.first as! PersonalCenterViewController
        personalCenterController.stateController = stateController
        nav3.tabBarItem.image = UIImage(named: "PersonalCenter")
        nav3.title = "个人中心"

        self.stateController = stateController
        
        return true
    }

    // 1 成功获得deviceToken
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        EMClient.shared().bindDeviceToken(deviceToken)
    }
    // 2 失败获得deviceToken
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        if (error as NSError).code == 3010 {
            print("Push notifications are not supported in the iOS Simulator.")
        } else {
            print("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    
    //监听是否有消息进来
    func messagesDidReceive(_ aMessages: [Any]!) {
        let conversations = EMClient.shared().chatManager.getAllConversations() as! [EMConversation]
        var unreadMessageCount = 0
        for conv in conversations {
            unreadMessageCount += Int(conv.unreadMessagesCount)
        }
        UIApplication.shared.applicationIconBadgeNumber = unreadMessageCount
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "YXMMessagesDidReceived"), object: nil)
        
        if UIApplication.shared.applicationState == UIApplicationState.background {
            self.showNotificationWithMessage(message: aMessages.last as! EMMessage)
        }
    }
    //本地推送
    func showNotificationWithMessage(message : EMMessage)->Void {
        let easeMessageModel : EaseMessageModel = EaseMessageModel.init(message: message)
        if UIDevice.current.systemVersion.hashValue >= 10 {
            let userNotificationCenter = UNUserNotificationCenter.current()
            let mutableNotificationContent = UNMutableNotificationContent()
            mutableNotificationContent.body = String.init(format: "%@: %@", message.from, easeMessageModel.text)
            mutableNotificationContent.sound = UNNotificationSound.default()
            let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 0.1, repeats: false)
            //一个requestIdentifier对应一个通知，所以新的推送要
            let requestIdentifier = String(UIApplication.shared.applicationIconBadgeNumber)
            let request = UNNotificationRequest.init(identifier: requestIdentifier, content: mutableNotificationContent, trigger: trigger)
            userNotificationCenter.add(request, withCompletionHandler: { (error) in
                if error == nil {
                    print("本地推送成功")
                }
            })
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        print("app will resign active")
        let conversations = EMClient.shared().chatManager.getAllConversations() as? [EMConversation]
        var unreadMessageCount = 0
        if conversations != nil {
            for conv in conversations! {
                unreadMessageCount += Int(conv.unreadMessagesCount)
            }
        }
        application.applicationIconBadgeNumber = unreadMessageCount
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        //保存数据到硬盘
        //stateController.saveMealToDisk()
        print("app did enter backgroud")
        EMClient.shared().chatManager.add(self, delegateQueue: nil)
        
        EMClient.shared().applicationDidEnterBackground(application)

        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        print("app will enter foreground")
        EMClient.shared().chatManager.remove(self)
        EMClient.shared().applicationWillEnterForeground(application)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("app did become active")
        
        let tabVC = self.window?.rootViewController as! UITabBarController
        let nav0 = tabVC.viewControllers?[0] as! UINavigationController
        let viewController = nav0.viewControllers.first as? OrderMealController

        viewController?.viewWillAppear(true)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        HandleCoreData.saveContext()
    }
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Received notification!")
        let tabVC = self.window?.rootViewController as! UITabBarController
        let nav0 = tabVC.viewControllers?[0] as! UINavigationController
        guard let viewController = nav0.viewControllers.first as? OrderMealController else { return }

        let dict = userInfo as! [String: NSObject]
        guard let notification : CKDatabaseNotification = CKNotification(fromRemoteNotificationDictionary:dict) as? CKDatabaseNotification else { return }
        
        viewController.fetchChanges(in: notification.databaseScope) {
            completionHandler(UIBackgroundFetchResult.newData)
        }
    }
}


extension AppDelegate: UNUserNotificationCenterDelegate, EMChatManagerDelegate {
    //app通知的点击
    /*
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        code
    }
    */
    
    //Called when a notification is delivered to a foreground app.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:@escaping (UNNotificationPresentationOptions) -> Void) {
    /*
        let userInfo = notification.request.content.userInfo
        let request = notification.request
        let content = request.content
        let badge = content.badge
        let body = content.body
        let sound = content.sound
        let subTitle = content.subtitle
        let title = content.title
 */
        print("这个方法被激发")
        if notification.request.trigger?.isKind(of: UNPushNotificationTrigger.self) == true{
            print("前台收到远程通知")
        }
        else {
            print("***********前台收到本地通知")
        }
        //PFPush.handle(notification.request.content.userInfo)
        completionHandler([.alert, .badge, .sound])
    }
}
