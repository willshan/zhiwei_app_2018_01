//
//  MyOrderListTableViewCell.swift
//  私家厨房
//
//  Created by Will.Shan on 23/04/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit

class OrderListCenterCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    @IBOutlet weak var dishes: UILabel!
    @IBOutlet weak var drink: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var photoCollection: UICollectionView!

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
