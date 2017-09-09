//
//  OrderMealTableViewController.swift
//  私家厨房
//
//  Created by Will.Shan on 25/03/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit
import os.log
import CoreData

//合并后使用该class
class OrderMealController: UITableViewController {
    //MARK: -Properties
    var stateController : StateController!
    //var stateController = StateController(MealStorage())
    //fileprivate var dataSource: OrderMealDataSource!
    var dataSource: OrderMealDataSource!
}

extension OrderMealController{
    //MARK: -Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        print("start viewDidLoad")
        //受限于服务器的储存量和费用，一般不上传服务器，只保存在本地coredata，只在分享时上传到服务器。
        //let userName : String? = UserDefaults.standard.string(forKey: "user_name")
        //HandleCoreData.clearCoreData(userName!)
        
        //loadMealsFromServer()
        
        print("end viewDidLoad")
        
        //添加聊天管理代理
        EMClient.shared().chatManager.add(self, delegateQueue: nil)
        
        // Use the edit button item provided by the table view controller.
        navigationItem.leftBarButtonItem = editButtonItem
    }
    
    //这一步在unwind之后调用
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        print("view will appear in OrderMealVC")
        dataSource = OrderMealDataSource(meals: stateController.meals)

        dataSource.orderMealController = self
        //dataSource.orderedMealCount = stateController.countOrderedMealCount()
        
        if stateController.mealOrderList != nil {
            dataSource.mealOrderList = stateController.mealOrderList
        }
        tableView.dataSource = dataSource
        //tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        //stateController.updateMealOrderList(dataSource.mealOrderList)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        //loadMealsFromServer()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension OrderMealController {
    //MARK: -Get data from server
    //func loadMealsFromServer(completion : @escaping () -> Void ) {
    func loadMealsFromServer() {
        print("func loadMealsFromServer is loaded")
        
        guard let query = MealToServer.query() else {
            return
        }
        
        query.countObjectsInBackground { [unowned self] count, error in
            if Int(count) == self.stateController.meals?.count {
            return
        }
                
        else {
        query.findObjectsInBackground { [unowned self] objects, error in
            guard let objects = objects as? [MealToServer]
                else {
                    self.showErrorView(error)
                    return
            }

            //Clear coredata first
            //print((PFUser.current()?.username)!)
            let userName : String? = UserDefaults.standard.string(forKey: "user_name")

            //clear coreData
            HandleCoreData.clearCoreData(userName!)
            
            //download from server
            for object in objects {
                if object.userName == userName {
                    //print("object的user为\(object.user)")
                    //print("current的user为\(PFUser.current())")
					
					//添加数据到coreData
					let meal = HandleCoreData.insertData(mealToServer: object, meal: nil)
                    print("***the identifier for the meal is \(String(describing: meal.identifier))")
                    
                    self.stateController.addMeal(meal)
                    
                    self.dataSource = OrderMealDataSource(meals: self.stateController.meals)
                    self.tableView.dataSource = self.dataSource
                    self.dataSource.orderMealController = self
                    self.tableView.reloadData()
                    
                    object.photo?.getDataInBackground { [unowned self] data, error in
                            guard let data = data,
                                let image = UIImage(data: data) else {
                                    return
                        }
                        //添加图片到Disk
                        ImageStore().setImage(image: image, forKey: meal.identifier)
                    }
                }
                //print("**3**共找到了的meals数量为\(meals.count)")
            }
            print("**************001")
            print("********该用户有\(String(describing: self.stateController.meals?.count))道菜！！***********")

            self.dataSource = OrderMealDataSource(meals: self.stateController.meals)
            print("**************002")
            
            self.tableView.dataSource = self.dataSource
            print("**************003")
            
            self.dataSource.orderMealController = self
            self.tableView.reloadData()
            print("func loadMealsFromServer is loaded")
            }
        }
        }
    }
}


extension OrderMealController {
    //MARK: -Segus
    //Add New Meal and show meal details
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch(segue.identifier ?? "") {
            
        case "AddNewMeal":
            os_log("Adding a new meal.", log: OSLog.default, type: .debug)
            
        case "ShowDetailSegue":
            
            guard let viewDetailVC = segue.destination as? ViewDetailVC else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedMealCell = sender as? OrderMealCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedMealCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedMeal = self.dataSource.mealListBySections[indexPath.section][indexPath.row]
            print("***************\(selectedMeal)")
            
            viewDetailVC.meal = selectedMeal
            
            viewDetailVC.photoFromOrderMeal = ImageStore().imageForKey(key: selectedMeal.identifier)
            //cell.order?.setTitle("加入菜单", for: .normal)
            //viewDetailVC.addToShoppingCartLabel = selectedMealCell.order?.titleLabel?.text
            
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
    @IBAction func saveUnwindToMealList(sender: UIStoryboardSegue) {
        let sourceViewController = sender.source as? PersonalSetViewController
        navigationItem.title = sourceViewController?.mealListName.text
        
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        }
    
    @IBAction func unwindFromOrderCenter(sender: UIStoryboardSegue) {
        return
    }
    
    @IBAction func unwindToMealList(sender: UIStoryboardSegue) {
        print("transfered data to orderMeal")
        if let sourceViewController = sender.source as? DetailMealViewController, let meal = sourceViewController.meal, let photochanged : Bool = sourceViewController.photochanged {
            print("*****DetailMealViewController的meal不为空")
            // Save to Parse server in background

            let uploadImage = sourceViewController.photoFromOrderMeal ?? UIImage(named: "defaultPhoto")
            //只能转化为PNG的格式保存到Parse，PNEG的不行，上传不了
            //let pictureData = UIImagePNGRepresentation(uploadImage!)
            //let file = PFFile(name: "photo", data: pictureData!)

            //Determine update meal or add new meal
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                //Update an existing meal
                if meal.mealType != dataSource.mealListBySections[selectedIndexPath.section].first?.mealType {
                    //移出数据
                    dataSource.mealListBySections[selectedIndexPath.section].remove(at: selectedIndexPath.row)
                    //移出表格
                    let indexPath = IndexPath(row: selectedIndexPath.row, section: selectedIndexPath.section)
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                    
                    if meal.mealType == "凉菜" {
                        let newIndexPath = IndexPath(row: dataSource.mealListBySections[0].count, section: 0)
                        dataSource.mealListBySections[0].append(meal)
                        tableView.insertRows(at: [newIndexPath], with: .automatic)
                    }
                    if meal.mealType == "热菜" {
                        let newIndexPath = IndexPath(row: dataSource.mealListBySections[1].count, section: 1)
                        dataSource.mealListBySections[1].append(meal)
                        tableView.insertRows(at: [newIndexPath], with: .automatic)
                    }
                    if meal.mealType == "汤" {
                        let newIndexPath = IndexPath(row: dataSource.mealListBySections[2].count, section: 2)
                        dataSource.mealListBySections[2].append(meal)
                        tableView.insertRows(at: [newIndexPath], with: .automatic)
                    }
                    if meal.mealType == "酒水" {
                        let newIndexPath = IndexPath(row: dataSource.mealListBySections[3].count, section: 3)
                        dataSource.mealListBySections[3].append(meal)
                        tableView.insertRows(at: [newIndexPath], with: .automatic)
                    }
                }
                    
                else {
                    dataSource.mealListBySections[selectedIndexPath.section][selectedIndexPath.row] = meal
                    tableView.reloadRows(at: [selectedIndexPath], with: .none)
                }
                
                //服务器中更新菜
                /*新规则，受限于服务器空间，不向服务器上传，只在share时上传。
                guard let query = MealToServer.query() else {
                    return
                }

                query.getObjectInBackground(withId: meal.objectIDinServer!) { [unowned self] object, error in
                    guard let object = object as? MealToServer
                        else {
                            self.showErrorView(error)
                            return
                    }

                    //let object = try? PFQuery.getObjectOfClass("MealToServerTest", objectId: meal.objectIDinServer!) as! MealToServer //这一步占用了app主线程太长时间
                object.mealName = meal.mealName
                object.mealType = meal.mealType
                object.spicy = Int(meal.spicy)
                object.comment = meal.comment!
                    
                //如果图片变化则重新储存，如果没有则不储存
                if photochanged == true {
                    object.photo = file
                }
                
                    object.saveInBackground(){ [unowned self] succeeded, error in
                        if succeeded {
                           
                            print("***updated in server successfully***")
                    
                        } else if let error = error {
                            self.showErrorView(error)
                            print("***failed to update in server***")
                        }
                    }
                }
                 */
            }
            else {
                //Add a new meal
                if meal.mealType == "凉菜" {
                    let newIndexPath = IndexPath(row: dataSource.mealListBySections[0].count, section: 0)
                    dataSource.mealListBySections[0].append(meal)
                    tableView.insertRows(at: [newIndexPath], with: .automatic)
                }
                if meal.mealType == "热菜" {
                    let newIndexPath = IndexPath(row: dataSource.mealListBySections[1].count, section: 1)
                    dataSource.mealListBySections[1].append(meal)
                    tableView.insertRows(at: [newIndexPath], with: .automatic)
                }
                if meal.mealType == "汤" {
                    let newIndexPath = IndexPath(row: dataSource.mealListBySections[2].count, section: 2)
                    dataSource.mealListBySections[2].append(meal)
                    tableView.insertRows(at: [newIndexPath], with: .automatic)
                }
                if meal.mealType == "酒水" {
                    let newIndexPath = IndexPath(row: dataSource.mealListBySections[3].count, section: 3)
                    dataSource.mealListBySections[3].append(meal)
                    tableView.insertRows(at: [newIndexPath], with: .automatic)
                }
                
                //服务器中添加新菜
                /*
                let object = MealToServer(mealname: meal.mealName, photo: file, spicy: Int(meal.spicy), comment: meal.comment, mealType: meal.mealType, userName: (PFUser.current()?.username!)!, date: meal.date!, identifier : meal.identifier)
                
                object!.saveInBackground { [unowned self] succeeded, error in
                    if succeeded {
                        HandleCoreData.updateObjectIDinServer(identifier : object!.identifier, objectIDinServer : object!.objectId!)
                        print("***save to server successfully***")
                        print("***objectID is \(object!.objectId!)***")
                    } else if let error = error {
                        self.showErrorView(error)
                        print("***failed to save to server***")
                    }
                }*/
            }

            //添加图片到Disk
            ImageStore().setImage(image: uploadImage!, forKey: meal.identifier)
            
            //添加图片到datasource.photos
            //self.dataSource.photos[meal.identifier] = uploadImage
            
            // Save the meals to stateControler
            dataSource.updateMeals()
            stateController?.saveMeal(dataSource.meals!)
        }
    }
}

//MARK: -监听消息列表
extension OrderMealController : EMChatManagerDelegate{
    func conversationListDidUpdate(_ aConversationList: [Any]!) {
        self.showTabBarBadge()
    }
    
    func messagesDidReceive(_ aMessages: [Any]!) {
        self.showTabBarBadge()
    }
    
    func showTabBarBadge() {
        let conversations = EMClient.shared().chatManager.getAllConversations() as! [EMConversation]
        var unreadMessageCount = 0
        for conv in conversations {
            unreadMessageCount += Int(conv.unreadMessagesCount)
        }
        let nav0 = self.navigationController
        let tabNav = nav0?.tabBarController
        let nav2 = tabNav?.viewControllers?[2]
        
        if unreadMessageCount == 0 {
            nav2?.tabBarItem.badgeValue = nil
        }
        else {
            
            nav2?.tabBarItem.badgeValue = "\(unreadMessageCount)"
        }
    }
}
