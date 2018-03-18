//
//  ComponentButton.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 4..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

/// A button that is used when the user choose a electric circuit component. Only the look of the button is set in this class.
class ComponentButton: UIButton {
	/// This color is changed when the user chooses a component
	@IBInspectable var chosenColor: UIColor = UIColor.white
	
	/// Shows this button is chosen
	@IBInspectable var chosen: Bool = false {
		didSet {
			backgroundColor = chosen ? chosenColor : UIColor.white.withAlphaComponent(0.5)
			layer.shadowColor = chosen ? chosenColor.withAlphaComponent(1).cgColor : UIColor.white.cgColor
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		// Set image scale option
		imageView?.contentMode = .scaleAspectFit
		
		// Bounds the image, add the shadow effect
		let menuImageSize = self.frame.width
		layer.cornerRadius = menuImageSize / 2
		layer.masksToBounds = false
		layer.shadowOpacity = 1
		layer.shadowOffset = CGSize.zero
		layer.shadowRadius = 10
		clipsToBounds = true
	}
}
