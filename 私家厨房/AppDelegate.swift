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

    let container = CKContainer.default()
    //fileprivate var stateController : StateController?
    var mealCountNumber = [IndexPath:Int]()
    var stateController : StateController?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        //MARK: 注册离线推送
        // Silent push
        let notificationInfo = CKNotificationInfo()
        // Set only this property
        notificationInfo.shouldSendContentAvailable = true
        
//        // Register for remote notification.
//        let userNotificationCenter = UNUserNotificationCenter.current()
//        userNotificationCenter.delegate = self
//        userNotificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { accepted, error in
//            guard accepted == true else {
//                print("User declined remote notifications")
//                return
//            }
//        }
        application.registerForRemoteNotifications()

        //
        let rootViewController = self.window!.rootViewController as! UITabBarController
        let stateController = StateController()
        //tab0
        let nav0 = rootViewController.viewControllers?[0] as! UINavigationController
        let orderMealController = nav0.viewControllers.first as! MealListVC
        orderMealController.stateController = stateController

        //tab1
        let nav1 = rootViewController.viewControllers?[1] as! UINavigationController
        let shoppingCartController = nav1.viewControllers.first as! ShoppingCartVC
        shoppingCartController.stateController = stateController
        if stateController.selectedMeals?.count != 0 {
            nav1.tabBarItem.badgeValue = "\(stateController.selectedMealsCount)"
        }
        
        //tab2
        
 
        //tab3
        let nav3 = rootViewController.viewControllers?[3] as! UINavigationController
        let personalCenterController = nav3.viewControllers.first as! PersonalCenterVC
        personalCenterController.stateController = stateController

        self.stateController = stateController
        
        // Checking account availability. Create local cache objects if the accountStatus is available.
        checkAccountStatus(for: container) {
            DatabaseLocalCache.share.initialize(container: self.container)
        }
        
        return true
    }
    
    // Note that to be able to accept a share, we need to have CKSharingSupported key in the info.plist and
    // set its value to true. This is mentioned in the WWDC 2016 session 226 “What’s New with CloudKit”.
    //
    func application(_ application: UIApplication, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShareMetadata) {
        print("++++++++++user accepted share")
        let acceptSharesOp = CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])
        acceptSharesOp.acceptSharesCompletionBlock = { error in
            guard CloudKitError.share.handle(error: error, operation: .acceptShare, alert: true) == nil else {return}
        }
        container.add(acceptSharesOp)
    }
    
    // 1 成功获得deviceToken
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
    }
    // 2 失败获得deviceToken
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        if (error as NSError).code == 3010 {
            print("Push notifications are not supported in the iOS Simulator.")
        } else {
            print("application:didFailToRegisterForRemoteNotificationsWithError:\(error)")
        }
    }
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        print("app will resign active")

        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        //保存数据到硬盘
        //stateController.saveMealToDisk()
        print("app did enter backgroud")

        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        print("app will enter foreground")
        let tabVC = self.window?.rootViewController as! UITabBarController
        let nav0 = tabVC.viewControllers?[0] as! UINavigationController
        guard let viewController = nav0.viewControllers.first as? MealListVC else { return }
        viewController.updateUI()

    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("app did become active")
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        HandleCoreData.saveContext()
    }
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("******Received notification!")

        let dict = userInfo as! [String: NSObject]
        guard let notification : CKDatabaseNotification = CKNotification(fromRemoteNotificationDictionary:dict) as? CKDatabaseNotification else { return }
        DatabaseLocalCache.share.fetchChanges(in: notification.databaseScope) {_ in 
            completionHandler(.newData)
            if application.applicationState == UIApplicationState.active {
                //update UI
                let tabVC = self.window?.rootViewController as! UITabBarController
                let nav0 = tabVC.viewControllers?[0] as! UINavigationController
                guard let viewController = nav0.viewControllers.first as? MealListVC else { return }
                DispatchQueue.main.async {
                    viewController.updateUI()
                }
            }
        }
    }
    
    // Checking account availability. We do account check when the app comes back to foreground.
    // We don't rely on ubiquityIdentityToken because it is not supported on tvOS and watchOS, while
    // CloudKit is supported in those platforms.
    //
    // Silently return if everything goes well, or do a second check a while after the first failure.
    //
    private func checkAccountStatus(for container: CKContainer, completionHandler: (() -> Void)? = nil) {
        
        container.accountStatus() { (status, error) in
            
            if CloudKitError.share.handle(error: error, operation: .accountStatus, alert: true) == nil &&
                status == CKAccountStatus.available {
                
                if let completionHandler = completionHandler {completionHandler()}
                return
            }
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) { // Initiate the second check.
                
                container.accountStatus() { (status, error) in
                    
                    if CloudKitError.share.handle(error: error, operation: .accountStatus, alert: true) == nil &&
                        status == CKAccountStatus.available {
                        
                        if let completionHandler = completionHandler {completionHandler()}
                        return
                    }
                    
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "iCloud账户不可用",
                                                      message: "请确认已登录iCloud并开启iCloud Drive",
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                        self.window?.rootViewController?.present(alert, animated: true)
                        
                        // If the local cache is built up, clear it and reload the UI. This happens when userse turn off
                        // iCloud while this app is in background.
                        //
               //         guard ZoneLocalCache.share.container != nil else {return}
                        
                        // Clear the cache container and reload the whole UI stack.
                        //
                 //       ZoneLocalCache.share.container =  nil
                 //       TopicLocalCache.share.container = nil
                        
                 //       let storyboard = UIStoryboard(name: StoryboardID.main, bundle: nil)
                 //       let mainNC = storyboard.instantiateViewController(withIdentifier: StoryboardID.mainNC) as! UINavigationController
                 //       let zoneNC = storyboard.instantiateViewController(withIdentifier: StoryboardID.zoneNC) as! UINavigationController
                 //       self.window?.rootViewController = MenuViewController(mainViewController: mainNC, menuViewController: zoneNC)
                    }
                }
            }
        }
    }
}


extension AppDelegate: UNUserNotificationCenterDelegate {
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
  
//        let userInfo = notification.request.content.userInfo
//        let request = notification.request
//        let content = request.content
//        let badge = content.badge
//        let body = content.body
//        let sound = content.sound
//        let subTitle = content.subtitle
//        let title = content.title
//
//        print("这个方法被激发")
//        if notification.request.trigger?.isKind(of: UNPushNotificationTrigger.self) == true{
//            print("前台收到远程通知")
//        }
//        else {
//            print("***********前台收到本地通知")
//        }
//        //PFPush.handle(notification.request.content.userInfo)
//        completionHandler([.alert, .badge, .sound])
    }

}
