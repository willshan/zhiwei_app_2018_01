//
//  MyOrderListTableViewController.swift
//  私家厨房
//
//  Created by Will.Shan on 23/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit
import os.log

class OrderListCenterController: UITableViewController {
    
    var orderList : [OrderListStruct]?
    var dataSource : OrderListCenterDataSource!

    override func viewDidLoad() {
        navigationItem.title = "订单中心"
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        dataSource = OrderListCenterDataSource(orderList: orderList!)
        tableView.dataSource = dataSource
        
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension OrderListCenterController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "OrderListDetailSegue":
            guard let orderListDetailController = segue.destination as? OrderListDetailController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            guard let selectedMealCell = sender as? OrderListCenterCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            guard let indexPath = tableView.indexPath(for: selectedMealCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            let selectedOrderList = dataSource.orderLists[indexPath.row]
            orderListDetailController.orderListDetail = selectedOrderList
            
        default:
            print("return to orderMeacontroller")
            //fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
}
