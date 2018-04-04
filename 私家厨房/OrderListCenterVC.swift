//
//  MyOrderListTableViewController.swift
//  私家厨房
//
//  Created by Will.Shan on 23/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit
import os.log

class OrderListCenterVC: UITableViewController {
    
    var reservedMealsHistory : [ReservedMeals]?
    var dataSource : OrderListCenterDataSource!

    override func viewDidLoad() {
        navigationItem.title = "预定查看"
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        dataSource = OrderListCenterDataSource(reservedMealsHistory!)
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

extension OrderListCenterVC {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case SegueID.showOrderListDetail:
            guard let orderListDetailController = segue.destination as? OrderListDetailVC else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            guard let selectedMealCell = sender as? OrderListCenterCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            guard let indexPath = tableView.indexPath(for: selectedMealCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            let reservedMeals = dataSource.reservedMealsHistoy[indexPath.row]
            orderListDetailController.orderListDetail = reservedMeals
            
        default:
            print("return to orderMeacontroller")
            //fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
}
