//
//  Spicy.swift
//  私家厨房
//
//  Created by Will.Shan on 05/03/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit
//@IBDesignable就是让这个class的view在storyboard上可见，不需要run就能看到
@IBDesignable class Spicy: UIStackView {

        //MARK: Properties
        
    private var spicyButtons = [UIButton]()
        
        var spicy = 0 {
            didSet {
                updateButtonSelectionStates()
            }
        }
    

    //@IBInspectable 让其后面跟着的变量，在IB中就可以直接调整
        @IBInspectable var spicySize: CGSize = CGSize(width: 32.0, height: 40.0) {
            didSet {
                setupButtons()
            }
        }
    
//didset就是变量改变后，立即执行didset{}内的code
        @IBInspectable var spicyCount: Int = 5 {
            didSet {
                setupButtons()
            }
        }
        
        //MARK: Initialization
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupButtons()
        }
    
    //superclass里有required，subclass里也必须有
        required init(coder: NSCoder) {
            super.init(coder: coder)
            setupButtons()
        }
        
        //MARK: Button Action
        //ratingButtonTapped按钮点击后会有什么action，在这里写出来
    @objc func ratingButtonTapped(button: UIButton) {
            //先找到点击的那个button在spicyButtons中处于第几个index
            guard let index = spicyButtons.index(of: button) else {
                fatalError("The button, \(button), is not in the ratingButtons array: \(spicyButtons)")
            }
            
            // Calculate the rating of the selected button
            let selectedRating = index + 1
            
            //此处即同一个辣椒点击两次，就变成0
            if selectedRating == spicy {
                // If the selected star represents the current rating, reset the spicy to 0.
                spicy = 0
            } else {
                // Otherwise set the rating to the selected star，否则就重新设定spicy。spicy重新设定完成后，就会在didset里调用updateButtonSelectionStates
                spicy = selectedRating
                
            }
        }
        
        
        //MARK: Private Methods
        //setupButtons 先设置一些buttons，并将它们放在stackview里
        private func setupButtons() {
            
            // Clear any existing buttons，目的是每次调用setupButtons方法是，先将view上的button清空，然后再根据新的变量，重新设置view
            for button in spicyButtons {
                //第一步removeArrangedSubview是StackView中的一个方法，它将button从stackview的管理list中去掉，这个button不会再用来计算大小和位置，但是button仍然存在.
                removeArrangedSubview(button)
                //第二步removeFromSuperview，将button从superview中去掉
                button.removeFromSuperview()
            }
            //所有button都去掉后，将变量spicyButton清零
            spicyButtons.removeAll()
            
            // Load Button Images
            let bundle = Bundle(for: type(of: self))
            let redSpicy = UIImage(named: AssetNames.redSpicy, in: bundle, compatibleWith: self.traitCollection)
            let graySpicy = UIImage(named: AssetNames.graySpicy, in: bundle, compatibleWith: self.traitCollection)

            //for in此处用来，根据提供的spicyCount这个变量，来设置button的数量
            for index in 0..<spicyCount {
                // Create the button
                let button = UIButton()
                
                // Set the button images
                button.setImage(graySpicy, for: .normal)
                button.setImage(redSpicy, for: .selected)

                
                // Add constraints
                //translatesAutoresizingMaskIntoConstraints是默认的constraint方式，当使用autolayout时，先把它关掉
                button.translatesAutoresizingMaskIntoConstraints = false
                //以下两个是将button的高度和宽度，设置成和spicy的高度宽度一致。
                button.heightAnchor.constraint(equalToConstant: spicySize.height).isActive = true
                button.widthAnchor.constraint(equalToConstant: spicySize.width).isActive = true
                
                // Set the accessibility label
                button.accessibilityLabel = "Set \(index + 1) star rating"
                
                // Setup the button action，本class中，所有的action都是通过code来完成，并没有从IB中有连接过来，下面的code跟@IBAction达到的目的一致。将屏幕上的每个按钮都连接这个action
                button.addTarget(self, action: #selector(Spicy.ratingButtonTapped(button:)), for: .touchUpInside)
                
                // Add the button to the stack
                addArrangedSubview(button)
                
                // Add the new button to the rating button array，该class的变量数组spicyButtons，来记录button
                spicyButtons.append(button)
            }
            
            updateButtonSelectionStates()
        }
    
    //更新button的选定状态
        private func updateButtonSelectionStates() {
            for (index, button) in spicyButtons.enumerated() {
                // If the index of a button is less than the rating, that button should be selected.
                button.isSelected = index < spicy
                
                // Set accessibility hint and value
                let hintString: String?
                if spicy == index + 1 {
                    hintString = "Tap to reset the rating to zero."
                } else {
                    hintString = nil
                }
                
                let valueString: String
                switch (spicy) {
                case 0:
                    valueString = "No rating set."
                case 1:
                    valueString = "1 star set."
                default:
                    valueString = "\(spicy) stars set."
                }
                
                button.accessibilityHint = hintString
                button.accessibilityValue = valueString
            }
        }
}
