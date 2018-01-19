//
//  CatagoryPopUpVC.swift
//  私家厨房
//
//  Created by Will.Shan on 06/01/2018.
//  Copyright © 2018 待定. All rights reserved.
//

import UIKit

class CatagoryPopUpVC: UIViewController {
    var catagory = [String]()
    var delegate : DataTransferBackProtocol?
    var selectedCatagory = "请选择"
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var catagoryPicker: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //catagory = ["冷菜","热菜","汤","酒水"]
        catagoryPicker.dataSource = self
        catagoryPicker.delegate = self
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func Cancel(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true)
    }
    
    @IBAction func dismissPopUP(_ sender: Any) {
        dismiss(animated: true)
        delegate?.stringTransferBack!(string: selectedCatagory)
    }
}

extension CatagoryPopUpVC : UIPickerViewDataSource, UIPickerViewDelegate {
    //设置选择框的列数为1列,继承于UIPickerViewDataSource协议
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    //设置选择框的行数为3行，继承于UIPickerViewDataSource协议
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return catagory.count
    }
    //设置选择框各选项的内容，继承于UIPickerViewDelegate协议
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int,
                    forComponent component: Int) -> String? {
        print("func 1 was runing")
        selectedCatagory = catagory[row]
        return catagory[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("func 2 was runing")
        selectedCatagory = catagory[row]
    }
    
}
