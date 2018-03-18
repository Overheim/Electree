//
//  WaveGraphView.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 23..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

class WaveGraphView: UIView {
	/// The color of text
	private var textColor: UIColor = .black
	
	/// Whole datum of wave
	var datum: [Float] = []
	
	/// A title of the graph
	var title: String = "No Title" {
		didSet {
			titleLabel.text = title
		}
	}
	
	/// The range of the values of x-coordinate
	var xRange: (Float, Float) = (0.0, 0.0)
	
	private var gridCount: Int = 8
	
	private var titleLabel: UILabel!
	private var xDatumLabels: [UILabel?] = []
	private var yDatumLabels: [UILabel?] = []
	
	private var graphOrigin = CGPoint()
	private var graphSize = CGSize()
	
	init(frame rect: CGRect, title: String) {
		self.title = title
		
		super.init(frame: rect)
		
		isOpaque = false
		
		createViews()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		isOpaque = false
		
		createViews()
	}
	
	private func createViews() {
		// Define the size of each label
		let labelSize = CGSize(width: 70.0, height: 20.0)
		
		// Set the size and location of the graph
		graphOrigin = CGPoint(x: labelSize.width, y: 50.0)
		graphSize = CGSize(width: frame.width - labelSize.width * 1.5, height: frame.height - graphOrigin.y - labelSize.height)
		
		// Create a control for title
		titleLabel = UILabel(frame: CGRect(x: graphOrigin.x, y: 0.0, width: graphSize.width, height: graphOrigin.y))
		titleLabel.text = title
		titleLabel.font = UIFont(name: fontBold, size: 24)
		titleLabel.textAlignment = .center
		titleLabel.textColor = textColor
		addSubview(titleLabel)
		
		// The number of labels per coordinate
		let numberOfLabels = gridCount+1
		
		// The location of label to be created. This will be updated after the new one is created
		var labelLocation = CGPoint(x: 0.0, y: 0.0)
		
		// Set the size of grid
		let gridSize = CGSize(width: graphSize.width / 8.0, height: graphSize.height / 8.0)
		
		//============================================================
		// Create the labels(y-coordinate)
		//============================================================
		// Set the initial location
		labelLocation.y = graphOrigin.y - labelSize.height / 2.0
		
		for _ in 0..<numberOfLabels {
			// Create a label
			let newLabel = UILabel(frame: CGRect(x: labelLocation.x, y: labelLocation.y, width: labelSize.width, height: labelSize.height))
			newLabel.text = "0"
			newLabel.font = UIFont(name: fontLight, size: 15)
			newLabel.textAlignment = .right
			newLabel.textColor = textColor
			
			yDatumLabels.append(newLabel)
			addSubview(newLabel)
			
			// Update the location
			labelLocation.y += gridSize.height
		}
		
		//============================================================
		// Create the labels(x-coordinate)
		//============================================================
		// Set the initial location
		labelLocation.x = graphOrigin.x - labelSize.width / 2.0
		labelLocation.y = graphOrigin.y + graphSize.height
		
		for _ in 0..<numberOfLabels {
			// Create a label
			let newLabel = UILabel(frame: CGRect(x: labelLocation.x, y: labelLocation.y, width: labelSize.width, height: labelSize.height))
			newLabel.text = "0"
			newLabel.font = UIFont(name: fontLight, size: 15)
			newLabel.textAlignment = .center
			newLabel.textColor = textColor
			
			xDatumLabels.append(newLabel)
			addSubview(newLabel)
			
			// Update the location
			labelLocation.x += gridSize.width
		}
		
		// Create a grid view
		addSubview(GridView(frame: CGRect(origin: graphOrigin, size: graphSize), numberOfX: gridCount, numberOfY: gridCount))
	}
	
	override func draw(_ rect: CGRect) {
		// Fill the labes of x-coordinate
		var value = xRange.0
		var offset = (xRange.1 - xRange.0) / Float(gridCount)
		for label in xDatumLabels {
			label?.text = String(format: "%.4f", value)
			value += offset
		}
		
		// Fill the labes of y-coordinate
		if datum.count > 0 {
			value = datum.max()!
			offset = (datum.max()! - datum.min()!) / Float(gridCount)
			for label in yDatumLabels {
				label?.text = String(format: "%.4f", value)
				value -= offset
			}
		}
		
		//============================================================
		// Draw the datum
		//============================================================
		if datum.count > 0 {
			// calculate the x point
			let margin: CGFloat = graphOrigin.x
			let columnXPoint = { (column: Int) -> CGFloat in
				// calculate gap between points
				let spacer = (self.graphSize.width) / CGFloat(self.datum.count - 1)
				var x: CGFloat = CGFloat(column) * spacer
				x += margin
				return x
			}
			
			// calculate the y point
			let topBorder: CGFloat = graphOrigin.y
			let minPoint = datum.min()!
			let P2P = datum.max()! - minPoint
			let columnYPoint = { (graphPoint: Float) -> CGFloat in
				// the origin is in the top-left corner and you draw a graph from an origin point in the bottom-left corner, columnYPoint adjusts its return value so that the graph is oriented as you would expect
				var y: CGFloat = CGFloat(graphPoint - minPoint) / CGFloat(P2P) * self.graphSize.height
				y = self.graphSize.height + topBorder - y
				return y
			}
			
			// set up the points line
			let graphPath = UIBezierPath()
			
			// Set the color of stroke
			UIColor.purple.setStroke()
			
			// go to start of line
			graphPath.move(to: CGPoint(x: columnXPoint(0), y: columnYPoint(datum[0])))
			
			// add points for each item in the graphPoints array at the correct (x, y) for the point
			for i in 1..<datum.count {
				let nextPoint = CGPoint(x: columnXPoint(i), y: columnYPoint(datum[i]))
				graphPath.addLine(to: nextPoint)
			}
			
			graphPath.lineWidth = 4;
			graphPath.stroke()
		}
	}
}
