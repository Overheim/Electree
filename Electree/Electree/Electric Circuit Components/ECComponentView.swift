//
//  ECComponentView.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 4..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

let π: CGFloat = CGFloat(Double.pi)

/// The type of electric circuit component
///
/// - acvs: AC voltage source
/// - dcvs: DC voltage source
/// - resistor: resistor
/// - capacitor: capacitor
/// - inductor: inductor
/// - diode: diode
/// - tube: vacuum tube
/// - transistor: transistor
/// - cable: cable
/// - dummy: Only used in case of having two pairs of terminals at least
enum ECComponentType: Int {
	case acvs=0, dcvs, resistor, capacitor, inductor, diode, tube, transistor, cable, dummy, dummyTube, dummyTransistor
}

/// The list of model of electric circuit component
let ECModels: [ECComponentType : [String]] = [
	.tube : ["RSD-1", "RSD-2", "EHX-1"],
	.transistor : ["2N2222", "2N5089"]
]

/// The direction of the electric circuit component
///
/// - rightward: rightward
/// - downward: downward
/// - leftward: leftward
/// - upward: upward
enum ECComponentDirection: Int {
	case rightward=0, downward, leftward, upward
	
	/// Get the angle according to direction
	///
	/// - Returns: Angle by radian
	func getAngle() -> CGFloat {
		switch self {
		case .rightward:
			return 0.0
		case .downward:
			return π / 2.0
		case .leftward:
			return π
		case .upward:
			return 3.0 * π / 2.0
		}
	}
	
	func isVertical() -> Bool {
		return self == .upward || self == .downward
	}
	
	func isHorizon() -> Bool {
		return self == .leftward || self == .rightward
	}
	
	/// Get the direction rotated by 0.5π
	///
	/// - Returns: The direction rotated by 0.5π
	func rotate() -> ECComponentDirection {
		return ECComponentDirection(rawValue: (self.rawValue + 1) % 4)!
	}
	
	/// Get the opposite direction
	///
	/// - Returns: The direction rotated by π
	func getOppositeDirection() -> ECComponentDirection {
		return ECComponentDirection(rawValue: (self.rawValue + 2) % 4)!
	}
}

/// The reverse option of the electric circuit component
///
/// - vertical: Reverse vertically
/// - horizontal: Reverse horizontally
enum ECComponentReversalOption {
	case vertical, horizontal
}

typealias ECComponentValueDictionary = Dictionary<String, Float>
typealias ECComponentOptionDictionary = Dictionary<String, Bool>

/// A structure which stores the properties of EC compoent
struct ECComponentProperty {
	var values: ECComponentValueDictionary = [:]
	var options: ECComponentOptionDictionary = [:]
	var modelIndex: Int = -1
	
	init(type: ECComponentType) {
		switch type {
		case .acvs:
			values["FREQUENCY"] = 1000.0
			values["VOLTAGE"] = 1.0
			options["INPUT"] = true
		case .dcvs:
			values["VOLTAGE"] = 250.0
		case .resistor:
			values["RESISTANCE"] = 1.0
			options["OUTPUT"] = false
		case .capacitor:
			values["CAPACITANCE"] = 1.0
			options["OUTPUT"] = false
		case .inductor:
			values["INDUCTANCE"] = 1.0
			options["OUTPUT"] = false
		case .tube:
			modelIndex = 0
		default:
			break
		}
	}
}

/// The list of the ECC colors
let ecComponentColor: [ECComponentType : UIColor] = [
	.acvs : UIColor(hex: "E67E22"),
	.dcvs : UIColor(hex: "C0392B"),
	.resistor : UIColor(hex: "16A085"),
	.capacitor : UIColor(hex: "3498DB"),
	.inductor : UIColor(hex: "2ECC71"),
	.diode : UIColor(hex: "F1C40F"),
	.tube : UIColor(hex: "8E44AD"),
	.transistor : UIColor(hex: "2E4053"),
	.cable : UIColor(hex: "95A5A6")
]

/// The electric circuit component class. This have the symbol and label as sub displaying the symbol image, name and values(i.e., resistance, capacitance...), and interact with the touch event by showing detail popup or change the direction.
class ECComponentView: UIView {
	/// An unique string which differentiates with others
	private(set) var id: String
	
	/// Displays the symbol image of the EC component
	private var symbol: ECSymbolView!
	
	/// Displays the name and the value of the EC component
	private var label: ECLabelView!
	
	/// The properties of EC component, which have impedance or power source
	var property: ECComponentProperty! {
		didSet {
			label.values = property.values
		}
	}
	
	/// The grid point at which EC component locates
	var gOrigin: GridPoint
	
	/// The number of nodes which connected to this component
	var numberOfNodes: Int {
		if symbol.type == .tube || symbol.type == .transistor || symbol.type == .dummyTube || symbol.type == .dummyTransistor {
			return 3
		} else {
			return 2
		}
	}
	
	/// A name of EC component
	var name: String {
		get {
			return label.name
		}
		set {
			label.name = newValue
		}
	}
	
	/// Whether the component is a cable
	var isCable: Bool {
		return symbol.type == .cable
	}
	
	var type: ECComponentType {
		return symbol.type
	}
	
	/// The direction of ECC. The value is same with the symbol and label's
	var direction: ECComponentDirection {
		get {
			return symbol.direction
		}
		set {
			symbol.direction = newValue
			label?.direction = newValue
		}
	}
	
	/// The length of ECC by grided value
	var gLength: CGFloat {
		if type == .cable {
			switch symbol.direction {
			case .rightward, .leftward:
				return frame.width / gridSize
			case .downward, .upward:
				return frame.height / gridSize
			}
		} else {
			return gECComponentSymbolImageSize
		}
	}
	
	/// Thickness of the cable(by grid)
	private let gThickness: CGFloat = 0.25
	
	/// The grided endpoint of electric circuit component. This should be changed only if the type is Cable.
	var endpoint: GridPoint {
		get {
			switch symbol.direction {
			case .rightward:
				return GridPoint(gx: gOrigin.gx + frame.width / gridSize, gy: gOrigin.gy)
			case .leftward:
				return GridPoint(gx: gOrigin.gx - frame.width / gridSize, gy: gOrigin.gy)
			case .upward:
				return GridPoint(gx: gOrigin.gx, gy: gOrigin.gy - frame.height / gridSize)
			case .downward:
				return GridPoint(gx: gOrigin.gx, gy: gOrigin.gy + frame.height / gridSize)
			}
		}
		set {
			// Changing the endpoint can't be performed unless the type is Cable.
			if type != .cable {
				return
			}
			
			if newValue.isOnSameHorizontal(with: gOrigin) {
				//============================================================
				// horizontally
				//============================================================
				if newValue.isRightSide(of: gOrigin) {
					// Set the direction
					direction = .rightward
					
					// Calculate the length
					let gCableLength = newValue.gx - gOrigin.gx
					
					// Modify the frame
					frame = CGRect(x: gOrigin.gx * gridSize, y: (gOrigin.gy - gThickness / 2.0) * gridSize, width: gCableLength * gridSize, height: gThickness * gridSize)
				} else {
					// Set the direction
					direction = .leftward
					
					// Calculate the length
					let gCableLength = gOrigin.gx - newValue.gx
					
					// Modify the frame
					frame = CGRect(x: newValue.gx * gridSize, y: (newValue.gy - gThickness / 2.0) * gridSize, width: gCableLength * gridSize, height: gThickness * gridSize)
				}
			} else if newValue.isOnSameVertical(with: gOrigin) {
				//============================================================
				// vertically
				//============================================================
				if newValue.isBelow(gOrigin) {
					// Set the direction
					direction = .downward
					
					// Calculate the length
					let gCableLength = newValue.gy - gOrigin.gy
					
					// Modify the frame
					frame = CGRect(x: (gOrigin.gx - gThickness / 2.0) * gridSize, y: gOrigin.gy * gridSize, width: gThickness * gridSize, height: gCableLength * gridSize)
				} else {
					// Set the direction
					direction = .upward
					
					// Calculate the length
					let gCableLength = gOrigin.gy - newValue.gy
					
					// Modify the frame
					frame = CGRect(x: (newValue.gx - gThickness / 2.0) * gridSize, y: newValue.gy * gridSize, width: gThickness * gridSize, height: gCableLength * gridSize)
				}
			}
			
			// Modify the frame of symbol image
			symbol.frame = CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)
		}
	}
	
	/// A center of the EC component's rect
	var centroid: GridPoint {
		return GridPoint(gx: (frame.origin.x + frame.width / 2.0) / gridSize, gy: (frame.origin.y + frame.height / 2.0) / gridSize)
	}
	
	override var description: String {
		return id
	}
	
	/// True if the EC component is a extension cable, or false
	var isExtensionCable: Bool {
		let ecGraph = ECGraph.sharedInstance
		
		for connectedNode in ecGraph.findECNodes(connectedTo: self, option: .all) {
			for adjacentComponent in ecGraph.findECComponents(adjacentTo: self, through: connectedNode) {
				if !adjacentComponent.isCable {
					return false
				}
			}
		}
		
		return true
	}
	
	/// Initializer function of EC component
	///
	/// - Parameters:
	///   - gOrigin: origin by grid
	init(at gOrigin: GridPoint, id: String, name: String, type: ECComponentType, property: ECComponentProperty, direction: ECComponentDirection) {
		self.id = id
		self.property = property
		self.gOrigin = gOrigin
		
		// Create a rect
		let rect: CGRect
		switch direction {
		case .downward:
			rect = CGRect(x: (gOrigin.gx - gECComponentSymbolImageSize / 2.0) * gridSize, y: gOrigin.gy * gridSize, width: ecComponentSymbolImageSize, height: ecComponentSymbolImageSize)
		case .upward:
			rect = CGRect(x: (gOrigin.gx - gECComponentSymbolImageSize / 2.0) * gridSize, y: (gOrigin.gy - gECComponentSymbolImageSize) * gridSize, width: ecComponentSymbolImageSize, height: ecComponentSymbolImageSize)
		case .rightward:
			rect = CGRect(x: gOrigin.gx * gridSize, y: (gOrigin.gy - gECComponentSymbolImageSize / 2.0) * gridSize, width: ecComponentSymbolImageSize, height: ecComponentSymbolImageSize)
		case .leftward:
			rect = CGRect(x: (gOrigin.gx - gECComponentSymbolImageSize) * gridSize, y: (gOrigin.gy - gECComponentSymbolImageSize / 2.0) * gridSize, width: ecComponentSymbolImageSize, height: ecComponentSymbolImageSize)
		}
		
		// Create a symbol and label instance
		symbol = ECSymbolView(frame: CGRect(x: 0.0, y: 0.0, width: rect.width, height: rect.height), type: type, direction: direction)
		label = ECLabelView(frame: CGRect(x: 0.0, y: 0.0, width: rect.width, height: rect.height), name: name, type: type, values: property.values, direction: direction)
		
		super.init(frame: rect)
		
		addSubview(symbol)
		addSubview(label)
	}
	
	/// Initializer for the type of cable
	///
	/// - Parameters:
	///   - gOrigin: origin by grid
	///   - gLength: length by grid
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
		self.id = id
		self.gOrigin = gOrigin
		
		// Create a symbol image
		symbol = ECSymbolView(frame: CGRect(x: 0.0, y: 0.0, width: rect.width, height: rect.height), type: .cable, direction: direction)
		
		super.init(frame: rect)
		
		addSubview(symbol)
	}
	
	required init?(coder aDecoder: NSCoder) {
		id = aDecoder.decodeObject(forKey: "id") as! String
		gOrigin = GridPoint(gx: aDecoder.decodeObject(forKey: "gOriginX") as! CGFloat, gy: aDecoder.decodeObject(forKey: "gOriginY") as! CGFloat)
		symbol = aDecoder.decodeObject(forKey: "symbolView") as! ECSymbolView
		label = aDecoder.decodeObject(forKey: "labelView") as? ECLabelView
		
		let type = ECComponentType(rawValue: aDecoder.decodeInteger(forKey: "typeRawValue"))!
		
		super.init(coder: aDecoder)
		
		if type != .cable {
			property = ECComponentProperty(type: type)
			property.values = aDecoder.decodeObject(forKey: "values") as! [String : Float]
			property.options = aDecoder.decodeObject(forKey: "options") as! [String : Bool]
			property.modelIndex = aDecoder.decodeInteger(forKey: "modelIndex")
		}
	}
	
	override func encode(with aCoder: NSCoder) {
		aCoder.encode(id, forKey: "id")
		aCoder.encode(gOrigin.gx, forKey: "gOriginX")
		aCoder.encode(gOrigin.gy, forKey: "gOriginY")
		aCoder.encode(symbol, forKey: "symbolView")
		aCoder.encode(type.rawValue, forKey: "typeRawValue")
		
		if !isCable {
			aCoder.encode(property.values, forKey: "values")
			aCoder.encode(property.options, forKey: "options")
			aCoder.encode(property.modelIndex, forKey: "modelIndex")
			aCoder.encode(label, forKey: "labelView")
		}
		
		super.encode(with: aCoder)
	}
	
	/// Create a rect of ECC in case that the type is cable
	///
	/// - Parameter direction: a direction of ECC
	/// - Returns: a rect of ECC
	private func createCableRect(direction: ECComponentDirection) -> CGRect {
		switch direction {
		case .downward:
			return CGRect(x: (gOrigin.gx - gThickness / 2.0) * gridSize, y: gOrigin.gy * gridSize, width: gThickness * gridSize, height: gLength * gridSize)
		case .upward:
			return CGRect(x: (gOrigin.gx - gThickness / 2.0) * gridSize, y: (gOrigin.gy - gLength) * gridSize, width: gThickness * gridSize, height: gLength * gridSize)
		case .rightward:
			return CGRect(x: gOrigin.gx * gridSize, y: (gOrigin.gy - gThickness / 2.0) * gridSize, width: gLength * gridSize, height: gThickness * gridSize)
		case .leftward:
			return CGRect(x: (gOrigin.gx - gLength) * gridSize, y: (gOrigin.gy - gThickness / 2.0) * gridSize, width: gLength * gridSize, height: gThickness * gridSize)
		}
	}
	
	/// Show a pop-up view that includes the properties of the ECC.
	func showECComponentPopUp() {
		if isCable {
			return
		}
		
		ECComponentPopUpView(name: name, property: property, models: ECModels[type]) {
			name, property in
			self.name = name
			self.property = property
			}.show(animated: true)
	}
	
	/// Invert a symbol image of the ECC by option
	///
	/// - Parameter option: Reverse a image vertically or horizontally.
	func invert(option: ECComponentReversalOption) {
		if isCable {
			return
		}
		
		// Invert a symbol image
		symbol.invert(option: option)
		
		// Change a location of label
		if numberOfNodes == 3 &&
			((direction.isHorizon() && option == .vertical) ||
			(direction.isVertical() && option == .horizontal)) {
			label.swapPosition()
		}
		
		// Change the direction and the origin
		if (direction.isHorizon() && option == .horizontal) ||
			(direction.isVertical() && option == .vertical) {
			gOrigin = endpoint
			direction = direction.getOppositeDirection()
		}
	}
	
	/// Reflect an ECC through a given point.
	///
	/// - Parameter base: a base point
	func reflect(through base: GridPoint) {
		// Translate the origin
		gOrigin = gOrigin.reflect(through: base)
		
		// Invert the direction
		direction = direction.getOppositeDirection()
		
		// Modify the frame
		frame = createCableRect(direction: direction)
	}
}
