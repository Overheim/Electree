//
//  CheckBox.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 22..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

class CheckBox: UIImageView {
	@IBInspectable private var uncheckedImage: UIImage?
	@IBInspectable private var checkedImage: UIImage?
	
	@IBInspectable var isChecked: Bool = false {
		didSet {
			if isChecked {
				image = checkedImage
				didCheck?()
			} else {
				image = uncheckedImage
				didUncheck?()
			}
			
			if oldValue != isChecked {
				didChangeValue?(isChecked)
			}
		}
	}
	
	var didCheck: (()->())?
	var didUncheck: (()->())?
	var didChangeValue: ((Bool)->())?
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		isUserInteractionEnabled = true
		addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(check)))
	}
	
	@objc private func check() {
		isChecked = !isChecked
	}
}
