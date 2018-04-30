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
        let storyboard = UIStoryboard(name: StoryboardID.main, bundle: nil)
        todayVC = storyboard.instantiateViewController(withIdentifier: StoryboardID.orderListCenterVC) as? OrderListCenterVC
        todayVC?.view.backgroundColor = UIColor.blue
        reservedVC = storyboard.instantiateViewController(withIdentifier: StoryboardID.orderListCenterVC) as? OrderListCenterVC
        reservedVC?.view.backgroundColor = UIColor.red
        histroyVC = storyboard.instantiateViewController(withIdentifier: StoryboardID.orderListCenterVC) as? OrderListCenterVC
        histroyVC?.view.backgroundColor = UIColor.gray

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
        self.transition(from: oldVC, to: newVC, duration: 0, options: UIViewAnimationOptions.transitionCrossDissolve, animations: nil) { (success) in
            if success {
                newVC.didMove(toParentViewController: self)
                oldVC.willMove(toParentViewController: nil)
                oldVC.removeFromParentViewController()
                self.currentVC = newVC
            }
            else {
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
