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
	var orderListCatagory : String!

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
		NotificationCenter.default.addObserver(self,
                                               selector: #selector(type(of:self).dateChanged(_:)),
                                               name: .dateChanged,
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
        print("\(orderListCatagory)!! The instance of OrderListCenterVC was deinited!!!")
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name.reservedMealsDeleted, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.reservedMealsAdded, object: nil)
		NotificationCenter.default.removeObserver(self, name: Notification.Name.dateChanged, object: nil)
    }
}
extension OrderListCenterVC {
    @objc func reservedMealsDeleted(_ notification: Notification) {
        let mealsList = updateOrderList()
		dataSource = OrderListCenterDataSource(mealsList)
        tableView.dataSource = dataSource
        tableView.reloadData()
    }
    
    @objc func reservedMealsAdded(_ notification: Notification) {
        let mealsList = updateOrderList()
		dataSource = OrderListCenterDataSource(mealsList)
        tableView.dataSource = dataSource
        tableView.reloadData()
    }
	
	@objc func dateChanged(_ notification: Notification) {
        let mealsList = updateOrderList()
		dataSource = OrderListCenterDataSource(mealsList)
        tableView.dataSource = dataSource
        tableView.reloadData()
    }
	
	func updateOrderList()-> [ReservedMeals] {
	    let todayDate = MainVC.dateConvertString(date: Date())
        let reservedMealsHistory = StateController.share.readReservedMealsHistoryFromDisk()!
        var todayMealsList = [ReservedMeals]()
        var reservedMealsList = [ReservedMeals]()
        var historyMealsList = [ReservedMeals]()
        for mealsList in reservedMealsHistory {
            if mealsList.date == todayDate {
                todayMealsList.append(mealsList)
            }
            else if mealsList.date > todayDate {
                reservedMealsList.append(mealsList)
            }
            else {
                historyMealsList.append(mealsList)
            }
        }
		if self.orderListCatagory == OrderListCategroy.today {
		return todayMealsList
		}
		else if self.orderListCatagory == OrderListCategroy.reserved {
		return reservedMealsList
		}
		else {
		return historyMealsList
		}
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
