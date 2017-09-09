//
//  ViewDetailVC.swift
//  私家厨房
//
//  Created by Will.Shan on 28/07/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit
import CoreData

class ViewDetailVC: UIViewController {
    
    //MARK: -Properties
    @IBOutlet weak var mealName: UILabel!
    @IBOutlet weak var spicy: Spicy!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var comment: UITextView!
    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var mealType: UILabel!
    //@IBOutlet weak var addToShoppingCart: UIButton!
    //@IBOutlet weak var back: UIButton!

    var meal: Meal!
    var photoFromOrderMeal : UIImage?
    
    //var addToShoppingCartLabel : String!
    
    let dateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

extension ViewDetailVC {
    //MARK: -LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = meal.mealName
        //let userName : String? = UserDefaults.standard.string(forKey: "user_name")

        //print("用户\(userName)邀请码为\(meal.invitationCode)")
        //MARK: -自定义UIBarButton,并添加方法
        var editButtonItem : UIBarButtonItem {
            //return UIBarButtonItem(title: "编辑", style: .plain, target: self, action: #selector(ViewDetailVC.editMeal(_:)))
            return UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(ViewDetailVC.editMeal(_:)))
        }
        
        navigationItem.rightBarButtonItem = editButtonItem
        
        photo.image = photoFromOrderMeal
        mealName.text = meal.mealName
        mealType.text = meal.mealType
        spicy.spicy = Int(meal.spicy)
        spicy.spicyCount = Int(meal.spicy)
        comment.text = meal.comment
        date.text = dateFormatter.string(from: meal.date! as Date)
        /*
        addToShoppingCart.addTarget(self, action: #selector(addToShoppingCart(_:)), for: .touchUpInside)
        if addToShoppingCartLabel == "加入菜单" {
            addToShoppingCart.isSelected = false
        }
        else {
            addToShoppingCart.isSelected = true
        }
        addToShoppingCart.setTitle("加入菜单", for: .normal)
        addToShoppingCart.setTitle("已加入", for: .selected)
        if addToShoppingCart.isSelected == true {
            //addToShoppingCart.backgroundColor = UIColor.white
            //addToShoppingCart.titleLabel?.textColor = UIColor.red
        }*/
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }
}

extension ViewDetailVC {
    //MARK: -Actions
    //func editMeal(_ sender : UIBarButtonItem){
    func editMeal(_ sender : UIBarButtonItem){
        print("edit func was performed")
        //if sender == navigationItem.rightBarButtonItem {
        self.performSegue(withIdentifier: "EditMealDetailSegue", sender: nil)
        //}
    }
    /*
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        dismiss(animated: true, completion: nil)
        /*let isPresentingInAddMealMode = presentingViewController is UINavigationController
         if isPresentingInAddMealMode {
         dismiss(animated: true, completion: nil)
         }*/
        //如果是Navigation的形式，则释放popViewController
        if let owningNavigationController = navigationController{
            owningNavigationController.popViewController(animated: true)
        }
        else {
            fatalError("The MealViewController is not inside a navigation controller.")
        }
    }
    
    @IBAction func back(_ sender: UIButton) {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        dismiss(animated: true, completion: nil)
        /*let isPresentingInAddMealMode = presentingViewController is UINavigationController
         if isPresentingInAddMealMode {
         dismiss(animated: true, completion: nil)
         }*/
        //如果是Navigation的形式，则释放popViewController
        if let owningNavigationController = navigationController{
            owningNavigationController.popViewController(animated: true)
        }
        else {
            fatalError("The MealViewController is not inside a navigation controller.")
        }
    }
    
    func addToShoppingCart(_ sender : UIButton) {
        if sender.isEnabled == true && sender.isSelected == false{
            //将按钮设为“已加入”
            sender.isSelected = true
        }
        else {
            //将按钮设为“加入菜单”
            sender.isSelected = false
        }
    }*/
}

extension ViewDetailVC {
    //MARK: -Segues
    //Add New Meal and show meal details
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "EditMealDetailSegue":
            guard let nav = segue.destination as? UINavigationController,let detailMealVC = nav.topViewController as? DetailMealViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            detailMealVC.meal = meal
            
            detailMealVC.photoFromOrderMeal = photoFromOrderMeal
            
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
    
}
