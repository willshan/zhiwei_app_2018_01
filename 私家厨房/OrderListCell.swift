//
//  OrderListTableViewCell.swift
//  私家厨房
//
//  Created by Will.Shan on 12/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit

class OrderListCell: UITableViewCell {

    @IBOutlet weak var index: UILabel!
    @IBOutlet weak var mealName: UILabel!
    @IBOutlet weak var mealCount: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
