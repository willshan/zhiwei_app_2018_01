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
    
    var reservedMealsHistory = [ReservedMeals]()
    var dataSource : OrderListCenterDataSource!

    override func viewDidLoad() {
        
        super.viewDidLoad()
        //Add notificaton listener
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(type(of:self).reservedMealsDeleted(_:)),
                                               name: .reservedMealsDeleted,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(type(of:self).reservedMealsAdded(_:)),
                                               name: .reservedMealsAdded,
                                               object: nil)
//        reservedMealsHistory = StateController.share.readReservedMealsHistoryFromDisk()!
        
        dataSource = OrderListCenterDataSource(reservedMealsHistory)
        tableView.dataSource = dataSource
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
    }
    
    deinit {
        print("The instance of OrderListCenterVC was deinited!!!")
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name.reservedMealsDeleted, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.reservedMealsAdded, object: nil)
    }
}
extension OrderListCenterVC {
    @objc func reservedMealsDeleted(_ notification: Notification) {
        dataSource = OrderListCenterDataSource(StateController.share.readReservedMealsHistoryFromDisk()!)
        tableView.dataSource = dataSource
        tableView.reloadData()
    }
    
    @objc func reservedMealsAdded(_ notification: Notification) {
        dataSource = OrderListCenterDataSource(StateController.share.readReservedMealsHistoryFromDisk()!)
        tableView.dataSource = dataSource
        tableView.reloadData()
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
