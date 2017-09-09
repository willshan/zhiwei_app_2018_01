//
//  ShoppingCartViewController.swift
//  私家厨房
//
//  Created by Will.Shan on 02/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit

class ShoppingCartViewController: UIViewController, UITableViewDelegate{

    @IBOutlet weak var firstTableView: UITableView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var reminder1: UILabel!
    
    var stateController : StateController!
    //var stateController = StateController(MealStorage())
    var dataSource: ShoppingCartDataSource!
    //var mealOrderList : [IndexPath:OrderedMeal]!

    //用于设置“确认下单”按钮在无菜品时，处于不可按下的状态
    var mealNumber = 0 {
        didSet{
            saveButtonUpdate()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        firstTableView.delegate = self
        //添加聊天管理代理
        EMClient.shared().chatManager.add(self, delegateQueue: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        dataSource = ShoppingCartDataSource(mealOrderList: stateController.mealOrderList)
        dataSource.shoppingCartController = self

        mealNumber = dataSource.mealOrderList.count
        if mealNumber == 0{
            reminder1.text = "今儿想吃啥，小主快来点点吧！"
        }
        else{
            reminder1.text = funnyReminder()
        }
        saveButtonUpdate()
        firstTableView.dataSource = dataSource
        firstTableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
    }

    override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
            // Dispose of any resources that can be recreated.
        }
}

extension ShoppingCartViewController{
    //来点有意思的标签
    func funnyReminder ()-> String {
        let labels = ["才这么一点，再来点吧！","小主口味真是独到","我今天也好想吃这个呀！！！","谁知盘中餐，粒粒皆辛苦啊","来来来，再来一瓶！！！","愿得一人心，白首不相离","对酒当歌，人生几何","唯有美食才能打断我的思索","这个，这个，还有这个，统统都要","要不换个大碗？","你问有多少卡？我问问Siri","晒个图吧，让大厨开心开心","红烧翅膀，我喜欢吃","你怎么就吃不胖呢，真让人嫉妒","我不是机器人，我也饿啦！！！"]
       
        let idx = arc4random_uniform(UInt32(labels.count))
        
        let randomLabel = labels[Int(idx)]
        
        return randomLabel
    }
    
    //update save button status
    func saveButtonUpdate() {
        if dataSource.mealOrderList.count == 0 {
            saveButton.isEnabled = false
            saveButton.backgroundColor = UIColor.gray
            saveButton.isHidden = true
        }
        else {
            saveButton.isEnabled = true
            saveButton.backgroundColor = UIColor.red
            saveButton.isHidden = false
        }
    }
    
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "OrderListSegue":
            guard let navi = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            let orderList = navi.topViewController as! OrderListViewController
            orderList.mealListBySections = dataSource.mealListBySections
            
            //传递photosIdentifers
            var photosIdentifers = [String]()
            let mealListBySections = dataSource.mealListBySections
            for meal in mealListBySections[0] {
                photosIdentifers.append(meal.mealIdentifier)
            }
            for meal in mealListBySections[1] {
                photosIdentifers.append(meal.mealIdentifier)
            }
            for meal in mealListBySections[2] {
                photosIdentifers.append(meal.mealIdentifier)
            }
            for meal in mealListBySections[3] {
                photosIdentifers.append(meal.mealIdentifier)
            }
            orderList.photosIdentifiers = photosIdentifers
    
        default:
            print("return to orderMeacontroller")
            //fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
}

//MARK: -监听消息列表
extension ShoppingCartViewController : EMChatManagerDelegate{
    func conversationListDidUpdate(_ aConversationList: [Any]!) {
        self.showTabBarBadge()
    }
    
    func messagesDidReceive(_ aMessages: [Any]!) {
        self.showTabBarBadge()
    }
    
    func showTabBarBadge() {
        let conversations = EMClient.shared().chatManager.getAllConversations() as! [EMConversation]
        var unreadMessageCount = 0
        for conv in conversations {
            unreadMessageCount += Int(conv.unreadMessagesCount)
        }
        let nav1 = self.navigationController
        let tabNav = nav1?.tabBarController
        let nav2 = tabNav?.viewControllers?[2]
        
        if unreadMessageCount == 0 {
            nav2?.tabBarItem.badgeValue = nil
        }
        else {
            
            nav2?.tabBarItem.badgeValue = "\(unreadMessageCount)"
        }
    }
}
