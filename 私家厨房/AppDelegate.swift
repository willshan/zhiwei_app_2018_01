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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    //fileprivate var stateController : StateController?
    var mealCountNumber = [IndexPath:Int]()
    var stateController : StateController?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
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
        //1
        let userNotificationCenter = UNUserNotificationCenter.current()
        userNotificationCenter.delegate = self
        
        //2 获取消息推送权限
        //ISO系统10.0及以上
        if UIDevice.current.systemVersion.hashValue >= 10 {
        userNotificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { accepted, error in
            guard accepted == true else {
                print("User declined remote notifications")
                return
            }
            userNotificationCenter.getNotificationSettings(completionHandler: { (settings) in
                print("\(settings)")
            })
            }
        }
            //ISO系统8.0及以上
        else if UIDevice.current.systemVersion.hashValue >= 8{
            let notificationTypes : UIUserNotificationType = [.alert, .sound, .badge]
            let settings = UIUserNotificationSettings(types: notificationTypes, categories: nil)
            application.registerUserNotificationSettings(settings)
        }
            //ISO系统8.0以下
        else if UIDevice.current.systemVersion.hashValue < 8{
            let notificationTypes : UIRemoteNotificationType = [.badge, .alert, .sound]
            UIApplication.shared.registerForRemoteNotifications(matching: notificationTypes)
        }
        
        //3 注册获得device Token
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
        
        Parse.enableLocalDatastore()
        // Initialize Parse.
        let configuration = ParseClientConfiguration {
            $0.applicationId = "nameless-beyond-49193"
            $0.server = "https://nameless-beyond-49193.herokuapp.com/parse"
        }
        Parse.initialize(with: configuration)

        // [Optional] Track statistics around application opens.
        PFAnalytics.trackAppOpened(launchOptions: launchOptions)
        
        let userName : String? = UserDefaults.standard.string(forKey: "user_name")
        
        //print(userName)
        //print(PFUser.current()?.objectId)
        
        if userName != nil {
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            
            let stateController = StateController(userName: userName!)
            //print("*****************\(stateController.meals)")
            
            //自动登陆环信，已经设置
            
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
            nav3.tabBarItem.image = UIImage(named: "PersonalCenter")
            nav3.title = "个人中心"
            
            let tabNav = UITabBarController()
            let viewControllerArray = [nav0, nav1, nav2, nav3]
            //tabNav.addChildViewController(nav0)
            //tabNav.addChildViewController(nav1)
            //tabNav.addChildViewController(nav3)
            tabNav.viewControllers = viewControllerArray
            
            self.window?.rootViewController = tabNav
            self.stateController = stateController
        }
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
        EMClient.shared().chatManager.remove(self)
        
        EMClient.shared().applicationWillEnterForeground(application)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        HandleCoreData.saveContext()
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
