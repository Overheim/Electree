//
//  ECComponentManager.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 7..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

/// Manages EC components as creating, deleting and finding a component in specific location.
class ECComponentManager {
	/// Uses as singleton
	static let sharedInstance: ECComponentManager = {
		let instance = ECComponentManager()
		return instance
	}()
	
	/// An index dictionary which is used when creating a EC component. Each index refers to the count of EC components which has been created
	var ecComponentIndices: [ECComponentType : Int] = [
		.acvs : 1,
		.dcvs : 1,
		.resistor : 1,
		.capacitor : 1,
		.inductor : 1,
		.diode : 1,
		.tube : 1,
		.transistor : 1,
		.cable : 1,
		.dummy : 1,
		.dummyTube: 1,
		.dummyTransistor: 1]
	
	/// A prefix string of EC component's name
	private let ecComponentNamePrefixes: [ECComponentType: String] = [
		.acvs : "AC",
		.dcvs : "DC",
		.resistor : "R",
		.capacitor : "C",
		.inductor : "I",
		.diode : "D",
		.tube : "VT",
		.transistor : "TR",
		.cable : "CB",
		.dummy : "DM",
		.dummyTube: "VT",
		.dummyTransistor: "TR"]
	
	/// A list which stores created ECCs
	var ecComponents: Set<ECComponentView> = []
	
	/// The array of ECCs for backup
	private var lastECCs: Set<ECComponentView> = []
	
	/// The dicrtionary of the index of ECCs for backup
	private var lastECCIndices: [ECComponentType : Int] = [:]
	
	/// Init all variables
	func initialize() {
		for key in ecComponentIndices.keys {
			ecComponentIndices[key] = 1
		}
		ecComponents.removeAll()
	}
	
	/// Get a new ID of the type to be created next time
	///
	/// - Parameter type: The type of EC component to be created next time
	/// - Returns: The new ID of the type. Return nil if an wrong type is passed
	func getNewID(of type: ECComponentType) -> String? {
		if let prefix = ecComponentNamePrefixes[type], let index = ecComponentIndices[type] {
			return prefix + String(index)
		} else {
			return nil
		}
	}
	
	/// Create a new ID of the type. It will not be used again.
	///
	/// - Parameter type: The type of EC component to be created
	/// - Returns: The new id of the type
	private func createNewID(of type: ECComponentType) -> String? {
		if let newID = getNewID(of: type) {
			ecComponentIndices[type]! += 1
			return newID
		} else {
			return nil
		}
	}
	
	/// Create EC component at the specified position with the initial property
	///
	/// - Parameters:
	///   - gOrigin: origin by grid
	///   - property: properties
	/// - Returns: A new instance succeeded, nil failed
	func createECComponent(at gOrigin: GridPoint, forward direction: ECComponentDirection, withType type: ECComponentType) -> ECComponentView? {
		if type == .cable {
			return nil
		}
		
		if let newID = createNewID(of: type) {
			let newComponent = ECComponentView(at: gOrigin, id: newID, name: newID, type: type, property: ECComponentProperty(type: type), direction: direction)
			ecComponents.insert(newComponent)
			return newComponent
		} else {
			return nil
		}
	}
	
	/// Remove an EC component
	///
	/// - Parameter ecComponent: an EC Component to be removed
	func removeECComponent(_ ecComponent: ECComponentView) {
		let ecGraph = ECGraph.sharedInstance
		_ = ecGraph.disconnect(ecComponent: ecComponent)
		ecComponents.remove(ecComponent)
	}
	
	/// Create an instance of the ECCableView with new id
	///
	/// - Parameters:
	///   - gOrigin: origin by grid
	///   - gLength: length by grid
	///   - direction: direction
	///   - isExtension: extension option
	/// - Returns: new instance of the ECCableView
	func createCable(at gOrigin: GridPoint, for gLength: CGFloat, forward direction: ECComponentDirection, isExtension: Bool) -> ECComponentView? {
		if let newID = createNewID(of: .cable) {
			return ECComponentView(at: gOrigin, id: newID, for: gLength, forward: direction, isExtension: isExtension)
		} else {
			return nil
		}
	}
	
	/// Get an ECN that includes the location
	///
	/// - Parameter location: the location to find
	/// - Returns: an ECN that includes the location, or nil if there is no ECC at the location
	func getECComponent(includes location: CGPoint) -> ECComponentView? {
		for component in ecComponents {
			if component.frame.contains(location) {
				return component
			}
		}
		
		return nil
	}
	
	/// Split a EC cable by a ECN, which should be on the line of the EC cable.
	///
	/// The existing EC cable is modified as the length is chganged, and a new cable is created where the split ECN exists.
	///
	/// - Parameters:
	///   - ecCable: a EC cable to be split
	///   - ecNode: a ECN that exists on the EC cable
	/// - Returns: the EC cable created
	func splitCable(_ ecCable: ECComponentView, by ecNode: ECNodeView) -> ECComponentView? {
		let graph = ECGraph.sharedInstance
		
		// Get the length of the cable
		let gOldCableLength = ecCable.gLength
		
		// Disconnect the cable from the ECNs except at the origin
		let disconnectedNodes = graph.disconnect(ecComponent: ecCable, atOrigin: false)
		
		// Change length of the cable(modify the rect too)
		ecCable.endpoint = ecNode.gOrigin
		
		// Connect to the split ECN
		graph.connect(ecComponent: ecCable, to: ecNode)
		
		// Create a new cable
		if let newCable = createCable(at: ecNode.gOrigin, for: gOldCableLength - ecCable.gLength, forward: ecCable.direction, isExtension: true) {
			// Connect the new cable
			graph.connect(ecComponent: newCable, to: disconnectedNodes + [ecNode])
			
			// Returns the new cable
			return newCable
		}
		
		return nil
	}
	
	/// Get the list of nonlinear ECCs of which type is either transistor or vacuum tube.
	///
	/// - Returns: an array of ECCs
	func getNonlinearComponents() -> [ECComponentView] {
		return ecComponents.filter { $0.type == .transistor || $0.type == .tube }
	}
	
	/// Store the list of ECCs and indices
	func backup() {
		lastECCs = ecComponents
		lastECCIndices = ecComponentIndices
	}
	
	/// Restore the list of ECCs and indices
	func restore() {
		ecComponents = lastECCs
		ecComponentIndices = lastECCIndices
	}
}
