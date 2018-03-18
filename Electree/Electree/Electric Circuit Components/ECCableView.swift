//
//  ECCableView.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 8..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

/// A cable view which connects between two electric circuit components.
class ECCableView: UIView {
	/// Thickness of the cable(by grid)
	private let gThickness: CGFloat = 0.25
	
	/// Length of the cable(by grid)
	var gLength: CGFloat
	
	/// Direction of the cable
	var direction: ECComponentDirection
	
	/// A flag for the extension cable
	var isExtension = false
	
	var id: String
	
	/// Initializer of the cable view
	///
	/// - Parameters:
	///   - gOrigin: origin by grid
	///   - id: id
	///   - gLength: length
	///   - direction: direction
	///   - isExtension: means the cable is connected to the EC component or other cable
	init(at gOrigin: GridPoint, id: String, for gLength: CGFloat, forward direction: ECComponentDirection, isExtension: Bool) {
		// Create a rect
		let rect: CGRect
		switch direction {
		case .downward:
			rect = CGRect(x: (gOrigin.gx - gThickness / 2.0) * gridSize, y: gOrigin.gy * gridSize, width: gThickness * gridSize, height: gLength * gridSize)
		case .upward:
			rect = CGRect(x: (gOrigin.gx - gThickness / 2.0) * gridSize, y: (gOrigin.gy - gLength) * gridSize, width: gThickness * gridSize, height: gLength * gridSize)
		case .rightward:
			rect = CGRect(x: gOrigin.gx * gridSize, y: (gOrigin.gy - gThickness / 2.0) * gridSize, width: gLength * gridSize, height: gThickness * gridSize)
		case .leftward:
			rect = CGRect(x: (gOrigin.gx - gLength) * gridSize, y: (gOrigin.gy - gThickness / 2.0) * gridSize, width: gLength * gridSize, height: gThickness * gridSize)
		}
		
		// Set the properties
		self.gLength = gLength
		self.direction = direction
		self.isExtension = isExtension
		self.id = id
		
		super.init(frame: rect)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func draw(_ rect: CGRect) {
		let path = UIBezierPath()
		let strokeColor = UIColor(hex: "ECF0F1")
		strokeColor.setStroke()
		
		var startPoint: CGPoint
		var endPoint: CGPoint
		
		if direction == .leftward || direction == .rightward {
			// Draw horizontally
			startPoint = CGPoint(x: 0, y: bounds.height / 2)
			endPoint = CGPoint(x: bounds.width, y: startPoint.y)
		} else {
			// Draw vertically
			startPoint = CGPoint(x: bounds.width / 2, y: 0)
			endPoint = CGPoint(x: bounds.width / 2, y: bounds.height)
		}
		
		path.move(to: startPoint)
		path.addLine(to: endPoint)
		
		path.lineWidth = 2
		path.stroke()
	}
}
