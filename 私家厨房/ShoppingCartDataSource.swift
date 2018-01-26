//
//  ShoppingCartDataSource.swift
//  私家厨房
//
//  Created by Will.Shan on 27/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit

class ShoppingCartDataSource : NSObject {
    var mealListBySections : [[Meal]]
    //OrderedMeal是一个struct，用来记录mealName和mealCount
//    var mealOrderList : [IndexPath : OrderedMeal]!
    var shoppingCartController : ShoppingCartVC?
    var selectedMeals : [Meal]?
    var selectedMealsCount : Int
//    var tableViewHeight : Int!
    
    init(selectedMeals: [Meal]) {
        self.selectedMeals = selectedMeals
        selectedMealsCount = selectedMeals.count
        var coldDishes = [Meal]()
        var hotDishes = [Meal]()
        var soup = [Meal]()
        var drink = [Meal]()
        
        
        for meal in selectedMeals {
            if meal.mealType == "凉菜" {
                coldDishes.append(meal)
            }
            if meal.mealType == "热菜" {
                hotDishes.append(meal)
            }
            if meal.mealType == "汤" {
                soup.append(meal)
            }
            if meal.mealType == "酒水" {
                drink.append(meal)
            }
        }
        mealListBySections = [coldDishes, hotDishes, soup, drink]
        //Get tableView height
//        tableViewHeight = selectedMealsCount*44
//        var tableHeaderCount = 0
//        if coldDishes.count != 0 {
//            tableHeaderCount = tableHeaderCount + 1
//        }
//        if hotDishes.count != 0 {
//            tableHeaderCount = tableHeaderCount + 1
//        }
//        if soup.count != 0 {
//            tableHeaderCount = tableHeaderCount + 1
//        }
//        if drink.count != 0 {
//            tableHeaderCount = tableHeaderCount + 1
//        }
//        tableViewHeight = tableViewHeight + tableHeaderCount*18
//        if tableViewHeight < 250 {
//            tableViewHeight = 250
//        }
    }
}

extension ShoppingCartDataSource : UITableViewDataSource, UITableViewDelegate{
    
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
        let cellIdentifier = TableCellReusableID.shoppingCart
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ShoppingCell  else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        
        let meal = mealListBySections[indexPath.section][indexPath.row]
        
        cell.index.text = String(indexPath.row+1)
        cell.mealName.text = meal.mealName

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        shoppingCartController?.dismissKeyBoard()
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            // mealList.mealList.remove(at: indexPath.row)
            print("调用删除公式")
            
            let meal = mealListBySections[indexPath.section][indexPath.row]
            let title = "取消 \(meal.mealName)?"
            let message = "确认取消这道菜么?"
            let ac = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            ac.addAction(cancelAction)
            
            let deleteAction = UIAlertAction(title: "删除", style: .destructive, handler: {
                (action) -> Void in
                
                self.mealListBySections[indexPath.section].remove(at: indexPath.row)
                
                print("selected meal was removed")
                
                tableView.deleteRows(at: [indexPath], with: .fade)

                //update meal in coredata
                HandleCoreData.updateMealSelectionStatus(identifier: meal.identifier)
                self.selectedMealsCount = self.selectedMealsCount - 1
                self.updateShoppingCartIconBadgeNumber(orderedMealCount: self.selectedMealsCount)
                
                //read shoppingCartList from disk
                var shoppingCartList = NSKeyedUnarchiver.unarchiveObject(withFile: ShoppingCartList.ArchiveURL.path) as? ShoppingCartList
                
                //remove deleted meal from shoppingCartlist
                var orderedMealIdentifers = self.shoppingCartController!.shoppingCartList!.mealsIdentifiers!
                for i in 0..<orderedMealIdentifers.count {
                    if orderedMealIdentifers[i] == meal.identifier {
                        orderedMealIdentifers.remove(at: i)
                        break
                    }
                }

                //save shoppingCartList to disk
                shoppingCartList?.mealsIdentifiers = orderedMealIdentifers
                NSKeyedArchiver.archiveRootObject(shoppingCartList, toFile: ShoppingCartList.ArchiveURL.path)
                
            })
            ac.addAction(deleteAction)
            shoppingCartController?.present(ac, animated: true, completion: nil)
        }
        else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
}

extension ShoppingCartDataSource{
    
    func updateMealListBySections (){
        var coldDishes = [Meal]()
        var hotDishes = [Meal]()
        var soup = [Meal]()
        var drink = [Meal]()
        
        for meal in selectedMeals! {
            if meal.mealType == "凉菜" {
                coldDishes.append(meal)
            }
            if meal.mealType == "热菜" {
                hotDishes.append(meal)
            }
            if meal.mealType == "汤" {
                soup.append(meal)
            }
            if meal.mealType == "酒水" {
                drink.append(meal)
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
