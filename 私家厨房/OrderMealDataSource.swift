//
//  OrderMealDataSource.swift
//  私家厨房
//
//  Created by Will.Shan on 26/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit
import CoreData

class OrderMealDataSource : NSObject {
    //MARK: -Properties
    //meals是实际tableview中用到的数据
    var meals : [Meal]?
    var mealListBySections : [[Meal]]
    //mealsToServe仅用于在服务器中进行删除操作
    //var mealsToServer : [MealToServer]?
    //var mealToServerListBySections : [[MealToServer]]
    //var photos = [String : UIImage]()
    var orderMealController : OrderMealController?
    
    //OrderedMeal是一个struct，用来记录mealName和mealCount
    var mealOrderList = [IndexPath : OrderedMeal]()
 
    init(meals: [Meal]?) {
        self.meals = meals
        
        self.mealListBySections = [[Meal]]()
        super.init()
        
        if self.meals != nil {
            self.updateMealListBySections()
            
        }
        else {
            self.meals = []
            self.updateMealListBySections()
        }
        
        //print(self.meals)
        //print(self.mealListBySections)
    }
}

extension OrderMealDataSource : UITableViewDataSource {
    //MARK: -Table setting
    func numberOfSections(in tableView: UITableView) -> Int {
        return mealListBySections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return mealListBySections[section].first?.mealType
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        //return mealList.mealList.count
        return mealListBySections[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "OrderMealCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? OrderMealCell  else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        
        // Fetches the appropriate meal for the data source layout.
        let meal = mealListBySections[indexPath.section][indexPath.row]
       
        cell.mealName.text = meal.mealName
        cell.spicy.spicy = Int(meal.spicy)
        cell.spicy.spicyCount = Int(meal.spicy)
        cell.photo.image = ImageStore().imageForKey(key: meal.identifier)
        //photos[meal.identifier!] = cell.photo.image
        
        //设置cell的背景和按钮
        cell.order?.isSelected = meal.cellSelected
        cell.order?.setTitle("加入菜单", for: .normal)
        cell.order?.setTitle("已加入", for: .selected)
        cell.order?.addTarget(self, action: #selector(addToShoppingCart(_:)), for: .touchUpInside)
        //print("设定单元格")
        return cell
    }
    
    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            // mealList.mealList.remove(at: indexPath.row)
            print("调用删除公式")
            
            let meal = mealListBySections[indexPath.section][indexPath.row]
            let title = "删除 \(meal.mealName)?"
            let message = "确认删除这道菜么?"
            let ac = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            ac.addAction(cancelAction)
            
            let deleteAction = UIAlertAction(title: "删除", style: .destructive, handler: {
                (action) -> Void in
                
                self.mealListBySections[indexPath.section].remove(at: indexPath.row)

                print("selected meal was removed")
                
                self.updateMeals()
                
                tableView.deleteRows(at: [indexPath], with: .fade)
                
                //数据都在本地，因此无须在服务器删除
                //self.deleteMealInServer(meal)
                
                //Delete meal in stateController
                self.orderMealController?.stateController.saveMeal(self.meals!) //added
                
                //Delete meal in coredata
                HandleCoreData.deleteData(meal.identifier)
            })
            ac.addAction(deleteAction)
            orderMealController?.present(ac, animated: true, completion: nil)
        }
        else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
}

extension OrderMealDataSource {
    //MARK: -Delete data in server
    func deleteMealInServer(_ meal : Meal) {
        // Delete in Parse server in background
        guard let query = MealToServer.query() else {
            return
        }
        query.getObjectInBackground(withId: meal.objectIDinServer!) { [unowned self] object, error in
            guard let mealToServer = object as? MealToServer
                else {
                    print(error)
                    return
            }
            mealToServer.deleteInBackground { [unowned self] succeeded, error in
                if succeeded {
                    print("***Deleted in server successfully***")
                } else if let error = error {
                    self.orderMealController?.showErrorView(error)
                    print("***failed to delete in server***")
                }
            }
        }
    }
}

extension OrderMealDataSource {
    //MARK: -Actions
    func addToShoppingCart(_ sender : UIButton) {
        
        print("data source selected")

        let contentView = sender.superview
     
        let cell = contentView?.superview as! OrderMealCell
        
        //这是一个非常牛逼的方法，用来找到cell的TableView
        func superTableView() -> UITableView? {
            for view in sequence(first: cell.superview, next: { $0?.superview }) {
                if let tableView = view as? UITableView {
                    return tableView
                }
            }
            return nil
        }
        
        let tableView = superTableView()
        
        let index = tableView?.indexPath(for: cell)
        print("index信息是\(String(describing: index))")
        
        if sender.isEnabled == true && sender.isSelected == false{
            
            //将按钮设为“已加入”
            sender.isSelected = true
            
            //更新数据源信息
            mealListBySections[index!.section][index!.row].cellSelected = true
            
            //将选中菜品加入mealOrderList
            mealOrderList[index!] = OrderedMeal(mealName: cell.mealName.text!, mealIdentifier: mealListBySections[index!.section][index!.row].identifier, mealCount: 1, index: index! )

        }
        else {
            //将按钮设为“加入菜单”
            sender.isSelected = false
            
            //更新数据源信息
            mealListBySections[index!.section][index!.row].cellSelected = false
            mealOrderList.removeValue(forKey: index!)
        }

        //update mealOrderList in stateController
        orderMealController?.stateController.saveMealOrderList(mealOrderList)
        
        
        //update shopping cart badge number
        let orderedMealCount = orderMealController?.stateController.countOrderedMealCount()
        updateShoppingCartIconBadgeNumber(orderedMealCount: orderedMealCount!)
        
        print("被选中的菜有\(mealOrderList.enumerated())")
        print("stateController中被选中的菜有\(String(describing: orderMealController?.stateController.mealOrderList.enumerated()))")
    }
    

    //更新数据
    func updateMealListBySections(){
        var coldDishes = [Meal]()
        var hotDishes = [Meal]()
        var soup = [Meal]()
        var drink = [Meal]()
        
        for meal in meals! {
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
        mealListBySections = [coldDishes,hotDishes,soup,drink]
    }

    //更新数据
    func updateMeals(){
        let coldDishes = mealListBySections[0]
        let hotDishes = mealListBySections[1]
        let soup = mealListBySections[2]
        let drink = mealListBySections[3]
        
        meals = coldDishes + hotDishes + soup + drink
    }
    
    func updateShoppingCartIconBadgeNumber(orderedMealCount : Int) {
        
        //find shopping cart badge
        let nav0 = orderMealController?.navigationController
        let tabNav = nav0?.tabBarController
        let nav1TabBar = tabNav?.viewControllers?[1].tabBarItem
        if orderedMealCount == 0 {
            nav1TabBar?.badgeValue = nil
        }
        else {
            nav1TabBar?.badgeValue = "\(orderedMealCount)"
        }
    }
}


