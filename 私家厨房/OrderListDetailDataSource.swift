//
//  OrderListDetailDataSource.swift
//  私家厨房
//
//  Created by Will.Shan on 30/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit

class OrderListDetailDataSource : NSObject {
    //菜名
    var orderListDetail : ReservedMeals!
    
    init(orderListDetail: ReservedMeals) {
        self.orderListDetail = orderListDetail
    }
}

extension OrderListDetailDataSource : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderListDetail.mealsIdentifiers!.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = TableCellReusableID.orderDetail
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? OrderListDetailCell  else {
            fatalError("The dequeued cell is not an instance of OrderListCenterCell.")
        }
        cell.index.text = String(indexPath.row+1)
        let identifer = orderListDetail.mealsIdentifiers![indexPath.row]
        let meal = HandleCoreData.queryDataWithIdentifer(identifer).first
        cell.mealName.text = meal?.mealName ?? "菜品已被删除"
        cell.mealPhoto.image = DataStore().getImageForKey(key: identifer) ?? UIImage(named: AssetNames.defaultPhoto)!
        
        return cell
    }
}
