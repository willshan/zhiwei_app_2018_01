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
    var reservedMealsHistoy : [ReservedMeals]!
    var mealPhotos = [UIImage]()
    init(_ reservedMealsHistoy: [ReservedMeals]) {
        self.reservedMealsHistoy = reservedMealsHistoy
    }
}

extension OrderListCenterDataSource : UITableViewDataSource {
    //MARK : -Deploy tableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reservedMealsHistoy.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = TableCellReusableID.orderCenter
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? OrderListCenterCell  else {
            fatalError("The dequeued cell is not an instance of OrderListCenterCell.")
        }
        cell.date.text = reservedMealsHistoy[indexPath.row].date + "  " + reservedMealsHistoy[indexPath.row].mealCatagory
        
        let photoIdentifers = reservedMealsHistoy[indexPath.row].mealsIdentifiers
        var mealPhotos = [UIImage]()
        
        cell.dishes.text = "共预定\(photoIdentifers!.count)道菜"
        for identifier in photoIdentifers! {
            mealPhotos.append(DataStore().getImageForKey(key: identifier)!)
        }
        
        self.mealPhotos = mealPhotos

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

