//
//  BackgroundView.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 3..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

/// A value that defines the size of the grid
let gridSize = CGFloat(44)

/// Draws a regular grid line like normal grid paper
class BackgroundView: UIView {
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func draw(_ rect: CGRect) {
		if let context = UIGraphicsGetCurrentContext() {
			// fill the entire rectangle with a background color
			context.setFillColor(UIColor(hue: 0.0, saturation: 0.0, brightness: 0.15, alpha: 1.0).cgColor)
			context.fill(rect)
			
			// callback that actually draws the pattern
			let drawColoredPattern: CGPatternDrawPatternCallback = { _, con in
				let dotColor = UIColor(hue: 0.0, saturation: 0.0, brightness: 0.07, alpha: 1.0)
				let shadowColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.1)
				
				con.setShadow(offset: CGSize.init(width: 0.0, height: 1.0), blur: 1.0, color: shadowColor.cgColor)
				
				con.move(to: CGPoint(x: 0.0, y: 0.0))
				con.addLine(to: CGPoint(x: gridSize, y: 0.0))
				
				con.move(to: CGPoint(x: 0.0, y: 0.0))
				con.addLine(to: CGPoint(x: 0.0, y: gridSize))
				
				con.setLineWidth(1.0)
				con.setStrokeColor(dotColor.cgColor)
				
				con.strokePath()
			}
			
			// nil for the function that would be called when the pattern drawing is complete
			var callback: CGPatternCallbacks = CGPatternCallbacks(version: 0, drawPattern: drawColoredPattern, releaseInfo: nil)
			
			context.saveGState()
			
			// creates a new color space for patterns, and sets the fill color space to that color space
			let patternSpace = CGColorSpace(patternBaseSpace: nil)
			context.setFillColorSpace(patternSpace!)
			
			// creating the pattern object
			let pattern = CGPattern(info: nil, bounds: rect, matrix: .identity, xStep: gridSize, yStep: gridSize, tiling: .constantSpacing, isColored: true, callbacks: &callback)
			
			// sets the fill pattern to the pattern object and simply fills the rectangle
			var alpha: CGFloat = 1.0
			context.setFillPattern(pattern!, colorComponents: &alpha)
			context.fill(bounds)
			
			context.restoreGState()
		}
	}
}
