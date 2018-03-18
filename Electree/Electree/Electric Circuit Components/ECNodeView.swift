//
//  ECNodeView.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 9..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

/// A node that connects two or more edges. It's displayed in a circle on the screen, and managed by ECNodeManager
class ECNodeView: UIView {
	var id: String
	
	/// The origin by grid
	var gOrigin: GridPoint
	
	/// The size of the node
	private let nodeSize: CGFloat = 4.0
	
	/// The color of the node
	private var nodeColor: UIColor = UIColor.lightGray
	
	/// print description
	override var description: String {
		return id
	}
	
	init(at gOrigin: GridPoint, id: String) {
		self.id = id
		self.gOrigin = gOrigin
		
		super.init(frame: CGRect(x: gOrigin.gx * gridSize - nodeSize / 2.0, y: gOrigin.gy * gridSize - nodeSize / 2.0, width: nodeSize, height: nodeSize))
		
		isOpaque = false
	}
	
	required init?(coder aDecoder: NSCoder) {
		id = aDecoder.decodeObject(forKey: "id") as! String
		gOrigin = GridPoint(gx: aDecoder.decodeObject(forKey: "gOriginX") as! CGFloat, gy: aDecoder.decodeObject(forKey: "gOriginY") as! CGFloat)
		
		super.init(coder: aDecoder)
	}
	
	override func encode(with aCoder: NSCoder) {
		aCoder.encode(id, forKey: "id")
		aCoder.encode(gOrigin.gx, forKey: "gOriginX")
		aCoder.encode(gOrigin.gy, forKey: "gOriginY")
		
		super.encode(with: aCoder)
	}
	
	override func draw(_ rect: CGRect) {
		nodeColor.setFill()
		
		let path = UIBezierPath(ovalIn: rect)
		path.lineWidth = 1
		path.fill()
	}
	
	/// Move to the grided point
	///
	/// - Parameters:
	///   - gx: point of x coordinate
	///   - gy: point of y coordinate
	func moveTo(gx: CGFloat, gy: CGFloat) {
		// Modify the origin
		gOrigin.gx = gx
		gOrigin.gy = gy
		
		// Modify the frame
		frame = CGRect(x: gOrigin.gx * gridSize - nodeSize / 2.0, y: gOrigin.gy * gridSize - nodeSize / 2.0, width: nodeSize, height: nodeSize)
	}
}
