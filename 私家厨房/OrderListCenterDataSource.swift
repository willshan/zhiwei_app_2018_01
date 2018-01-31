//
//  OrderListCenterDataSource.swift
//  私家厨房
//
//  Created by Will.Shan on 29/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit

class OrderListCenterDataSource : NSObject {
    //菜名
    var orderLists : [OrderListStruct]!
    var mealPhotos = [UIImage]()
    init(orderList: [OrderListStruct]) {
        self.orderLists = orderList
    }
}

extension OrderListCenterDataSource : UITableViewDataSource {
    //MARK : -Deploy tableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderLists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = TableCellReusableID.orderCenter
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? OrderListCenterCell  else {
            fatalError("The dequeued cell is not an instance of OrderListCenterCell.")
        }
        cell.date.text = orderLists[indexPath.row].orderTime
        cell.button1.layer.borderColor = UIColor.red.cgColor
        
        //orderLists已经是按菜种分类过的
        let orderList1 = orderLists[indexPath.row].orderList[0]
        let orderList2 = orderLists[indexPath.row].orderList[1]
        let orderList3 = orderLists[indexPath.row].orderList[2]
        let orderList4 = orderLists[indexPath.row].orderList[3]
        
        var dishesCount1 = 0
        for meal in orderList1 {
            dishesCount1 += meal.mealCount
        }
        var dishesCount2 = 0
        for meal in orderList2 {
            dishesCount2 += meal.mealCount
        }
        var dishesCount3 = 0
        for meal in orderList3 {
            dishesCount3 += meal.mealCount
        }
        var dishesCount4 = 0
        for meal in orderList4 {
            dishesCount4 += meal.mealCount
        }
        
        cell.dishes.text = "点了\(dishesCount1+dishesCount2+dishesCount3)道菜"
        cell.drink.text = "还有\(dishesCount4)瓶饮料"
        if dishesCount4 == 0 {
            cell.drink.isHidden = true
        }
        else {
            cell.drink.isHidden = false
        }
        //??????????????从这里开始检查
        let photoIdentifers = orderLists[indexPath.row].mealsIdentifiers
        var mealPhotos = [UIImage]()
        
        for identifier in photoIdentifers {
            mealPhotos.append(DataStore().imageForKey(key: identifier)!)
        }
        
        self.mealPhotos = mealPhotos
        if mealPhotos.count <= 5 {
            cell.etc.isHidden = true
        }
        else {
            cell.etc.isHidden = false
        }
        
        ///????????????
        cell.photoCollection.dataSource = self
        
        return cell
        
    }
}
extension OrderListCenterDataSource : UICollectionViewDataSource {
    //MARK : -Deploy collectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mealPhotos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = "OrderListCollectionViewCell"
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? OrderListCollectionViewCell else {
            fatalError("The dequeued cell is not an instance of OrderListCollectionViewCell.")
        }

        cell.photoInCell.image = mealPhotos[indexPath.row]
        
        return cell
        
    }
}

