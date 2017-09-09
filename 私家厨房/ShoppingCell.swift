//
//  ShppingCell.swift
//  私家厨房
//
//  Created by Will.Shan on 03/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit

class ShoppingCell: UITableViewCell {

    @IBOutlet weak var index: UILabel!
    @IBOutlet weak var mealName: UILabel!
    @IBOutlet weak var mealCount: UILabel!
    @IBOutlet weak var minus: UIButton!
    @IBOutlet weak var plus: UIButton!
    
    //var mealCountNumber = 1
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
