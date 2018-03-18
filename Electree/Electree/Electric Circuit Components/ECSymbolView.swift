//
//  ECSymbolView.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 4..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

/// A class that displays a symbol image of the electric circuit component according to the types
class ECSymbolView: UIView {
	/// A type of the EC component
	var type: ECComponentType
	
	/// A direction of the EC component
	var direction: ECComponentDirection
	
	/// The scale factor for the transform
	var transformedScaleX: CGFloat = 1, transformedScaleY: CGFloat = 1
	
	/// A grid size of the frame
	private var innerGridSize: CGFloat = 0
	
	init(frame rect: CGRect, type: ECComponentType, direction: ECComponentDirection) {
		self.type = type
		self.direction = direction
		
		// The number of grid in the frame is 20
		innerGridSize = rect.width / 20.0
		
		super.init(frame: rect)
		
		isOpaque = false
	}
	
	required init?(coder aDecoder: NSCoder) {
		type = ECComponentType(rawValue: aDecoder.decodeInteger(forKey: "typeRawValue"))!
		direction = ECComponentDirection(rawValue: aDecoder.decodeInteger(forKey: "directionRawValue"))!
		transformedScaleX = CGFloat(aDecoder.decodeFloat(forKey: "transformedScaleX"))
		transformedScaleY = CGFloat(aDecoder.decodeFloat(forKey: "transformedScaleY"))
		
		super.init(coder: aDecoder)
		
		innerGridSize = frame.width / 20.0
		
		isOpaque = false
	}
	
	override func encode(with aCoder: NSCoder) {
		aCoder.encode(type.rawValue, forKey: "typeRawValue")
		aCoder.encode(direction.rawValue, forKey: "directionRawValue")
		aCoder.encode(Float(transformedScaleX), forKey: "transformedScaleX")
		aCoder.encode(Float(transformedScaleY), forKey: "transformedScaleY")
		
		super.encode(with: aCoder)
	}
	
	override func draw(_ rect: CGRect) {
		if type == .cable {
			// The cable doesn't need to be transformed
			drawCable(rect)
		} else if let context = UIGraphicsGetCurrentContext() {
			context.saveGState()
			
			// Transfrom the context according to the direction
			switch direction {
			case .rightward:
				context.translateBy(x: 0, y: 0)
			case .downward:
				context.translateBy(x: rect.width, y: 0.0)
			case .leftward:
				context.translateBy(x: rect.width, y: rect.height)
			case .upward:
				context.translateBy(x: 0.0, y: rect.height)
			}
			context.rotate(by: direction.getAngle())
			
			// Actual drawing
			switch type {
			case .acvs:
				drawACVS(rect)
			case .dcvs:
				drawDCVS(rect)
			case .resistor:
				drawResistor(rect)
			case .capacitor:
				drawCapacitor(rect)
			case .inductor:
				drawInductor(rect)
			case .diode:
				drawDiode(rect)
			case .tube:
				drawTriode(rect)
			case .transistor:
				drawTransistor(rect)
			default:
				break
			}
			
			// Restore the transformed context
			context.restoreGState()
		}
	}
	
	/// Draw an AC voltage source
	///
	/// - Parameter rect: Rect to draw in
	private func drawACVS(_ rect: CGRect) {
		let path = UIBezierPath()
		ecComponentColor[type]?.setStroke()
		
		var fromPoint = CGPoint(x: 0.0, y: bounds.height / 2.0)
		var toPoint = CGPoint(x: fromPoint.x + innerGridSize * 5.0, y: fromPoint.y)
		path.move(to: fromPoint)
		path.addLine(to: toPoint)
		
		fromPoint = CGPoint(x: bounds.width / 2.0, y: bounds.height / 2.0)
		let circlePath = UIBezierPath(ovalIn: CGRect(x: fromPoint.x - innerGridSize * 5.0, y: fromPoint.y - innerGridSize * 5.0, width: innerGridSize * 10.0, height: innerGridSize * 10.0))
		
		fromPoint = CGPoint(x: innerGridSize * 6.0, y: bounds.height / 2.0)
		toPoint = CGPoint(x: fromPoint.x + innerGridSize * 3.0, y: fromPoint.y)
		path.move(to: fromPoint)
		path.addLine(to: toPoint)
		
		fromPoint = CGPoint(x: fromPoint.x + innerGridSize * 1.5, y: fromPoint.y - innerGridSize * 1.5)
		toPoint = CGPoint(x: fromPoint.x, y: fromPoint.y + innerGridSize * 3.0)
		path.move(to: fromPoint)
		path.addLine(to: toPoint)
		
		path.move(to: CGPoint(x: innerGridSize * 11.0, y: innerGridSize * 10.0))
		path.addLine(to: CGPoint(x: innerGridSize * 14.0, y: innerGridSize * 10.0))
		
		fromPoint = CGPoint(x: bounds.width, y: bounds.height / 2.0)
		toPoint = CGPoint(x: fromPoint.x - innerGridSize * 5.0, y: fromPoint.y)
		path.move(to: fromPoint)
		path.addLine(to: toPoint)
		
		path.lineWidth = 2.0
		path.stroke()
		circlePath.lineWidth = 2.0
		circlePath.stroke()
	}
	
	/// Draw a DC voltage source
	///
	/// - Parameter rect: Rect to draw in
	private func drawDCVS(_ rect: CGRect) {
		let path = UIBezierPath()
		ecComponentColor[type]?.setStroke()
		ecComponentColor[type]?.setFill()
		
		path.move(to: CGPoint(x: 0.0, y: innerGridSize * 10.0))
		path.addLine(to: CGPoint(x: innerGridSize * 8.0, y: innerGridSize * 10.0))
		
		path.move(to: CGPoint(x: innerGridSize * 8.0, y: innerGridSize * 4.0))
		path.addLine(to: CGPoint(x: innerGridSize * 8.0, y: innerGridSize * 16.0))
		
		path.move(to: CGPoint(x: innerGridSize * 11.0, y: innerGridSize * 4.0))
		path.addLine(to: CGPoint(x: innerGridSize * 11.0, y: innerGridSize * 16.0))
		
		path.move(to: CGPoint(x: innerGridSize * 13.0, y: innerGridSize * 10.0))
		path.addLine(to: CGPoint(x: innerGridSize * 20.0, y: innerGridSize * 10.0))
		
		path.move(to: CGPoint(x: innerGridSize * 9.0, y: innerGridSize * 7.0))
		path.addLine(to: CGPoint(x: innerGridSize * 9.0, y: innerGridSize * 13.0))
		path.addLine(to: CGPoint(x: innerGridSize * 10.0, y: innerGridSize * 13.0))
		path.addLine(to: CGPoint(x: innerGridSize * 10.0, y: innerGridSize * 7.0))
		path.close()
		path.fill()
		
		path.move(to: CGPoint(x: innerGridSize * 12.0, y: innerGridSize * 7.0))
		path.addLine(to: CGPoint(x: innerGridSize * 12.0, y: innerGridSize * 13.0))
		path.addLine(to: CGPoint(x: innerGridSize * 13.0, y: innerGridSize * 13.0))
		path.addLine(to: CGPoint(x: innerGridSize * 13.0, y: innerGridSize * 7.0))
		path.close()
		path.fill()
		
		path.lineWidth = 2.0
		path.stroke()
	}
	
	/// Draw a Resistor
	///
	/// - Parameter rect: Rect to draw in
	private func drawResistor(_ rect: CGRect) {
		let path = UIBezierPath()
		ecComponentColor[type]?.setStroke()
		
		let startPoint = CGPoint(x: 0.0, y: bounds.height / 2.0)
		
		path.move(to: startPoint)
		var toPoint = CGPoint(x: startPoint.x + innerGridSize * 4.0, y: startPoint.y)
		path.addLine(to: toPoint)
		
		for _ in 1...3 {
			toPoint = CGPoint(x: toPoint.x + innerGridSize, y: toPoint.y - innerGridSize * 2.0)
			path.addLine(to: toPoint)
			
			toPoint = CGPoint(x: toPoint.x + innerGridSize * 2.0, y: toPoint.y + innerGridSize * 4.0)
			path.addLine(to: toPoint)
			
			toPoint = CGPoint(x: toPoint.x + innerGridSize, y: toPoint.y - innerGridSize * 2.0)
			path.addLine(to: toPoint)
		}
		
		toPoint = CGPoint(x: toPoint.x + innerGridSize * 4.0, y: toPoint.y)
		path.addLine(to: toPoint)
		
		path.lineWidth = 2.0
		path.stroke()
	}
	
	/// Draw a Capacitor
	///
	/// - Parameter rect: Rect to draw in
	private func drawCapacitor(_ rect: CGRect) {
		let path = UIBezierPath()
		ecComponentColor[type]?.setStroke()
		
		var startPoint = CGPoint(x: 0.0, y: bounds.height / 2.0)
		var toPoint = CGPoint(x: startPoint.x + innerGridSize * 9.0, y: startPoint.y)
		path.move(to: startPoint)
		path.addLine(to: toPoint)
		
		startPoint = CGPoint(x: toPoint.x, y: toPoint.y - innerGridSize * 4.0)
		toPoint = CGPoint(x: startPoint.x, y: startPoint.y + innerGridSize * 8.0)
		path.move(to: startPoint)
		path.addLine(to: toPoint)
		
		startPoint = CGPoint(x: startPoint.x + innerGridSize * 2.0, y: startPoint.y)
		toPoint = CGPoint(x: toPoint.x + innerGridSize * 2.0, y: toPoint.y)
		path.move(to: startPoint)
		path.addLine(to: toPoint)
		
		startPoint = CGPoint(x: startPoint.x, y: startPoint.y + innerGridSize * 4.0)
		toPoint = CGPoint(x: startPoint.x + innerGridSize * 9.0, y: startPoint.y)
		path.move(to: startPoint)
		path.addLine(to: toPoint)
		
		path.lineWidth = 2.0
		path.stroke()
	}
	
	/// Draw an Inductor
	///
	/// - Parameter rect: Rect to draw in
	private func drawInductor(_ rect: CGRect) {
		let path = UIBezierPath()
		ecComponentColor[type]?.setStroke()
		
		var fromPoint = CGPoint(x: 0.0, y: bounds.height / 2.0)
		var toPoint = CGPoint(x: fromPoint.x + innerGridSize * 4.0, y: fromPoint.y)
		path.move(to: fromPoint)
		path.addLine(to: toPoint)
		
		for _ in 1...3 {
			fromPoint = toPoint
			toPoint.x += innerGridSize * 4.0
			path.addCurve(to: toPoint, controlPoint1: CGPoint(x: fromPoint.x, y: fromPoint.y - innerGridSize * 4.0), controlPoint2: CGPoint(x: toPoint.x, y: toPoint.y - innerGridSize * 4.0))
		}
		
		toPoint.x += innerGridSize * 4
		path.addLine(to: toPoint)
		
		path.lineWidth = 2.0
		path.stroke()
	}
	
	/// Draw a Diode
	///
	/// - Parameter rect: Rect to draw in
	private func drawDiode(_ rect: CGRect) {
		let path = UIBezierPath()
		ecComponentColor[type]?.setStroke()
		ecComponentColor[type]?.setFill()
		path.lineWidth = 2.0
		
		path.move(to: CGPoint(x: 6.0 * innerGridSize, y: 4.0 * innerGridSize))
		path.addLine(to: CGPoint(x: 6.0 * innerGridSize, y: 10.0 * innerGridSize))
		path.addLine(to: CGPoint(x: 11.0 * innerGridSize, y: 7.0 * innerGridSize))
		path.close()
		
		path.move(to: CGPoint(x: 9.0 * innerGridSize, y: 13.0 * innerGridSize))
		path.addLine(to: CGPoint(x: 14.0 * innerGridSize, y: 10.0 * innerGridSize))
		path.addLine(to: CGPoint(x: 14.0 * innerGridSize, y: 16.0 * innerGridSize))
		path.close()
		path.fill()
		
		path.move(to: CGPoint(x: 0.0, y: 10.0 * innerGridSize))
		path.addLine(to: CGPoint(x: 3.0 * innerGridSize, y: 10.0 * innerGridSize))
		
		path.move(to: CGPoint(x: 6.0 * innerGridSize, y: 7.0 * innerGridSize))
		path.addLine(to: CGPoint(x: 3.0 * innerGridSize, y: 7.0 * innerGridSize))
		path.addLine(to: CGPoint(x: 3.0 * innerGridSize, y: 13.0 * innerGridSize))
		path.addLine(to: CGPoint(x: 9.0 * innerGridSize, y: 13.0 * innerGridSize))
		
		path.move(to: CGPoint(x: 11.0 * innerGridSize, y: 4.0 * innerGridSize))
		path.addLine(to: CGPoint(x: 11.0 * innerGridSize, y: 10.0 * innerGridSize))
		
		path.move(to: CGPoint(x: 9.0 * innerGridSize, y: 10.0 * innerGridSize))
		path.addLine(to: CGPoint(x: 9.0 * innerGridSize, y: 16.0 * innerGridSize))
		
		path.move(to: CGPoint(x: 11.0 * innerGridSize, y: 7.0 * innerGridSize))
		path.addLine(to: CGPoint(x: 17.0 * innerGridSize, y: 7.0 * innerGridSize))
		path.addLine(to: CGPoint(x: 17.0 * innerGridSize, y: 13.0 * innerGridSize))
		path.addLine(to: CGPoint(x: 14.0 * innerGridSize, y: 13.0 * innerGridSize))
		
		path.move(to: CGPoint(x: 17.0 * innerGridSize, y: 10.0 * innerGridSize))
		path.addLine(to: CGPoint(x: 20.0 * innerGridSize, y: 10.0 * innerGridSize))
		
		path.stroke()
	}
	
	/// Draw a Triode
	///
	/// - Parameter rect: Rect to draw in
	private func drawTriode(_ rect: CGRect) {
		let path = UIBezierPath()
		ecComponentColor[type]?.setStroke()
		
		let circlePath = UIBezierPath(ovalIn: CGRect(x: innerGridSize * 5.0, y: ecComponentSymbolImageSize / 2.0 - innerGridSize * 4.0, width: innerGridSize * 10.0, height: innerGridSize * 8.0))
		
		path.move(to: CGPoint(x: innerGridSize * 5.0, y: ecComponentSymbolImageSize / 2.0))
		path.addLine(to: CGPoint(x: innerGridSize * 7.5, y: ecComponentSymbolImageSize / 2.0))
		
		path.move(to: CGPoint(x: innerGridSize * 7.5, y: innerGridSize * 8.0))
		path.addLine(to: CGPoint(x: innerGridSize * 7.5, y: innerGridSize * 12.0))
		
		path.move(to: CGPoint(x: innerGridSize * 15.0, y: ecComponentSymbolImageSize / 2.0))
		path.addLine(to: CGPoint(x: innerGridSize * 14.0, y: ecComponentSymbolImageSize / 2.0))
		path.addLine(to: CGPoint(x: innerGridSize * 12.5, y: innerGridSize * 8.0))
		path.addLine(to: CGPoint(x: innerGridSize * 12.5, y: innerGridSize * 12.0))
		path.addLine(to: CGPoint(x: innerGridSize * 13.5, y: innerGridSize * 12.0))
		
		path.move(to: CGPoint(x: 0.0, y: ecComponentSymbolImageSize / 2.0))
		path.addLine(to: CGPoint(x: innerGridSize * 5.0, y: ecComponentSymbolImageSize / 2.0))
		
		path.move(to: CGPoint(x: innerGridSize * 15.0, y: ecComponentSymbolImageSize / 2.0))
		path.addLine(to: CGPoint(x: ecComponentSymbolImageSize, y: ecComponentSymbolImageSize / 2.0))
		
		path.move(to: CGPoint(x: ecComponentSymbolImageSize / 2.0, y: ecComponentSymbolImageSize - innerGridSize * 6.0))
		path.addLine(to: CGPoint(x: ecComponentSymbolImageSize / 2.0, y: ecComponentSymbolImageSize))
		
		path.lineWidth = 2.0
		path.stroke()
		circlePath.stroke()
		
		path.move(to: CGPoint(x: ecComponentSymbolImageSize / 2.0, y: ecComponentSymbolImageSize / 2.0 - innerGridSize * 4.0))
		let dashes: [CGFloat] = [4, 2]
		path.setLineDash(dashes, count: 2, phase: 0.0)
		path.addLine(to: CGPoint(x: ecComponentSymbolImageSize / 2.0, y: ecComponentSymbolImageSize / 2.0 + innerGridSize * 4.0))
		path.stroke()
	}
	
	/// Draw a Transistor
	///
	/// - Parameter rect: Rect to draw in
	private func drawTransistor(_ rect: CGRect) {
		var path = UIBezierPath()
		ecComponentColor[type]?.setStroke()
		ecComponentColor[type]?.setFill()
		
		path.move(to: CGPoint(x: 0.0, y: innerGridSize * 10.0))
		path.addLine(to: CGPoint(x: innerGridSize * 5.0, y: innerGridSize * 10.0))
		path.addLine(to: CGPoint(x: innerGridSize * 7.0, y: innerGridSize * 16.0))
		
		path.move(to: CGPoint(x: innerGridSize * 13.0, y: innerGridSize * 16.0))
		path.addLine(to: CGPoint(x: innerGridSize * 15.0, y: innerGridSize * 10.0))
		path.addLine(to: CGPoint(x: innerGridSize * 20.0, y: innerGridSize * 10.0))
		
		path.move(to: CGPoint(x: innerGridSize * 10.0, y: innerGridSize * 16.5))
		path.addLine(to: CGPoint(x: innerGridSize * 10.0, y: innerGridSize * 20.0))
		
		path.lineWidth = 2.0
		path.stroke()
		
		path = UIBezierPath(rect: CGRect(x: innerGridSize * 5.0, y: innerGridSize * 16.0, width: innerGridSize * 10.0, height: innerGridSize * 0.5))
		path.fill()
		
		let centroid = CGPoint(x: innerGridSize * 14.0, y: innerGridSize * 13.0)
		let tempPoint = CGPoint(x: innerGridSize * 15.0, y: innerGridSize * 13.0)
		let point1 = tempPoint.rotate(around: centroid, by: 75.0)
		let point2 = point1.rotate(around: centroid, by: 120.0)
		let point3 = point2.rotate(around: centroid, by: 120.0)
		path.move(to: point1)
		path.addLine(to: point2)
		path.addLine(to: point3)
		path.close()
		path.fill()
	}
	
	/// Draw a cable
	///
	/// - Parameter rect: Rect to draw in
	private func drawCable(_ rect: CGRect) {
		let path = UIBezierPath()
		ecComponentColor[type]?.setStroke()
		
		var startPoint: CGPoint
		var endPoint: CGPoint
		
		if direction == .leftward || direction == .rightward {
			// Draw horizontally
			startPoint = CGPoint(x: 0.0, y: bounds.height / 2.0)
			endPoint = CGPoint(x: bounds.width, y: startPoint.y)
		} else {
			// Draw vertically
			startPoint = CGPoint(x: bounds.width / 2.0, y: 0.0)
			endPoint = CGPoint(x: bounds.width / 2.0, y: bounds.height)
		}
		
		path.move(to: startPoint)
		path.addLine(to: endPoint)
		
		path.lineWidth = 2.0
		path.stroke()
	}
	
	/// Invert the symbol image according to the option
	///
	/// - Parameter option: Invert a image vertically or horizontally
	func invert(option: ECComponentReversalOption) {
		if option == .vertical {
			transformedScaleY *= -1
		} else {
			transformedScaleX *= -1
		}
		transform = CGAffineTransform(scaleX: transformedScaleX, y: transformedScaleY)
	}
}

extension CGPoint {
	/// Rotate a point around a given origin.
	///
	/// - Parameters:
	///   - origin: origin
	///   - degrees: degrees
	/// - Returns: a point calculated
	func rotate(around origin: CGPoint, by degrees: CGFloat) -> CGPoint {
		let dx = self.x - origin.x
		let dy = self.y - origin.y
		let radius = sqrt(dx * dx + dy * dy)
		let azimuth = atan2(dy, dx) // in radians
		let newAzimuth = azimuth + degrees * CGFloat(π / 180.0) // convert it to radians
		let x = origin.x + radius * cos(newAzimuth)
		let y = origin.y + radius * sin(newAzimuth)
		return CGPoint(x: x, y: y)
	}
}
