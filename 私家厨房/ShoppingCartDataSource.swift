//
//  ShoppingCartDataSource.swift
//  私家厨房
//
//  Created by Will.Shan on 27/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit

class ShoppingCartDataSource : NSObject {
    var mealListBySections : [[OrderedMeal]]
    //OrderedMeal是一个struct，用来记录mealName和mealCount
    var mealOrderList : [IndexPath : OrderedMeal]!
    var shoppingCartController : ShoppingCartViewController?
    
    init(mealOrderList: [IndexPath : OrderedMeal]) {
        self.mealOrderList = mealOrderList
        var coldDishes = [OrderedMeal]()
        var hotDishes = [OrderedMeal]()
        var soup = [OrderedMeal]()
        var drink = [OrderedMeal]()
        
        for meal in mealOrderList {
            if meal.key.section == 0 {
                coldDishes.append(meal.value)
            }
            if meal.key.section == 1 {
                hotDishes.append(meal.value)
            }
            if meal.key.section == 2 {
                soup.append(meal.value)
            }
            if meal.key.section == 3 {
                drink.append(meal.value)
            }
        }
        mealListBySections = [coldDishes, hotDishes, soup, drink]
    }
}

extension ShoppingCartDataSource : UITableViewDataSource{
    
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
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "ShoppingCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ShoppingCell  else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        
        // Fetches the appropriate meal for the data source layout.
        // let meal = mealList.mealList[indexPath.row]
        
        let meal = mealListBySections[indexPath.section][indexPath.row]
        
        print(meal)
        
        cell.index.text = String(indexPath.row+1)
        cell.mealName.text = meal.mealName
        cell.mealCount.text = String(meal.mealCount)
        
        cell.minus?.addTarget(self, action: #selector(self.adjustMealCount(_:)), for: .touchUpInside)
        cell.plus?.addTarget(self, action: #selector(self.adjustMealCount(_:)), for: .touchUpInside)
        
        //print("section number is \(indexPath.section)")
        return cell
    }
}

extension ShoppingCartDataSource{

    func adjustMealCount(_ sender: UIButton) {
        
        let contentView = sender.superview?.superview
        let cell = contentView?.superview as! ShoppingCell
        
        //寻找cell对应的tableView
        func superTableView() -> UITableView? {
            for view in sequence(first: cell.superview, next: { $0?.superview }) {
                if let tableView = view as? UITableView {
                    return tableView
                }
            }
            return nil
        }
        
        let firstTableView = superTableView()
        let index = firstTableView?.indexPath(for: cell)
        if sender.titleLabel?.text == "-"{
            if  mealListBySections[(index?.section)!][(index?.row)!].mealCount == 1
            {
                mealListBySections[(index?.section)!][(index?.row)!].mealCount = 1
            }
            else{
                mealListBySections[(index?.section)!][(index?.row)!].mealCount -= 1
 
            }
            print("已执行计算-")
        }
            
        else{
            print("已触发公式+")
            mealListBySections[(index?.section)!][(index?.row)!].mealCount += 1
  
        }
        //更新mealOrderList中的菜的数量
        let index1 = mealListBySections[(index?.section)!][(index?.row)!].index
        mealOrderList[index1]?.mealCount = mealListBySections[(index?.section)!][(index?.row)!].mealCount
        
        //update mealOrderList in stateController
        self.shoppingCartController?.stateController.saveMealOrderList(mealOrderList)
    
        //update shopping cart badge number
        let orderedMealCount = shoppingCartController?.stateController.countOrderedMealCount()
        updateShoppingCartIconBadgeNumber(orderedMealCount: orderedMealCount!)
        
        firstTableView?.reloadRows(at: [index!], with: .none)
    }
    
    func updateMealListBySections (){
        var coldDishes = [OrderedMeal]()
        var hotDishes = [OrderedMeal]()
        var soup = [OrderedMeal]()
        var drink = [OrderedMeal]()
        
        for meal in mealOrderList {
            if meal.key.section == 0 {
                coldDishes.append(meal.value)
            }
            if meal.key.section == 1 {
                hotDishes.append(meal.value)
            }
            if meal.key.section == 2 {
                soup.append(meal.value)
            }
            if meal.key.section == 3 {
                drink.append(meal.value)
            }
        }
        mealListBySections = [coldDishes, hotDishes, soup, drink]
    }
    
    func updateShoppingCartIconBadgeNumber(orderedMealCount : Int) {
        
        //find shopping cart badge
        let nav0 = shoppingCartController?.navigationController
        let nav0TabBar = nav0?.tabBarItem
        
        if orderedMealCount == 0 {
            nav0TabBar?.badgeValue = nil
        }
        else {
            nav0TabBar?.badgeValue = "\(orderedMealCount)"
        }
    }
}
