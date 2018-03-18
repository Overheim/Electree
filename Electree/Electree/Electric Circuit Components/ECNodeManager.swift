//
//  ECNodeManager.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 9..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

class ECNodeManager {
	/// Use as singleton
	static let sharedInstance: ECNodeManager = {
		let instance = ECNodeManager()
		return instance
	}()
	
	/// A list of ECNs created
	var nodes: Set<ECNodeView> = []
	
	/// The index of ECN to be created
	var nodeIndex: Int = 1
	
	/// The array of ECNs for the backup
	private var lastNodes: Set<ECNodeView> = []
	
	/// The index of ECN for the backup
	private var lastNodeIndex: Int = 1
	
	/// The id of ECN for grounding
	let groundingNodeId = "grounding"
	
	/// Reset all variables
	func initialize() {
		nodes.removeAll()
		nodeIndex = 1
	}
	
	/// Create an id of ECN. The id of ECN has no prefix, but only index
	///
	/// - Returns: a new id created
	private func createNewID() -> String {
		let newID = String(nodeIndex)
		nodeIndex += 1
		return newID
	}
	
	/// Find an ECN at given position
	///
	/// - Parameter gPoint: a position to find
	/// - Returns: an ECN found, or nil
	func findECNode(at gPoint: GridPoint) -> ECNodeView? {
		return nodes.filter { $0.gOrigin == gPoint }.first
	}
	
	/// Find an ECN which has the given id
	///
	/// - Parameter id: an ID to find
	/// - Returns: an ECN found, or nil
	func findECNode(with id: String) -> ECNodeView? {
		return nodes.filter { $0.id == id }.first
	}
	
	/// Create or get existing ECN at given point
	///
	/// - Parameters:
	///   - gPoint: the origin of the ECN by grid
	///   - isInner: isInner option
	///   - allowOverlapped: If this option is true, the new ECN will be created absolutely even though there is already an ECN at gPoint
	/// - Returns: An ECN which exists at the point
	func getECNode(at gPoint: GridPoint, allowOverlapped: Bool) -> ECNodeView {
		if let existingNode = findECNode(at: gPoint), !allowOverlapped {
			return existingNode
		} else {
			let newNode = ECNodeView(at: gPoint, id: createNewID())
			nodes.insert(newNode)
			
			return newNode
		}
	}
	
	/// Remove an ECN
	///
	/// - Parameter ecNode: an ECN to be removed
	func removeECNode(_ ecNode: ECNodeView) {
		let ecGraph = ECGraph.sharedInstance
		ecGraph.disconnect(ecNode: ecNode)
		nodes.remove(ecNode)
	}
	
	/// Check there is a ECN at the location
	///
	/// - Parameter gPoint: location to search
	/// - Returns: true existing, false not
	func ecNodeExist(at gPoint: GridPoint) -> Bool {
		return findECNode(at: gPoint) != nil
	}
	
	/// Store the array of ECNs and index
	func backup() {
		lastNodes = nodes
		lastNodeIndex = nodeIndex
	}
	
	/// Restore the array of ECNs and index
	func restore() {
		nodes = lastNodes
		nodeIndex = lastNodeIndex
	}
}
