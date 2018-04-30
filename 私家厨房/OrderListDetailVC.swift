//
//  OrderListDetailController.swift
//  私家厨房
//
//  Created by Will.Shan on 30/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit

class OrderListDetailVC: UIViewController {

    @IBOutlet weak var orderTime: UILabel!
    @IBOutlet weak var thirdTable: UITableView!
    
    var orderListDetail : ReservedMeals!
    var dataSource : OrderListDetailDataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        orderTime.text = orderListDetail.date + "  " + orderListDetail.mealCatagory
        dataSource = OrderListDetailDataSource(orderListDetail: orderListDetail)
        thirdTable.dataSource = dataSource
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
//        self.view.layoutIfNeeded()
    }
    override func viewWillDisappear(_ animated: Bool) {
        print("OrderListDetailVC will disappear")

    }
}

extension OrderListDetailVC {
    
    @IBAction func deleteReservedMeals(_ sender: UIButton) {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        dismiss(animated: true, completion: nil)
        /*let isPresentingInAddMealMode = presentingViewController is UINavigationController
         
         if isPresentingInAddMealMode {
         dismiss(animated: true, completion: nil)
         }*/
        
        let title = "删除预定菜单?"
        let message = "确认删除当前日期内所有菜品么?"
        let ac = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        ac.addAction(cancelAction)
        
        let deleteAction = UIAlertAction(title: "删除", style: .destructive, handler: {
            (action) -> Void in
            
            //remove resveredMeals in disk
            let key = self.orderListDetail.date + self.orderListDetail.mealCatagory
            let archiveURL = DataStore.objectURLForKey(key: key)
            
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: archiveURL.path) {
                do {
                    try! fileManager.removeItem(atPath: archiveURL.path)
                }
                
                 //update reservedMealsHistory in disk
                let key0 = "reservedMealsHistory"
                let archiveURL0 = DataStore.objectURLForKey(key: key0)
                
                if var historyList = NSKeyedUnarchiver.unarchiveObject(withFile: archiveURL0.path) as? [String] {
                    for list in historyList {
                        if list == key {
                            let index = historyList.index(of: list)
                            historyList.remove(at: index!)
                            break
                        }
                    }
                    NSKeyedArchiver.archiveRootObject(historyList, toFile: archiveURL0.path)
                }
                //send out notification for updating orderlistcenter
                NotificationCenter.default.post(name: .reservedMealsDeleted, object: nil)
            }
            
            //如果是Navigation的形式，则释放popViewController
            if let owningNavigationController = self.navigationController{
                owningNavigationController.popViewController(animated: true)
            }
            else {
                fatalError("The MealViewController is not inside a navigation controller.")
            }
        })
        ac.addAction(deleteAction)
        self.present(ac, animated: true, completion: nil)
    }
}
