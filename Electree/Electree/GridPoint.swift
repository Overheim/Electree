//
//  GridPoint.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 11..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

// MARK: - Extension to the relative position of the CGPoint
extension CGPoint {
	func isAbove(_ point: CGPoint) -> Bool {
		return y < point.y
	}
	
	func isBelow(_ point: CGPoint) -> Bool {
		return y > point.y
	}
	
	func isLeftSide(of point: CGPoint) -> Bool {
		return x < point.x
	}
	
	func isRightSide(of point: CGPoint) -> Bool {
		return x > point.x
	}
	
	func isOnSameVertical(with point: CGPoint) -> Bool {
		return x == point.x
	}
	
	func isOnSameHorizontal(with point: CGPoint) -> Bool {
		return y == point.y
	}
	
	func isTopLeft(to point: CGPoint) -> Bool {
		return isAbove(point) && isLeftSide(of: point)
	}
	
	func isTopRight(to point: CGPoint) -> Bool {
		return isAbove(point) && isRightSide(of: point)
	}
	
	func isBottomLeft(to point: CGPoint) -> Bool {
		return isBelow(point) && isLeftSide(of: point)
	}
	
	func isBottomRight(to point: CGPoint) -> Bool {
		return isBelow(point) && isRightSide(of: point)
	}
	
	var gridPoint: GridPoint {
		return GridPoint(gx: x / gridSize, gy: y / gridSize)
	}
}

/// A coordinate system which is composed by grid format
struct GridPoint: CustomStringConvertible {
	var gx: CGFloat
	var gy: CGFloat
	
	/// Convert to the CGPoint
	var cgPoint: CGPoint {
		return CGPoint(x: gx * gridSize, y: gy * gridSize)
	}
	
	//============================================================
	/// Initializer
	///
	/// - Parameters:
	///   - gx: x location by grid
	///   - gy: y location by grid
	init(gx: CGFloat, gy: CGFloat) {
		self.gx = gx
		self.gy = gy
	}
	
	/// Initializer function by CGPoint
	///
	/// - Parameter point: CGPoint to convert to the GridPoint
	init(_ point: CGPoint) {
		gx = point.x / gridSize
		gy = point.y / gridSize
	}
	
	init() {
		gx = 0
		gy = 0
	}
	
	//============================================================
	/// Check the two points are in the same location
	///
	/// - Parameters:
	///   - left: A point to compare
	///   - right: Another point to compare
	/// - Returns: True if same, or False
	static func ==(left: GridPoint, right: GridPoint) -> Bool {
		return (left.gx == right.gx) && (left.gy == right.gy)
	}
	
	/// Check the two points aren't in the same location
	///
	/// - Parameters:
	///   - left: a point to compare
	///   - right: another point to compare
	/// - Returns: True if not same, or False
	static func !=(left: GridPoint, right: GridPoint) -> Bool {
		return (left.gx != right.gx) || (left.gy != right.gy)
	}
	
	//============================================================
	/// Calculate a length between two points
	///
	/// - Parameter point: An end point
	/// - Returns: An absolte value between two points
	func length(to point: GridPoint) -> CGFloat {
		if isOnSameVertical(with: point) {
			return abs(point.gy - gy)
		} else if isOnSameHorizontal(with: point) {
			return abs(point.gx - gx)
		} else {
			return sqrt((point.gy - gy) * (point.gy - gy) + (point.gx - gx) * (point.gx - gx))
		}
	}
	
	/// Reflect a point through the given point
	///
	/// - Parameters:
	///   - origin: a base point
	/// - Returns: a reflected point through the base point
	func reflect(through base: GridPoint) -> GridPoint {
		let lengthX = gx - base.gx
		let lengthY = gy - base.gy
		return GridPoint(gx: base.gx - lengthX, gy: base.gy - lengthY)
	}
	
	//============================================================
	func isAbove(_ point: GridPoint) -> Bool {
		return gy < point.gy
	}
	
	func isBelow(_ point: GridPoint) -> Bool {
		return gy > point.gy
	}
	
	func isLeftSide(of point: GridPoint) -> Bool {
		return gx < point.gx
	}
	
	func isRightSide(of point: GridPoint) -> Bool {
		return gx > point.gx
	}
	
	func isOnSameVertical(with point: GridPoint) -> Bool {
		return gx == point.gx
	}
	
	func isOnSameHorizontal(with point: GridPoint) -> Bool {
		return gy == point.gy
	}
	
	func isTopLeft(to point: GridPoint) -> Bool {
		return isAbove(point) && isLeftSide(of: point)
	}
	
	func isTopRight(to point: GridPoint) -> Bool {
		return isAbove(point) && isRightSide(of: point)
	}
	
	func isBottomLeft(to point: GridPoint) -> Bool {
		return isBelow(point) && isLeftSide(of: point)
	}
	
	func isBottomRight(to point: GridPoint) -> Bool {
		return isBelow(point) && isRightSide(of: point)
	}
	
	//============================================================
	var description: String {
		return "G(" + String(describing: gx) + "," + String(describing: gy) + ")"
	}
}

