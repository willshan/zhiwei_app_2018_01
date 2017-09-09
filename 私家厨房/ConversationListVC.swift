//
//  ConversationListVC.swift
//  私家厨房
//
//  Created by Will.Shan on 10/08/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit

class ConversationListVC: EaseConversationListViewController {

    var conversations : [EMConversation]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        var addButtonItem : UIBarButtonItem {
            //return UIBarButtonItem(title: "编辑", style: .plain, target: self, action: #selector(ViewDetailVC.editMeal(_:)))
            //return UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(ViewDetailVC.editMeal(_:)))
            return UIBarButtonItem(barButtonSystemItem: .add, target: self, action: nil)
        }
        //是否支持下拉刷新
        //self.showRefreshHeader = true
        
        //添加聊天管理代理
        //EMClient.shared().chatManager.add(self, delegateQueue: nil)
        
        //载入数据
        //self.loadConversations()
        //刷新一下数据
        //self.tableViewDidTriggerHeaderRefresh()
        
        self.navigationController?.view.backgroundColor = UIColor.white
        //self.navigationController?.tabBarController?.tabBar.isHidden = false
        
        navigationItem.title = "消息列表"
        navigationItem.rightBarButtonItem = addButtonItem
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        //刷新数据
        self.tableViewDidTriggerHeaderRefresh()
        self.showTabBarBadge()
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("一共有\(self.dataArray.count)个会话")
    }
}

extension ConversationListVC {
    //会话列表变更
    override func conversationListDidUpdate(_ aConversationList: [Any]!) {
        //self.conversations = aConversationList as? [EMConversation]
        //self.tableView.reloadData()
        self.tableViewDidTriggerHeaderRefresh()
        self.showTabBarBadge()
    }
 
    //收到新消息后刷新tab2图标显示
    override func messagesDidReceive(_ aMessages: [Any]!) {
        self.tableViewDidTriggerHeaderRefresh()
        self.showTabBarBadge()
    }

    //在tab2图标上显示未读消息数
    func showTabBarBadge() {
        let conversations = EMClient.shared().chatManager.getAllConversations() as? [EMConversation]
        var unreadMessageCount = 0
        if conversations != nil {
            for conv in conversations! {
                unreadMessageCount += Int(conv.unreadMessagesCount)
            }
            if unreadMessageCount == 0 {
                
                self.navigationController?.tabBarItem.badgeValue = nil
            }
            else {
                
                self.navigationController?.tabBarItem.badgeValue = "\(unreadMessageCount)"
            }
        }
    }
}
