//
//  ScrollView.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 3..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

/// The grid size of electric circuit component's image
let gECComponentSymbolImageSize: CGFloat = 1.5

/// The size of electric circuit component's image
let ecComponentSymbolImageSize: CGFloat = gECComponentSymbolImageSize * gridSize

/// Defines a process related to the touch event
///
/// - draw: Draw a simple line according to the touched points, then add a electric circuit element.
/// - erase: Remove electric circuit components touched by user.
enum TouchMode {
	case draw, erase, popup, invert, split
}

/// A view added in the main view controller.
class ScrollView: UIScrollView {
	/// Draws a line along the grid lines
	weak var drawingView: UIImageView!
	
	/// The color of the brush
	private var brushColor = UIColor.white
	
	/// The width of the brush
	private var brushWidth: CGFloat = 1.5
	
	/// The opacity value of the brush
	private var brushOpacity: CGFloat = 1.0
	
	/// Save the touched points on the grid line
	private var revisedTouchPoints: [CGPoint] = []
	
	/// A TouchMode sets to the .draw initially
	var mode: TouchMode = .draw
	
	/// Direction of a touchmove
	private var touchDirection: ECComponentDirection?
	
	/// The count of the change of direction
	private var chageOfTouchDirectionCount = -1
	
	/// A elctric circuit component's type chosen by an user
	var ecComponentType: ECComponentType!
	
	/// ECC views that received the touch event at the beginning and the end
	private var touchedECComponents: (ECComponentView?, ECComponentView?)
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		// Set the size of the scroll
		panGestureRecognizer.minimumNumberOfTouches = 2
		contentSize = CGSize(width: 2048, height: 2048)
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		// Skip in case of multi touch
		if touches.count > 1 {
			return
		}
		
		// Do nothing at the beginning of the touch event in case of erase mode.
		if mode == .erase {
			return
		}
		
		if let touch = touches.first {
			// Save the touched point to the array
			let currentLocation = touch.location(in: self)
			revisedTouchPoints.append(revise(currentLocation))
			
			if let touchedComponent = ecComponent(at: currentLocation), !touchedComponent.isCable {		// A ECC is touched
				// Set mode to .popup if an ECC is touched
				mode = .popup
				
				// Store the touched ECC
				touchedECComponents.0 = touchedComponent
			} else if let touchedComponent = ecComponent(at: revise(currentLocation)), touchedComponent.isCable {
				// Set mode to .split if a cable is touched
				let nodeManager = ECNodeManager.sharedInstance
				if !nodeManager.ecNodeExist(at: revise(currentLocation).gridPoint) {
					// If there is an ECN, the mode won't be changed
					mode = .split
					
					// Store the touched cable
					touchedECComponents.0 = touchedComponent
				}
			}
		}
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		// Skip in case of multi touch
		if touches.count > 1 {
			return
		}
		
		if let touch = touches.first {
			switch mode {
			case .draw, .split:
				// Draw a line between the last and the current point along the grid
				let currentRevisedPoint = revise(touch.location(in: self))
				drawLine(from: revisedTouchPoints.last!, to: currentRevisedPoint, in: drawingView)
				
				// Check whether the touch direction is changed
				checkTouchDirection(currentRevisedPoint)
				
				// Save the touched point to the array(Avoid duplication)
				if revisedTouchPoints.last! != currentRevisedPoint {
					revisedTouchPoints.append(currentRevisedPoint)
				}
			case .popup:
				mode = .invert
			case .erase:
				// Get the current point
				let currentPoint = touch.location(in: self)
				
				// Remove the ECC which is touched
				if let touchedComponent = ecComponent(at: currentPoint) {
					remove(ecComponent: touchedComponent)
				}
			default:
				break
			}
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		// Skip in case of multi touch
		if touches.count > 1 {
			return
		}
		
		if let touch = touches.first {
			// Set the mode
			let revisedCurrentLocation = revise(touch.location(in: self))
			if let component = ecComponent(at: revisedCurrentLocation) {
				if component.isCable && (mode == .draw || mode == .split) {
					// Set mode to .split if a cable is touched
					let nodeManager = ECNodeManager.sharedInstance
					if !nodeManager.ecNodeExist(at: revisedCurrentLocation.gridPoint) {
						// If there is an ECN, the mode won't be changed
						mode = .split
						
						// Store the touched cable
						touchedECComponents.1 = component
					}
				}
			}
			
			// Work depending on the mode
			switch mode {
			case .draw:
				// Add a new ECC
				addECComponent()?.showECComponentPopUp()
			case .popup:
				// Show the properties pop-up of the ECC
				touchedECComponents.0?.showECComponentPopUp()
				mode = .draw
			case .invert:
				// Invert the symbol of the ECC
				if let touchedComponent = touchedECComponents.0 {
					let endLocation = touch.location(in: touchedComponent)
					if endLocation.x >= touchedComponent.bounds.minX && endLocation.x <= touchedComponent.bounds.maxX {
						if endLocation.y < 0.0 || endLocation.y > touchedComponent.bounds.maxY {
							// Invert vertically
							invert(ecComponent: touchedComponent, option: .vertical)
						}
					} else if endLocation.y >= touchedComponent.bounds.minY && endLocation.y <= touchedComponent.bounds.maxY {
						if endLocation.x < 0.0 || endLocation.x > touchedComponent.bounds.maxX {
							// Invert horizontally
							invert(ecComponent: touchedComponent, option: .horizontal)
						}
					}
				}
				mode = .draw
			case .erase:
				// Get the current point
				let currentPoint = touch.location(in: self)
				
				// Remove the ECC which is touched
				if let touchedComponent = ecComponent(at: currentPoint) {
					remove(ecComponent: touchedComponent)
				}
			case .split:
				// Add an new ECC
				if let newComponent = addECComponent() {
					newComponent.showECComponentPopUp()
					// Split the cable
					splitCable()
				}
				
				mode = .draw
			}
		}
		
		// Reset all touch events
		reset()
	}
	
	/// Matches a point to the grid line
	///
	/// - Parameter point: A point to be matched
	/// - Returns: The matched point
	private func revise(_ point: CGPoint) -> CGPoint {
		var revisedPoint = CGPoint.zero
		let nGridSize = Int(gridSize)
		
		// x
		var quotient: Int = Int(point.x) / nGridSize
		var remainder: Int = Int(point.x) - quotient * nGridSize
		revisedPoint.x = CGFloat(quotient * nGridSize + (remainder < nGridSize/2 ? 0 : nGridSize))
		
		// y
		quotient = Int(point.y) / nGridSize
		remainder = Int(point.y) - quotient * nGridSize
		revisedPoint.y = CGFloat(quotient * nGridSize + (remainder < nGridSize/2 ? 0 : nGridSize))
		
		return revisedPoint
	}
	
	/// Draws a line between two points
	///
	/// - Parameters:
	///   - fromPoint: The starting point
	///   - toPoint: The end point
	///   - view: The view in which draw a line
	private func drawLine(from fromPoint: CGPoint, to toPoint: CGPoint, in view: UIImageView) {
		UIGraphicsBeginImageContext(view.frame.size)
		if let context = UIGraphicsGetCurrentContext() {
			view.image?.draw(in: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
			
			context.move(to: fromPoint)
			context.addLine(to: toPoint)
			
			context.setLineCap(.round)
			context.setLineWidth(brushWidth)
			context.setStrokeColor(brushColor.cgColor)
			context.setBlendMode(.normal)
			
			context.strokePath()
			
			view.image = UIGraphicsGetImageFromCurrentImageContext()
			view.alpha = brushOpacity
		}
		UIGraphicsEndImageContext()
	}
	
	/// Reset all variables related to touch events
	private func reset() {
		revisedTouchPoints.removeAll()
		drawingView.image = nil
		chageOfTouchDirectionCount = -1
		touchDirection = nil
		touchedECComponents = (nil, nil)
	}
}

// MARK: - Tracking touched points
extension ScrollView {
	private func checkTouchDirection(_ revisedCurrentPoint: CGPoint) {
		if let revisedLastPoint = revisedTouchPoints.last {
			if revisedCurrentPoint.isOnSameVertical(with: revisedLastPoint) {
				if revisedCurrentPoint.isAbove(revisedLastPoint) {
					// up
					if touchDirection == nil || touchDirection! != .upward {
						touchDirection = .upward
						chageOfTouchDirectionCount += 1
					}
				} else if revisedCurrentPoint.isBelow(revisedLastPoint) {
					// down
					if touchDirection == nil || touchDirection! != .downward {
						touchDirection = .downward
						chageOfTouchDirectionCount += 1
					}
				}
			} else if revisedCurrentPoint.isOnSameHorizontal(with: revisedLastPoint) {
				if revisedCurrentPoint.isLeftSide(of: revisedLastPoint) {
					// left
					if touchDirection == nil || touchDirection! != .leftward {
						touchDirection = .leftward
						chageOfTouchDirectionCount += 1
					}
				} else if revisedCurrentPoint.isRightSide(of: revisedLastPoint) {
					// right
					if touchDirection == nil || touchDirection! != .rightward {
						touchDirection = .rightward
						chageOfTouchDirectionCount += 1
					}
				}
			}
		}
	}
}

// MARK: - Manage an electric circuit components
extension ScrollView {
	/// Create an EC component.
	///
	/// Pop-up a view then store the detail properties for the component. Then, create an ECComponentView instances
	///
	/// - Returns: A EC component created, except the cables
	private func addECComponent() -> ECComponentView? {
		if ecComponentType == nil {
			return nil
		}
		
		// Create a rect
		var minX = revisedTouchPoints[0].x
		var minY = revisedTouchPoints[0].y
		var maxX = minX
		var maxY = minY
		for point in revisedTouchPoints {
			minX = min(minX, point.x)
			minY = min(minY, point.y)
			maxX = max(maxX, point.x)
			maxY = max(maxY, point.y)
		}
		let componentRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
		
		// Get width and height (by grid)
		let gComponentWidth = (maxX - minX) / gridSize
		let gComponentHeight = (maxY - minY) / gridSize
		if gComponentWidth == 0 && gComponentHeight == 0 {
			return nil
		}
		
		// EC components array which will be added in the scroll view
		var componentsToAdd = [ECComponentView]()
		
		// Get the start & end points in the array of touch points the convert to the GridPoint
		let gRevisedStartTouchPoint = GridPoint(revisedTouchPoints.first!)
		let gRevisedEndTouchPoint = GridPoint(revisedTouchPoints.last!)
		
		if ecComponentType == .cable {
			//============================================================
			// Cable
			//============================================================
			if gComponentWidth == 0.0 && chageOfTouchDirectionCount == 0 {
				//============================================================
				// vertically
				//============================================================
				// Get the length
				let gCableLength = gComponentHeight
				
				// Get the direction
				let cableDirection: ECComponentDirection = gRevisedStartTouchPoint.isAbove(gRevisedEndTouchPoint) ? .downward : .upward
				
				// Get the origin
				let gCableOrigin = gRevisedStartTouchPoint
				
				// Create the cable
				let componentManager = ECComponentManager.sharedInstance
				if let newCable = componentManager.createCable(at: gCableOrigin, for: gCableLength, forward: cableDirection, isExtension: true) {
					// Add to the array
					componentsToAdd.append(newCable)
				}
			} else if gComponentHeight == 0.0 && chageOfTouchDirectionCount == 0 {
				//============================================================
				// horizontally
				//============================================================
				// Get the length
				let gCableLength = gComponentWidth
				
				// Get the direction
				let cableDirection: ECComponentDirection = gRevisedStartTouchPoint.isLeftSide(of: gRevisedEndTouchPoint) ? .rightward : .leftward
				
				// Get the origin
				let gCableOrigin = gRevisedStartTouchPoint
				
				// Create the cable
				let componentManager = ECComponentManager.sharedInstance
				if let newCable = componentManager.createCable(at: gCableOrigin, for: gCableLength, forward: cableDirection, isExtension: true) {
					// Add to the array
					componentsToAdd.append(newCable)
				}
			} else {
				//============================================================
				// In case there is a middle point
				//============================================================
				// Get the vertices of the rect
				let verticesInComponentRect: [CGPoint] = [
					componentRect.origin,
					CGPoint(x: componentRect.maxX, y: componentRect.minY),
					CGPoint(x: componentRect.minX, y: componentRect.maxY),
					CGPoint(x: componentRect.maxX, y: componentRect.maxY)]
				
				// Both the startpoint and the endpoint must be on the vertices of the rect
				if !verticesInComponentRect.contains(gRevisedStartTouchPoint.cgPoint) || !verticesInComponentRect.contains(gRevisedEndTouchPoint.cgPoint) {
					return nil
				}
				
				// Get the vertices among the touchpoints
				var gRectVerticesInTouchPoints: [GridPoint] = []
				for point in revisedTouchPoints {
					if verticesInComponentRect.contains(point) {
						gRectVerticesInTouchPoints.append(point.gridPoint)
					}
				}
				
				if gRectVerticesInTouchPoints.count == 3 && chageOfTouchDirectionCount == 1 {
					//============================================================
					// In case that the number of middle points is 1
					//============================================================
					// Get the middlepoints
					let gRevisedMiddleTouchPoint = gRectVerticesInTouchPoints[1]
					
					if gRevisedMiddleTouchPoint.isOnSameVertical(with: gRevisedEndTouchPoint) {
						//============================================================
						// vertically
						//============================================================
						// Get the direction
						let cableDirection: ECComponentDirection = gRevisedMiddleTouchPoint.isAbove(gRevisedEndTouchPoint) ? .downward : .upward
						let extensionCableDirection: ECComponentDirection = gRevisedStartTouchPoint.isLeftSide(of: gRevisedMiddleTouchPoint) ? .rightward : .leftward
						
						// Get the length
						let gExtensionCableLength = gComponentWidth
						let gCableLength = gComponentHeight
						
						// Create the cables
						let componentManager = ECComponentManager.sharedInstance
						if	let extensionCable = componentManager.createCable(at: gRevisedStartTouchPoint, for: gExtensionCableLength, forward: extensionCableDirection, isExtension: true),
							let cable = componentManager.createCable(at: gRevisedMiddleTouchPoint, for: gCableLength, forward: cableDirection, isExtension: true) {
							// add to the list
							componentsToAdd.append(contentsOf: [extensionCable, cable])
						}
					} else {
						//============================================================
						// horizontally
						//============================================================
						// Get the direction
						let cableDirection: ECComponentDirection = gRevisedMiddleTouchPoint.isLeftSide(of: gRevisedEndTouchPoint) ? .rightward : .leftward
						let extensionCableDirection: ECComponentDirection = gRevisedStartTouchPoint.isAbove(gRevisedMiddleTouchPoint) ? .downward : .upward
						
						// Get the length
						let gExtensionCableLength = gComponentHeight
						let gCableLength = gComponentWidth
						
						// Create the cables
						let componentManager = ECComponentManager.sharedInstance
						if	let extensionCable = componentManager.createCable(at: gRevisedStartTouchPoint, for: gExtensionCableLength, forward: extensionCableDirection, isExtension: true),
							let cable = componentManager.createCable(at: gRevisedMiddleTouchPoint, for: gCableLength, forward: cableDirection, isExtension: true) {
							// Add to the array
							componentsToAdd.append(contentsOf: [cable, extensionCable])
						}
					}
				} else if gRectVerticesInTouchPoints.count == 4 && chageOfTouchDirectionCount == 2 {
					//============================================================
					// In case that the number of middle points is 2
					//============================================================
					if gRevisedStartTouchPoint.isOnSameHorizontal(with: gRevisedEndTouchPoint) {
						//============================================================
						// horizontally
						//============================================================
						// Get the middlepoints
						let gRevisedMiddleTouchPoints: [GridPoint]
						if gRectVerticesInTouchPoints[1].isOnSameVertical(with: gRevisedStartTouchPoint) {
							gRevisedMiddleTouchPoints = [gRectVerticesInTouchPoints[1], gRectVerticesInTouchPoints[2]]
						} else {
							gRevisedMiddleTouchPoints = [gRectVerticesInTouchPoints[2], gRectVerticesInTouchPoints[1]]
						}
						
						// Get the direction of extension cable(the second extension cable will be forwarded to the opposite direction of first cable)
						let firstExtensionCableDirection: ECComponentDirection = gRevisedStartTouchPoint.isBelow(gRevisedMiddleTouchPoints[0]) ? .upward : .downward
						
						// Get the direction
						let cableDirection: ECComponentDirection = gRevisedMiddleTouchPoints[0].isLeftSide(of: gRevisedMiddleTouchPoints[1]) ? .rightward : .leftward
						
						// Get the length
						let gCableLength = gComponentWidth
						
						// Create the cables
						let componentManager = ECComponentManager.sharedInstance
						if	let firstExtensionCable = componentManager.createCable(at: gRevisedStartTouchPoint, for: gComponentHeight, forward: firstExtensionCableDirection, isExtension: true),
							let cable = componentManager.createCable(at: gRevisedMiddleTouchPoints[0], for: gCableLength, forward: cableDirection, isExtension: true),
							let secondExtensionCable = componentManager.createCable(at: gRevisedMiddleTouchPoints[1], for: gComponentHeight, forward: firstExtensionCableDirection.getOppositeDirection(), isExtension: true) {
							// add to the list
							componentsToAdd.append(contentsOf: [firstExtensionCable, cable, secondExtensionCable])
						}
					} else if gRevisedStartTouchPoint.isOnSameVertical(with: gRevisedEndTouchPoint) {
						//============================================================
						// vertically
						//============================================================
						// Get the middlepoints
						let gRevisedMiddleTouchPoints: [GridPoint]
						if gRectVerticesInTouchPoints[1].isOnSameHorizontal(with: gRevisedStartTouchPoint) {
							gRevisedMiddleTouchPoints = [gRectVerticesInTouchPoints[1], gRectVerticesInTouchPoints[2]]
						} else {
							gRevisedMiddleTouchPoints = [gRectVerticesInTouchPoints[2], gRectVerticesInTouchPoints[1]]
						}
						
						// Get the direction of cables
						let firstExtensionCableDirection: ECComponentDirection = gRevisedStartTouchPoint.isLeftSide(of: gRevisedMiddleTouchPoints[0]) ? .rightward : .leftward
						let cableDirection: ECComponentDirection = gRevisedMiddleTouchPoints[0].isBelow(gRevisedMiddleTouchPoints[1]) ? .upward : .downward
						
						// Get the length
						let gCableLength = gComponentHeight
						
						// Create the cables
						let componentManager = ECComponentManager.sharedInstance
						if	let firstExtensionCable = componentManager.createCable(at: gRevisedStartTouchPoint, for: gComponentWidth, forward: firstExtensionCableDirection, isExtension: true),
							let cable = componentManager.createCable(at: gRevisedMiddleTouchPoints[0], for: gCableLength, forward: cableDirection, isExtension: false),
							let secondExtensionCable = componentManager.createCable(at: gRevisedMiddleTouchPoints[1], for: gComponentWidth, forward: firstExtensionCableDirection.getOppositeDirection(), isExtension: true) {
							// Add to the array
							componentsToAdd.append(contentsOf: [firstExtensionCable, cable, secondExtensionCable])
						}
					}
				}
			}
		} else {
			//============================================================
			// Other electric circuit components
			//============================================================
			if gComponentWidth == 0.0 && chageOfTouchDirectionCount == 0 {
				//============================================================
				// vertically
				//============================================================
				// If the height of rect is smaller than gECComponentImageSize, don't create an EC component
				if gComponentHeight < gECComponentSymbolImageSize {
					return nil
				}
				
				// The origin of EC component need to be modified to match the location of grid (or base) to the grid line in case of transistor or vacuum tube.
				let needToModifyOrigin: Bool = ((ecComponentType == .tube || ecComponentType == .transistor) && Int(gComponentHeight) % 2 != 0)
				
				// Calculate the length of cable
				let gCableLength1: CGFloat, gCableLength2: CGFloat
				if needToModifyOrigin {
					gCableLength1 = (gComponentHeight - gECComponentSymbolImageSize - 1.0) / 2.0
					gCableLength2 = gCableLength1 + 1.0
				} else {
					gCableLength1 = (gComponentHeight - gECComponentSymbolImageSize) / 2.0
					gCableLength2 = gCableLength1
				}
				
				
				// Set the direction of EC component
				let componentDirection: ECComponentDirection = gRevisedStartTouchPoint.isAbove(gRevisedEndTouchPoint) ? .downward : .upward
				
				// Calculate the grided origin of EC component
				let gComponentOrigin = GridPoint(gx: gRevisedStartTouchPoint.gx, gy: gRevisedStartTouchPoint.gy + (componentDirection == .downward ? gCableLength1 : -gCableLength1))
				
				let componentManager = ECComponentManager.sharedInstance
				
				// Create EC component and the cables
				if	let newComponent = componentManager.createECComponent(at: gComponentOrigin, forward: componentDirection, withType: ecComponentType),
					let cable1 = componentManager.createCable(at: gRevisedStartTouchPoint, for: gCableLength1, forward: componentDirection, isExtension: false),
					let cable2 = componentManager.createCable(at: GridPoint(gx: gRevisedEndTouchPoint.gx, gy: gComponentOrigin.gy + (componentDirection == .downward ? gECComponentSymbolImageSize : -gECComponentSymbolImageSize)), for: gCableLength2, forward: componentDirection, isExtension: false) {
					// Add to the array
					componentsToAdd += [newComponent, cable1, cable2]
					
					// 3rd cable: for vacuum tube & transistor
					if newComponent.numberOfNodes == 3 {
						let gCableOrigin: GridPoint
						let cableDirection: ECComponentDirection
						let gCableLength: CGFloat
						
						if componentDirection == .downward {
							gCableOrigin = GridPoint(gx: gComponentOrigin.gx - gECComponentSymbolImageSize / 2.0, gy: gComponentOrigin.gy + gECComponentSymbolImageSize / 2.0)
							cableDirection = .leftward
							gCableLength = (gComponentOrigin.gx - gECComponentSymbolImageSize / 2.0) - floor(gComponentOrigin.gx - gECComponentSymbolImageSize / 2.0)
						} else {
							gCableOrigin = GridPoint(gx: gComponentOrigin.gx + gECComponentSymbolImageSize / 2.0, gy: gComponentOrigin.gy - gECComponentSymbolImageSize / 2.0)
							cableDirection = .rightward
							gCableLength = ceil(gComponentOrigin.gx + gECComponentSymbolImageSize / 2.0) - (gComponentOrigin.gx + gECComponentSymbolImageSize / 2.0)
						}
						
						if let cable3 = componentManager.createCable(at: gCableOrigin, for: gCableLength, forward: cableDirection, isExtension: false) {
							componentsToAdd.append(cable3)
						}
					}
				}
			} else if gComponentHeight == 0.0 && chageOfTouchDirectionCount == 0 {
				//============================================================
				// horizontally
				//============================================================
				// If the width of the rect is smaller than gECComponentImageSize, don't create an ECC
				if gComponentWidth < gECComponentSymbolImageSize {
					return nil
				}
				
				// The origin of ECC needs to be modified to be matched to the location of grid line in case of transistor or vacuum tube.
				let needToModifyOrigin: Bool = ((ecComponentType == .tube || ecComponentType == .transistor) && Int(gComponentWidth) % 2 != 0)
				
				// Calculate the length of cable
				let gCableLength1: CGFloat, gCableLength2: CGFloat
				if needToModifyOrigin {
					gCableLength1 = (gComponentWidth - gECComponentSymbolImageSize - 1.0) / 2.0
					gCableLength2 = gCableLength1 + 1.0
				} else {
					gCableLength1 = (gComponentWidth - gECComponentSymbolImageSize) / 2.0
					gCableLength2 = gCableLength1
				}
				
				// Set the direction of ECC
				let componentDirection: ECComponentDirection = gRevisedStartTouchPoint.isLeftSide(of: gRevisedEndTouchPoint) ? .rightward : .leftward
				
				// Calculate the origin of ECC
				let gComponentOrigin = GridPoint(gx: gRevisedStartTouchPoint.gx + (componentDirection == .rightward ? gCableLength1 : -gCableLength1), gy: gRevisedStartTouchPoint.gy)
				
				let componentManager = ECComponentManager.sharedInstance
				
				// Create EC component and the cables
				if	let newComponent = componentManager.createECComponent(at: gComponentOrigin, forward: componentDirection, withType: ecComponentType),
					let cable1 = componentManager.createCable(at: gRevisedStartTouchPoint, for: gCableLength1, forward: componentDirection, isExtension: false),
					let cable2 = componentManager.createCable(at: GridPoint(gx: gComponentOrigin.gx + (componentDirection == .rightward ? gECComponentSymbolImageSize : -gECComponentSymbolImageSize), gy: gComponentOrigin.gy), for: gCableLength2, forward: componentDirection, isExtension: false) {
					// Add to the array
					componentsToAdd += [newComponent, cable1, cable2]
					
					// 3rd cable: for vacuum tube & transistor
					if newComponent.numberOfNodes == 3 {
						let gCableOrigin: GridPoint
						let cableDirection: ECComponentDirection
						let gCableLength: CGFloat
						
						if componentDirection == .rightward {
							gCableOrigin = GridPoint(gx: gComponentOrigin.gx + gECComponentSymbolImageSize / 2.0, gy: gComponentOrigin.gy + gECComponentSymbolImageSize / 2.0)
							cableDirection = .downward
							gCableLength = ceil(gComponentOrigin.gy + gECComponentSymbolImageSize / 2.0) - (gComponentOrigin.gy + gECComponentSymbolImageSize / 2.0)
						} else {
							gCableOrigin = GridPoint(gx: gComponentOrigin.gx - gECComponentSymbolImageSize / 2.0, gy: gComponentOrigin.gy - gECComponentSymbolImageSize / 2.0)
							cableDirection = .upward
							gCableLength = (gComponentOrigin.gy - gECComponentSymbolImageSize / 2.0) - floor(gComponentOrigin.gy - gECComponentSymbolImageSize / 2.0)
						}
						
						if let cable3 = componentManager.createCable(at: gCableOrigin, for: gCableLength, forward: cableDirection, isExtension: false) {
							componentsToAdd.append(cable3)
						}
					}
				}
			} else {
				//============================================================
				// In case there is a middle point
				//============================================================
				// A middlepoint is not allowed in case that the number of nodes is 3
				if ecComponentType == .tube || ecComponentType == .transistor {
					return nil
				}
				
				// Get the vertices of the rect
				let verticesInComponentRect: [CGPoint] = [
					componentRect.origin,
					CGPoint(x: componentRect.maxX, y: componentRect.minY),
					CGPoint(x: componentRect.minX, y: componentRect.maxY),
					CGPoint(x: componentRect.maxX, y: componentRect.maxY)]
				
				// Both the startpoint and the endpoint must be on the vertices of the rect
				if !verticesInComponentRect.contains(gRevisedStartTouchPoint.cgPoint) || !verticesInComponentRect.contains(gRevisedEndTouchPoint.cgPoint) {
					return nil
				}
				
				// Get the vertices among the touchpoints
				var gRectVerticesInTouchPoints: [GridPoint] = []
				for point in revisedTouchPoints {
					if verticesInComponentRect.contains(point) {
						gRectVerticesInTouchPoints.append(point.gridPoint)
					}
				}
				
				if gRectVerticesInTouchPoints.count == 3 && chageOfTouchDirectionCount == 1 {
					//============================================================
					// In case that the number of middle points is 1
					//============================================================
					// Get the middle point
					let gRevisedMiddleTouchPoint = gRectVerticesInTouchPoints[1]
					
					if gRevisedMiddleTouchPoint.isOnSameVertical(with: gRevisedEndTouchPoint) {
						//============================================================
						// vertically
						//============================================================
						if gComponentHeight < gECComponentSymbolImageSize {
							return nil
						}
						
						// Set the direction of ECC
						let componentDirection: ECComponentDirection = gRevisedMiddleTouchPoint.isAbove(gRevisedEndTouchPoint) ? .downward : .upward
						
						// Set the direction of extension cable
						let extensionCableDirection: ECComponentDirection = gRevisedStartTouchPoint.isLeftSide(of: gRevisedMiddleTouchPoint) ? .rightward : .leftward
						
						// Calculate the length of cable
						let gExtensionCableLength = gComponentWidth
						let gCableLength = (gComponentHeight - gECComponentSymbolImageSize) / 2.0
						
						// Calculate the origin of ECC
						let gComponentOrigin = GridPoint(gx: gRevisedMiddleTouchPoint.gx, gy: gRevisedMiddleTouchPoint.gy + (componentDirection == .downward ? gCableLength : -gCableLength))
						
						// Calculate the origin of end-cable
						let gEndCableOrigin = GridPoint(gx: gRevisedEndTouchPoint.gx, gy: gRevisedEndTouchPoint.gy - (componentDirection == .downward ? gCableLength : -gCableLength))
						
						// Create an EC component and the cables
						let componentManager = ECComponentManager.sharedInstance
						if	let newComponent = componentManager.createECComponent(at: gComponentOrigin, forward: componentDirection, withType: ecComponentType),
							let extensionCable = componentManager.createCable(at: gRevisedStartTouchPoint, for: gExtensionCableLength, forward: extensionCableDirection, isExtension: true),
							let startCable = componentManager.createCable(at: gRevisedMiddleTouchPoint, for: gCableLength, forward: componentDirection, isExtension: false),
							let endCable = componentManager.createCable(at: gEndCableOrigin, for: gCableLength, forward: componentDirection, isExtension: false) {
							// Add to the array
							componentsToAdd += [newComponent, extensionCable, startCable, endCable]
						}
					} else {
						//============================================================
						// horizontally
						//============================================================
						if gComponentWidth < gECComponentSymbolImageSize {
							return nil
						}
						
						// Set the direction of ECC
						let componentDirection: ECComponentDirection = gRevisedMiddleTouchPoint.isLeftSide(of: gRevisedEndTouchPoint) ? .rightward : .leftward
						
						// Set the direction of extension cable
						let extensionCableDirection: ECComponentDirection = gRevisedStartTouchPoint.isAbove(gRevisedMiddleTouchPoint) ? .downward : .upward
						
						// Calculate the length of cable
						let gExtensionCableLength = gComponentHeight
						let gCableLength = (gComponentWidth - gECComponentSymbolImageSize) / 2.0
						
						// Calculate the origin of ECC
						let gComponentOrigin = GridPoint(gx: gRevisedMiddleTouchPoint.gx + (componentDirection == .rightward ? gCableLength : -gCableLength), gy: gRevisedMiddleTouchPoint.gy)
						
						// Calculate the origin of end-cable
						let gEndCableOrigin = GridPoint(gx: gRevisedEndTouchPoint.gx - (componentDirection == .rightward ? gCableLength : -gCableLength), gy: gRevisedEndTouchPoint.gy)
						
						// Create an EC component and the cables
						let componentManager = ECComponentManager.sharedInstance
						if	let newComponent = componentManager.createECComponent(at: gComponentOrigin, forward: componentDirection, withType: ecComponentType),
							let extensionCable = componentManager.createCable(at: gRevisedStartTouchPoint, for: gExtensionCableLength, forward: extensionCableDirection, isExtension: true),
							let startCable = componentManager.createCable(at: gRevisedMiddleTouchPoint, for: gCableLength, forward: componentDirection, isExtension: false),
							let endCable = componentManager.createCable(at: gEndCableOrigin, for: gCableLength, forward: componentDirection, isExtension: false) {
							// Add to the array
							componentsToAdd += [newComponent, extensionCable, startCable, endCable]
						}
					}
				} else if gRectVerticesInTouchPoints.count == 4 && chageOfTouchDirectionCount == 2 {
					//============================================================
					// In case that the number of middle points is 2
					//============================================================
					if gRevisedStartTouchPoint.isOnSameHorizontal(with: gRevisedEndTouchPoint) {
						//============================================================
						// horizontally
						//============================================================
						// Get the middlepoints
						let gRevisedMiddleTouchPoints: [GridPoint]
						if gRectVerticesInTouchPoints[1].isOnSameVertical(with: gRevisedStartTouchPoint) {
							gRevisedMiddleTouchPoints = [gRectVerticesInTouchPoints[1], gRectVerticesInTouchPoints[2]]
						} else {
							gRevisedMiddleTouchPoints = [gRectVerticesInTouchPoints[2], gRectVerticesInTouchPoints[1]]
						}
						
						// Check the validation of rect
						if gComponentWidth < gECComponentSymbolImageSize {
							return nil
						}
						
						// Calculate the direction of extension cable(the second extension cable will be forwarded to the opposite direction of first cable)
						let firstExtensionCableDirection: ECComponentDirection = gRevisedStartTouchPoint.isBelow(gRevisedMiddleTouchPoints[0]) ? .upward : .downward
						
						// Calculate the direction of ECC
						let componentDirection: ECComponentDirection = gRevisedMiddleTouchPoints[0].isLeftSide(of: gRevisedMiddleTouchPoints[1]) ? .rightward : .leftward
						
						// Calculate the length of cable
						let gCableLength = (gComponentWidth - gECComponentSymbolImageSize) / 2.0
						
						// Calculate the origin of ECC
						let gComponentOrigin = GridPoint(gx: gRevisedMiddleTouchPoints[0].gx + (componentDirection == .rightward ? gCableLength : -gCableLength), gy: gRevisedMiddleTouchPoints[0].gy)
						
						// Calculate the origin of endcable
						let endCableOrigin = GridPoint(gx: gComponentOrigin.gx + (componentDirection == .rightward ? gECComponentSymbolImageSize : -gECComponentSymbolImageSize), gy: gComponentOrigin.gy)
						
						// Create the ECC
						let componentManager = ECComponentManager.sharedInstance
						if	let newComponent = componentManager.createECComponent(at: gComponentOrigin, forward: componentDirection, withType: ecComponentType),
							let firstExtensionCable = componentManager.createCable(at: gRevisedStartTouchPoint, for: gComponentHeight, forward: firstExtensionCableDirection, isExtension: true),
							let startCable = componentManager.createCable(at: gRevisedMiddleTouchPoints[0], for: gCableLength, forward: componentDirection, isExtension: false),
							let endCable = componentManager.createCable(at: endCableOrigin, for: gCableLength, forward: componentDirection, isExtension: false),
							let secondExtensionCable = componentManager.createCable(at: gRevisedMiddleTouchPoints[1], for: gComponentHeight, forward: firstExtensionCableDirection.getOppositeDirection(), isExtension: true) {
							// Add to the array
							componentsToAdd += [newComponent, firstExtensionCable, startCable, endCable, secondExtensionCable]
						}
					} else if gRevisedStartTouchPoint.isOnSameVertical(with: gRevisedEndTouchPoint) {
						//============================================================
						// vertically
						//============================================================
						// Get the middlepoints
						let gRevisedMiddleTouchPoints: [GridPoint]
						if gRectVerticesInTouchPoints[1].isOnSameHorizontal(with: gRevisedStartTouchPoint) {
							gRevisedMiddleTouchPoints = [gRectVerticesInTouchPoints[1], gRectVerticesInTouchPoints[2]]
						} else {
							gRevisedMiddleTouchPoints = [gRectVerticesInTouchPoints[2], gRectVerticesInTouchPoints[1]]
						}
						
						// Check the validation of rect
						if gComponentHeight < gECComponentSymbolImageSize {
							return nil
						}
						
						// Calculate the direction of extension cable(the second extension cable will be forwarded to the opposite direction of first cable)
						let firstExtensionCableDirection: ECComponentDirection = gRevisedStartTouchPoint.isLeftSide(of: gRevisedMiddleTouchPoints[0]) ? .rightward : .leftward
						
						// Calculate the direction of ECC
						let componentDirection: ECComponentDirection = gRevisedMiddleTouchPoints[0].isBelow(gRevisedMiddleTouchPoints[1]) ? .upward : .downward
						
						// Calculate the length of cable
						let gCableLength = (gComponentHeight - gECComponentSymbolImageSize) / 2.0
						
						// Calculate the origin of ECC
						let gComponentOrigin = GridPoint(gx: gRevisedMiddleTouchPoints[0].gx, gy: gRevisedMiddleTouchPoints[0].gy + (componentDirection == .downward ? gCableLength : -gCableLength))
						
						// get the origin of second cable
						let endCableOrigin = GridPoint(gx: gComponentOrigin.gx, gy: gComponentOrigin.gy + (componentDirection == .downward ? gECComponentSymbolImageSize : -gECComponentSymbolImageSize))
						
						// create core element
						let componentManager = ECComponentManager.sharedInstance
						if	let newComponent = componentManager.createECComponent(at: gComponentOrigin, forward: componentDirection, withType: ecComponentType),
							let firstExtensionCable = componentManager.createCable(at: gRevisedStartTouchPoint, for: gComponentWidth, forward: firstExtensionCableDirection, isExtension: true),
							let startCable = componentManager.createCable(at: gRevisedMiddleTouchPoints[0], for: gCableLength, forward: componentDirection, isExtension: false),
							let endCable = componentManager.createCable(at: endCableOrigin, for: gCableLength, forward: componentDirection, isExtension: false),
							let secondExtensionCable = componentManager.createCable(at: gRevisedMiddleTouchPoints[1], for: gComponentWidth, forward: firstExtensionCableDirection.getOppositeDirection(), isExtension: true) {
							// Add to the array
							componentsToAdd += [newComponent, firstExtensionCable, startCable, endCable, secondExtensionCable]
						}
					}
				}
			}			// The end of middlepoint
		}
		
		
		
		// Add to the parent
		for component in componentsToAdd {
			addSubview(component)
		}
		
		// Create the ECNs then connect them with the ECCs
		let ecGraph = ECGraph.sharedInstance
		let nodesToAdd = ecGraph.connect(ecComponents: componentsToAdd)
		
		// Add them to the parent
		for node in nodesToAdd {
			addSubview(node)
		}
		
//		print(ecGraph)
		
		return componentsToAdd.first
	}
	
	/// Split the EC cable which is stored at the beginning and the end of the touch event
	private func splitCable() {
		let nodeManager = ECNodeManager.sharedInstance
		let componentManager = ECComponentManager.sharedInstance
		
		// The array of ECCables created newly
		var newCables: [ECComponentView] = []
		
		// Get the first-touched ECCable
		if let component = touchedECComponents.0, let touchPoint = revisedTouchPoints.first {
			// Get a ECN existing at the first-touched point
			let splitNode = nodeManager.getECNode(at: touchPoint.gridPoint, allowOverlapped: false)
			
			// Split the cable with the split node
			if let newCable = componentManager.splitCable(component, by: splitNode) {
				newCables.append(newCable)
			}
		}
		
		// Get the second-touched ECCable
		if let component = touchedECComponents.1, let touchPoint = revisedTouchPoints.last {
			// Get a ECN existing at the first-touched point
			let splitNode = nodeManager.getECNode(at: touchPoint.gridPoint, allowOverlapped: false)
			
			// Split the cable with the split node
			if let newCable = componentManager.splitCable(component, by: splitNode) {
				newCables.append(newCable)
			}
		}
		
		// Add the new EC cables to the superview
		for newCable in newCables {
			addSubview(newCable)
		}
		
//		print(ECGraph.sharedInstance)
	}
	
	/// Invert an ECC and the dependents
	///
	/// - Parameters:
	///   - ecComponent: the ECC to be inverted
	///   - option: the direction of inverting
	private func invert(ecComponent: ECComponentView, option: ECComponentReversalOption) {
		// In case that the number of nodes is less than 3
		if ecComponent.numberOfNodes < 3 {
			ecComponent.invert(option: option)
			return
		}
		
		//============================================================
		// In case that the number of nodes is more than 2
		//============================================================
		// Get the nodes that include to the ECC
		var middleNode: ECNodeView!
		let ecGraph = ECGraph.sharedInstance
		for node in ecGraph.findECNodes(connectedTo: ecComponent) {
			if node.gOrigin != ecComponent.gOrigin && node.gOrigin != ecComponent.endpoint {
				middleNode = node
				break
			}
		}
		
		if middleNode != nil {
			// Get the EC cable which is adjacent to the ECC
			if let cable = ecGraph.findECComponents(adjacentTo: ecComponent, through: middleNode).first, cable.isCable {
				let nodeManager = ECNodeManager.sharedInstance
				
				var nodesToAdd: [ECNodeView] = []
				
				// Get another ECN that includes the EC cable
				var outerMiddleNode = ecGraph.findECNode(adjacentTo: middleNode, through: cable)!
				
				//============================================================
				// Move the locations: middle ECN, outer middle ECN and EC cable
				//============================================================
				if	(ecComponent.direction.isVertical() && option == .horizontal) ||
					(ecComponent.direction.isHorizon() && option == .vertical) {
					let translateLocationOfMiddleNode = middleNode.gOrigin.reflect(through: ecComponent.centroid)
					let translateLocationOfOuterMiddleNode = outerMiddleNode.gOrigin.reflect(through: ecComponent.centroid)
					
					if	nodeManager.findECNode(at: translateLocationOfMiddleNode) == nil &&
						nodeManager.findECNode(at: translateLocationOfOuterMiddleNode) == nil {
						// Disconnect the ECCs connected to the outer middle ECN except the EC cable
						if ecGraph.findECComponents(adjacentTo: cable, through: outerMiddleNode).count > 0 {
							ecGraph.disconnect(ecComponent: cable, from: outerMiddleNode)
							
							// Create a new ECN at the location of outer middle ECN.
							outerMiddleNode = nodeManager.getECNode(at: outerMiddleNode.gOrigin, allowOverlapped: true)
							nodesToAdd.append(outerMiddleNode)
							ecGraph.connect(ecComponent: cable, to: outerMiddleNode)
						}
						
						// Invert an image
						ecComponent.invert(option: option)
						
						// Translate the EC cable and the middle ECNs
						middleNode.moveTo(gx: translateLocationOfMiddleNode.gx, gy: translateLocationOfMiddleNode.gy)
						outerMiddleNode.moveTo(gx: translateLocationOfOuterMiddleNode.gx, gy: translateLocationOfOuterMiddleNode.gy)
						cable.reflect(through: ecComponent.centroid)
					}
				} else {
					// Just invert an image
					ecComponent.invert(option: option)
				}
				
				// Add new ECNs to the superview
				for newNode in nodesToAdd {
					addSubview(newNode)
				}
			}	// end of cable
		}	// end of middle node
	}
	
	/// Remove an ECC and the dependents
	///
	/// - Parameters:
	///   - ecComponent: an ECC to be remove
	///   - option: remove all dependents together, or single ECC
	private func remove(ecComponent: ECComponentView) {
		let ecGraph = ECGraph.sharedInstance
		let ecComponentManager = ECComponentManager.sharedInstance
		let ecNodeManager = ECNodeManager.sharedInstance
		
		if ecComponent.isCable {
			if ecComponent.isExtensionCable {
				// Get an array of the ECNs which is connected to this extension cable only
				let nodesToRemove = ecGraph.findECNodes(connectedTo: ecComponent, option: .single)
				
				if nodesToRemove.count == 0 {
					// Disconnect the ECC
					_ = ecGraph.disconnect(ecComponent: ecComponent)
				} else {
					// Remove the ECNs
					for node in nodesToRemove {
						ecNodeManager.removeECNode(node)
						node.removeFromSuperview()
					}
				}
				
				// Remove the EC cable
				ecComponent.removeFromSuperview()
			} else {
				// Get the ECC
				if let component = ecGraph.findECComponent(includes: ecComponent) {
					// Remove it
					remove(ecComponent: component)
				}
			}
		} else {
			//============================================================
			// Remove the ECC including dependents
			//============================================================
			// Get the dependents of the ECC
			let dependents = ecGraph.getECCablesAndNodes(dependentFor: ecComponent)
			
			// Remove the ECCs
			for component in dependents.0 {
				ecComponentManager.removeECComponent(component)
				component.removeFromSuperview()
			}
			
			// Remove the ECNs
			for node in dependents.1 {
				ecNodeManager.removeECNode(node)
				node.removeFromSuperview()
			}
		}
		
//		print(ecGraph)
	}
	
	/// Get an ECC at the point
	///
	/// - Parameter point: a point to find
	/// - Returns: an ECC at the point
	private func ecComponent(at point: CGPoint) -> ECComponentView? {
		for subview in subviews {
			if let component = subview as? ECComponentView, component.frame.contains(point) {
				return component
			}
		}
		
		return nil
	}
	
	/// Reset all electric circuit elements(ECC and ECN)
	func initialize() {
		ECNodeManager.sharedInstance.initialize()
		ECComponentManager.sharedInstance.initialize()
		ECGraph.sharedInstance.initialize()
		
		for subview in subviews {
			if let component = subview as? ECComponentView {
				component.removeFromSuperview()
			} else if let node = subview as? ECNodeView {
				node.removeFromSuperview()
			}
		}
	}
}
