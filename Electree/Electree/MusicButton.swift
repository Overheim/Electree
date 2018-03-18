//
//  MusicButton.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 2. 22..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

enum MusicButtonType: Int {
	case open=0, play, stop
}

/// A class that draws the button which indicates the functionalities of playing the music
class MusicButton: UIButton {
	/// the type of music button(decides the functionality)
	var type: MusicButtonType
	
	/// the ratio of the point in drawing
	private let gridCount: CGFloat = 10
	
	override var isEnabled: Bool {
		didSet {
			if isEnabled {
				
			} else {
				
			}
			setNeedsDisplay()
		}
	}
	
	init(frame rect: CGRect, type: MusicButtonType) {
		self.type = type
		
		super.init(frame: rect)
		
		var image: UIImage?
		switch type {
		case .open:
			image = UIImage(named: "open.png")
		case .play:
			image = UIImage(named: "play.png")
		case .stop:
			image = UIImage(named: "stop.png")
		}
		setImage(image, for: .normal)
		imageView?.contentMode = .scaleAspectFill
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

