//
//  PersonalSetViewController.swift
//  私家厨房
//
//  Created by Will.Shan on 22/07/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit

class PersonalSetVC: UIViewController {

    @IBOutlet weak var mealListName: UITextField!
    @IBOutlet weak var cookerName: UITextField!
    @IBOutlet weak var saveButton : UIBarButtonItem!

}

extension PersonalSetVC {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.navigationController?.tabBarController?.tabBar.isHidden = true
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension PersonalSetVC : UITextFieldDelegate{
    //MARK: UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Disable the Save button while editing.
        saveButton.isEnabled = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func dismissKeyBoard(_ sender: UITapGestureRecognizer){
        mealListName?.resignFirstResponder()
        cookerName?.resignFirstResponder()
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        dismiss(animated: true, completion: nil)

        //如果是Navigation的形式，则释放popViewController
        if let owningNavigationController = navigationController{
            owningNavigationController.popViewController(animated: true)
        }
        else {
            fatalError("The MealViewController is not inside a navigation controller.")
        }
    }
    
}
