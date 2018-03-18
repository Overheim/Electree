//
//  GridView.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 24..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

class GridView: UIView {
	private let edgeColor: UIColor = .black
	private let edgeWidth: CGFloat = 3.0
	
	private let lineColor: UIColor = .black
	private let lineWidth: CGFloat = 1.0
	
	var numberOfX: Int
	var numberOfY: Int
	
	init(frame rect: CGRect, numberOfX: Int, numberOfY: Int) {
		self.numberOfX = numberOfX
		self.numberOfY = numberOfY
		
		super.init(frame: rect)
		
		isOpaque = false
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func draw(_ rect: CGRect) {
		// Calculate the width and height of grid
		let gridWidth = frame.width / CGFloat(numberOfX)
		let gridHeight = frame.height / CGFloat(numberOfY)
		
		// Draw an edge line
		var path = UIBezierPath(rect: rect)
		edgeColor.setStroke()
		path.lineWidth = edgeWidth
		path.stroke()
		
		path = UIBezierPath()
		let dashes: [CGFloat] = [4, 2]
		path.setLineDash(dashes, count: 2, phase: 0.0)
		
		// Set the initial starting point
		var startingPoint = CGPoint(x: 0.0, y: gridHeight)
		
		// Draw a grid line of y-coordinate
		for _ in 0..<numberOfY-1 {
			path.move(to: startingPoint)
			path.addLine(to: CGPoint(x: startingPoint.x + rect.width, y: startingPoint.y))
			
			// Update the starting point
			startingPoint.y += gridHeight
		}
		
		// Draw a grid line of x-coordinate
		startingPoint = CGPoint(x: gridWidth, y: 0.0)
		for _ in 0..<numberOfX-1 {
			path.move(to: startingPoint)
			path.addLine(to: CGPoint(x: startingPoint.x, y: startingPoint.y + rect.height))
			
			// Update the starting point
			startingPoint.x += gridWidth
		}
		
		lineColor.setStroke()
		path.lineWidth = lineWidth
		path.stroke()
	}
}
