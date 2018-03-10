//
//  DatePopUpVC.swift
//  私家厨房
//
//  Created by Will.Shan on 04/01/2018.
//  Copyright © 2018 待定. All rights reserved.
//

import UIKit

class DatePopUpVC: UIViewController {

    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var saveButton: UIButton!
    @IBAction func cancel(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    var delegate : DataTransferBackProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func dismissPopUP(_ sender: Any) {
        dismiss(animated: true)
        let date = datePicker.date
        delegate?.dateTransferBack!(date: date)
    }
}
