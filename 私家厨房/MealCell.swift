//
//  OrderMealTableViewCell.swift
//  私家厨房
//
//  Created by Will.Shan on 25/03/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit

class MealCell: UITableViewCell {

    @IBOutlet var mealName: UILabel!
    @IBOutlet var spicy: Spicy!
    @IBOutlet var photo: UIImageView!
    @IBOutlet weak var order = UIButton()
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
