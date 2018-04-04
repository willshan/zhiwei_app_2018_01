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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension OrderListDetailVC {
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        dismiss(animated: true, completion: nil)
        /*let isPresentingInAddMealMode = presentingViewController is UINavigationController
         
         if isPresentingInAddMealMode {
         dismiss(animated: true, completion: nil)
         }*/
        
        //如果是Navigation的形式，则释放popViewController
        if let owningNavigationController = navigationController{
            owningNavigationController.popViewController(animated: true)
        }
        else {
            fatalError("The MealViewController is not inside a navigation controller.")
        }
    }
}
