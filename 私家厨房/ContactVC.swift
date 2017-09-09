//
//  ContactVC.swift
//  私家厨房
//
//  Created by Will.Shan on 01/09/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit

class ContactVC: EaseUsersListViewController {
    
    //var userList = EMClient.shared().contactManager.getContacts()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: -自定义UIBarButton,并添加方法
        var addButtonItem : UIBarButtonItem {
            //return UIBarButtonItem(title: "编辑", style: .plain, target: self, action: #selector(ViewDetailVC.editMeal(_:)))
            //return UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(ViewDetailVC.editMeal(_:)))
            
            return UIBarButtonItem(barButtonSystemItem: .add, target: self, action: nil)
        }
        
        navigationItem.rightBarButtonItem = addButtonItem
        
        self.navigationController?.view.backgroundColor = UIColor.white
        
        //self.navigationController?.tabBarController?.tabBar.isHidden = true

    }
    //刷新一下数据
    //self.tableViewDidTriggerHeaderRefresh()
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.showRefreshHeader = true
        //self.tableViewDidTriggerHeaderRefresh()
        //self.showRefreshHeader = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ContactVC {
    
}
