//
//  OrderListDataSource.swift
//  私家厨房
//
//  Created by Will.Shan on 28/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit

class OrderListDataSource : NSObject {
    //菜名
    var mealListBySections : [[OrderedMeal]]
    
    init(mealListBySections: [[OrderedMeal]]) {
        self.mealListBySections = mealListBySections
    }
}

extension OrderListDataSource : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return mealListBySections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mealListBySections[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0 :
            if mealListBySections[0].count == 0 {
                return nil
            } else {
                return "凉菜"
            }
        case 1:
            if mealListBySections[1].count == 0 {
                return nil
            } else {
                return "热菜"
            }
        case 2:
            if mealListBySections[2].count == 0 {
                return nil
            } else {
                return "汤"
            }
        case 3:
            if mealListBySections[3].count == 0 {
                return nil
            } else {
                return "酒水"
            }
        default:
            return "其他"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = TableCellReusableID.order
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? OrderListCell  else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        cell.index.text = String(indexPath.row+1)
        cell.mealName.text = mealListBySections[indexPath.section][indexPath.row].mealName
        cell.mealCount.text = "\(mealListBySections[indexPath.section][indexPath.row].mealCount)份"
        
        return cell
    }
}
