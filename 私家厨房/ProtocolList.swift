//
//  ProtocolList.swift
//  私家厨房
//
//  Created by Will.Shan on 06/01/2018.
//  Copyright © 2018 待定. All rights reserved.
//

import UIKit

@objc protocol DataTransferBackProtocol {
    @objc optional func stringTransferBack (string : String)
    @objc optional func dateTransferBack (date : Date)
}
