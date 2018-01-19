//
//  ResetPasswordViewController.swift
//  ParseDemo
//
//  Created by Rumiya Murtazina on 7/31/15.
//  Copyright (c) 2015 abearablecode. All rights reserved.
//

import UIKit

class ResetPasswordViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var emailField: UITextField!

    //Actually, no email for reset password will be sent to the email.
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func passwordReset(_ sender: AnyObject) {
        let email = self.emailField.text
        //var finalEmail = email.stringByTrimmingCharactersInSet(CharacterSet.whitespaceCharacterSet())
        let finalEmail = email?.trimmingCharacters(in: CharacterSet.whitespaces)
        
        // Send a request to reset a password
        //PFUser.requestPasswordResetForEmailInBackground(finalEmail!)老语法
        PFUser.requestPasswordResetForEmail(inBackground: finalEmail!)
        
        let alert = UIAlertController (title: "Password Reset", message: "An email containing information on how to reset your password has been sent to " + finalEmail! + ".", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func dismissKeyBoard(_ sender: UITapGestureRecognizer){
        emailField.resignFirstResponder()
        
    }
    
    @IBAction func dismissKeyBoard2(_ sender: UITapGestureRecognizer){
        emailField.resignFirstResponder()
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
