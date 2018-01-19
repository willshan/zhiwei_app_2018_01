//
//  OrderListViewController.swift
//  私家厨房
//
//  Created by Will.Shan on 11/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit

class OrderListVC: UIViewController, UITableViewDelegate {

    @IBOutlet weak var orderTime: UILabel!
    @IBOutlet weak var secondTableView: UITableView!
    
    fileprivate var dataSource: OrderListDataSource!
    var mealListBySections : [[OrderedMeal]]!
    var photosIdentifiers : [String]!

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = OrderListDataSource(mealListBySections: mealListBySections)
        secondTableView.delegate = self
        secondTableView.dataSource = dataSource
    }
    
    let dateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        let time = NSDate()
        orderTime.text = "下单时间：\(dateFormatter.string(from: time as Date))"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
