//
//  ECLabelView.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 4..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

//typealias ECComponentValue = (Float, String)

/// A class that displays a name and values of electric circuit component
class ECLabelView: UIView {
	/// A name of the EC component
	var name: String {
		didSet {
			setNeedsDisplay()
		}
	}
	
	/// Values of the ECC
	var values: ECComponentValueDictionary {
		didSet {
			setNeedsDisplay()
		}
	}
	
	private var rectName = CGRect(), rectValues = CGRect()
	
	var type: ECComponentType
	var direction: ECComponentDirection
	
	/// Initializer function
	init(frame rect: CGRect, name: String, type: ECComponentType, values: ECComponentValueDictionary, direction: ECComponentDirection) {
		self.name = name
		self.type = type
		self.values = values
		self.direction = direction
		
		super.init(frame: rect)
		
		setRects()
		isOpaque = false
	}
	
	required init?(coder aDecoder: NSCoder) {
		name = aDecoder.decodeObject(forKey: "name") as! String
		type = ECComponentType(rawValue: aDecoder.decodeInteger(forKey: "typeRawValue"))!
		direction = ECComponentDirection(rawValue: aDecoder.decodeInteger(forKey: "directionRawValue"))!
		values = aDecoder.decodeObject(forKey: "values") as! [String : Float]
		
		super.init(coder: aDecoder)
		
		setRects()
		isOpaque = false
	}
	
	override func encode(with aCoder: NSCoder) {
		aCoder.encode(name, forKey: "name")
		aCoder.encode(type.rawValue, forKey: "typeRawValue")
		aCoder.encode(direction.rawValue, forKey: "directionRawValue")
		aCoder.encode(values, forKey: "values")
		
		super.encode(with: aCoder)
	}
	
	override func draw(_ rect: CGRect) {
		if let context = UIGraphicsGetCurrentContext() {
			context.saveGState()
			
			// Rotate the context according to the direction
			switch direction {
			case .rightward, .leftward:
				context.translateBy(x: 0, y: 0)
			case .downward, .upward:
				context.translateBy(x: rect.width, y: 0)
				context.rotate(by: π / 2.0)
			}
			
			// Get font
			let font = UIFont(name: fontLight, size: 10.0)
			
			// Set the style of text
			let textStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
			textStyle.alignment = .center
			let textColor = ecComponentColor[type]!
			
			if let actualFont = font {
				let textFontAttributes = [
					NSAttributedStringKey.font: actualFont,
					NSAttributedStringKey.foregroundColor: textColor,
					NSAttributedStringKey.paragraphStyle: textStyle
				]
				
				// Create a string for values to display
				var valueString: String = ""
				var isFirstValue = true
				for value in values {
					if !isFirstValue {
						valueString += ", "
					}
					
					valueString += calculateUnitPrefix(value.value)		// unit prefix
					valueString += getUnit(value.key)					// unit
					isFirstValue = false
				}
				
				// Draw a text
				valueString.draw(in: rectValues, withAttributes: textFontAttributes)
				name.draw(in: rectName, withAttributes: textFontAttributes)
			}
			
			context.restoreGState()
		}
	}
	
	/// Unit prefix table
	///
	/// - Parameter value: a value to calculate
	/// - Returns: unit prefix
	private func calculateUnitPrefix(_ value: Float) -> String {
		if value >= 1.0e18 {
			return String(value / 1.0e18) + "E"
		} else if value >= 1.0e15 {
			return String(value / 1.0e15) + "P"
		} else if value >= 1.0e12 {
			return String(value / 1.0e12) + "T"
		} else if value >= 1.0e9 {
			return String(value / 1.0e9) + "G"
		} else if value >= 1.0e6 {
			return String(value / 1.0e6) + "M"
		} else if value >= 1.0e3 {
			return String(value / 1.0e3) + "k"
		} else if value <= 1.0e-18 {
			return String(value / 1.0e-18) + "a"
		} else if value <= 1.0e-15 {
			return String(value / 1.0e-15) + "f"
		} else if value <= 1.0e-12 {
			return String(value / 1.0e-12) + "p"
		} else if value <= 1.0e-9 {
			return String(value / 1.0e-9) + "n"
		} else if value <= 1.0e-6 {
			return String(value / 1.0e-6) + "µ"
		} else if value <= 1.0e-3 {
			return String(value / 1.0e-3) + "m"
		} else {
			return String(value)
		}
	}
	
	/// Get a unit of electric circuit component
	///
	/// - Parameter type: A type of EC component to get the unit
	/// - Returns: A unit of EC component
	private func getUnit(_ type: String) -> String {
		if type == "FREQUENCY" {
			return "Hz"
		} else if type == "VOLTAGE" {
			return "V"
		} else if type == "RESISTANCE" {
			return "Ω"
		} else if type == "CAPACITANCE" {
			return "F"
		} else if type == "INDUCTANCE" {
			return "H"
		} else {
			return ""
		}
	}
	
	/// Set the rects of ECC's name and properties
	private func setRects() {
		// Calculate the rect
		rectName = CGRect(x: 0.0, y: 0.0, width: bounds.width, height: bounds.height * 0.2)
		rectValues = CGRect(x: 0.0, y: bounds.height * 0.8, width: bounds.width, height: bounds.height * 0.2)
		
		// Swap two positions each other in case of upward or leftward.
		if (type == .tube || type == .transistor) && (direction == .leftward || direction == .upward) {
			swapPosition()
		}
	}
	
	/// Swap the position of name and properties
	func swapPosition() {
		let tempRect = rectName
		rectName = rectValues
		rectValues = tempRect
		
		setNeedsDisplay()
	}
}

