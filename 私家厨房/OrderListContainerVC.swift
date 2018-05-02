//
//  OrderListContainerVC.swift
//  私家厨房
//
//  Created by 单志伟 on 2018/4/28.
//  Copyright © 2018 待定. All rights reserved.
//

import UIKit

class OrderListContainerVC: UIViewController {
    
    var currentVC : OrderListCenterVC!
    var todayVC : OrderListCenterVC?
    var reservedVC : OrderListCenterVC?
    var histroyVC : OrderListCenterVC?

    override func viewDidLoad() {
        super.viewDidLoad()
       
        setSegmentedControl()
        setVCs()

        self.addChildViewController(todayVC!)
        self.view.addSubview(todayVC!.view)
        self.currentVC = todayVC
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setSegmentedControl() {
        let titles = ["今日","预定","历史"]
        let segmentedControl = UISegmentedControl(items: titles)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.frame = CGRect(x: 0, y: 0, width: 200, height: 29)
        segmentedControl.addTarget(self, action: #selector(self.indexChanged(sender:)), for: .valueChanged)
        self.navigationItem.titleView = segmentedControl
        
    }
    
    func setVCs() {
        let reservedMealsHistory = StateController.share.readReservedMealsHistoryFromDisk()
        //将订单分类
        //用这种方法加载tableview速度很慢，下次考虑用coredata试试
        //segmented control的切换也很慢，考虑解决方法
        let todayDate = MainVC.dateConvertString(date: Date())
        var todayMeals = [ReservedMeals]()
        var reservedMeals = [ReservedMeals]()
        var historyMeals = [ReservedMeals]()
        for mealsList in reservedMealsHistory! {
            if mealsList.date == todayDate {
                todayMeals.append(mealsList)
            }
            else if mealsList.date > todayDate {
                reservedMeals.append(mealsList)
            }
            else {
                historyMeals.append(mealsList)
            }
        }
        print(todayMeals.count)
        print(reservedMeals.count)
        print(historyMeals.count)
        
        let storyboard = UIStoryboard(name: StoryboardID.main, bundle: nil)
        todayVC = storyboard.instantiateViewController(withIdentifier: StoryboardID.orderListCenterVC) as? OrderListCenterVC
        todayVC?.reservedMealsHistory = todayMeals
        //对应VC的viewdidload在这之后运行
//        todayVC?.dataSource = OrderListCenterDataSource.init(todayMeals)
//        todayVC?.tableView.dataSource = todayVC?.dataSource
        
        reservedVC = storyboard.instantiateViewController(withIdentifier: StoryboardID.orderListCenterVC) as? OrderListCenterVC
        reservedVC?.reservedMealsHistory = reservedMeals
//        reservedVC?.dataSource = OrderListCenterDataSource.init(reservedMeals)
//        reservedVC?.tableView.dataSource = reservedVC?.dataSource
        
        histroyVC = storyboard.instantiateViewController(withIdentifier: StoryboardID.orderListCenterVC) as? OrderListCenterVC
        histroyVC?.reservedMealsHistory = historyMeals
//        histroyVC?.dataSource = OrderListCenterDataSource.init(historyMeals)
//        histroyVC?.tableView.dataSource = histroyVC?.dataSource
    }
    
    //option 1:
    @objc func indexChanged(sender: UISegmentedControl) {
        print("func indexChanged was used")
        if (self.currentVC == todayVC && sender.selectedSegmentIndex == 0) || (self.currentVC == reservedVC && sender.selectedSegmentIndex == 1) || (self.currentVC == histroyVC && sender.selectedSegmentIndex == 2) {
            return
        }
        else {
            switch sender.selectedSegmentIndex
            {
            case 0:
                self.replaceController(oldVC: currentVC, newVC: todayVC!)
                break
            case 1:
                self.replaceController(oldVC: currentVC, newVC: reservedVC!)
                break
            case 2:
                self.replaceController(oldVC: currentVC, newVC: histroyVC!)
                break
            default:
                break;
            }
        }
    }
    //option 2:
//    @objc func indexChanged(sender: UISegmentedControl) {
//
//
//    }
    
    func replaceController(oldVC : OrderListCenterVC, newVC : OrderListCenterVC) {
        print("func replaceController was used")
        self.addChildViewController(newVC)
        self.transition(from: oldVC, to: newVC, duration: 0.5, options: UIViewAnimationOptions.curveLinear, animations: nil) { (success) in
            if success {
                print("success")
                newVC.didMove(toParentViewController: self)
                oldVC.willMove(toParentViewController: nil)
                oldVC.removeFromParentViewController()
                self.currentVC = newVC
            }
            else {
                print("fail")
                self.currentVC = oldVC
            }
        }
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
