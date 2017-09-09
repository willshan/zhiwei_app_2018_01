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
    var orderListDetail : OrderListStruct!
    
    init(orderListDetail: OrderListStruct) {
        self.orderListDetail = orderListDetail
    }
}

extension OrderListDetailDataSource : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return orderListDetail.orderList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderListDetail.orderList[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0 :
            if orderListDetail.orderList[0].count == 0 {
                return nil
            } else {
                return "凉菜"
            }
        case 1:
            if orderListDetail.orderList[1].count == 0 {
                return nil
            } else {
                return "热菜"
            }
        case 2:
            if orderListDetail.orderList[2].count == 0 {
                return nil
            } else {
                return "汤"
            }
        case 3:
            if orderListDetail.orderList[3].count == 0 {
                return nil
            } else {
                return "酒水"
            }
        default:
            return "其他"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "OrderListDetailCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? OrderListDetailCell  else {
            fatalError("The dequeued cell is not an instance of OrderListCenterCell.")
        }
        cell.index.text = String(indexPath.row+1)
        cell.mealName.text = orderListDetail.orderList[indexPath.section][indexPath.row].mealName
        cell.mealPhoto.image = ImageStore().imageForKey(key: orderListDetail.orderList[indexPath.section][indexPath.row].mealIdentifier)
        cell.mealCount.text = "\(orderListDetail.orderList[indexPath.section][indexPath.row].mealCount)份"
        
        return cell
    }
}
