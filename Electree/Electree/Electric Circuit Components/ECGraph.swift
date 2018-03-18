//
//  ECGraph.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 9..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

/// A relative position of ECN to the ECC
///
/// - startpoint: means an origin of ECC
/// - endpoint: means an endpoint of ECC
/// - middlepoint: means a middlepoint in case that the number of nodes of ECC is more than 3
enum ECNodePosition {
	case startpoint, endpoint, middlepoint
}

/// An option for searching the ECN
///
/// - all: Search an ECN connected to the ECC
/// - single: Search an ECN connected to the one ECC
/// - multiple: Search an ECN connected to the multiple ECC
enum ECNodeSearchOption {
	case all, single, multiple
}

typealias ECNDictionary = [ECNodeView : Set<ECComponentView>]
typealias ECCDictionary = [ECComponentView : (ECNodeView, ECNodeView)]

/// A graph that is composed of ECC as edge and ECN as node.
class ECGraph: CustomStringConvertible {
	var description: String {
		var string: String = "ECGraph: [\n"
		let sortedGraph = graph.sorted(by: { Int($0.0.id)! < Int($1.0.id)! })
		for index in 0..<sortedGraph.count {
			let element = sortedGraph[index]
			
			// key
			string += element.key.id
			string += ": "
			
			// values
			var isFirst = true
			for elemInSet in element.value {
				if !isFirst {
					string += ", "
				}
				string += elemInSet.id
				isFirst = false
			}
			string += "\n"
		}
		string += "]"
		
		return string
	}
	
	/// Use as singleton
	static let sharedInstance: ECGraph = {
		let instance = ECGraph()
		return instance
	}()
	
	/// Stores the connection status of the graph. The key means a node in graph and the value does an edges(ECC) be attached to the node
	var graph: ECNDictionary = [:]
	
	/// The EC graph for backup and restore
	private var lastGraph: ECNDictionary = [:]
	
	// MARK: - init
	/// Reset the graph
	func initialize() {
		graph.removeAll()
	}
	
	// MARK: - Connect the ECC
	
	/// Attach an edge(ECC) to the node
	///
	/// - Parameters:
	///   - component: an edge to be attached
	///   - node: a node to attach
	func connect(ecComponent component: ECComponentView, to node: ECNodeView) {
		var oldValue = graph[node]
		if oldValue != nil {
			oldValue!.insert(component)
			graph[node] = oldValue
		} else {
			graph[node] = Set([component])
		}
	}
	
	/// Attach an edge(ECC) to the several nodes
	///
	/// - Parameters:
	///   - component: an edge to be attached
	///   - nodes: nodes array to attach
	func connect(ecComponent component: ECComponentView, to nodes: [ECNodeView]) {
		for node in nodes {
			connect(ecComponent: component, to: node)
		}
	}
	
	/// Connect the ECNs to both ends of the ECC. If the ECCs are attached together, they share one ECN.
	///
	/// - Parameter components: the ECCs to be added to the graph
	/// - Returns: the ECNs created
	func connect(ecComponents components: [ECComponentView]) -> [ECNodeView] {
		// The array of ECNs to be created and added as the subview
		var nodesToAdd: Set<ECNodeView> = []
		
		for component in components {
			var createdNodes: [ECNodeView] = []
			
			// The origins of each node
			let startNodeOrigin: GridPoint = component.gOrigin
			let endNodeOrigin: GridPoint, middleNodeOrigin: GridPoint
			
			// Calculate the origin of each node
			switch component.direction {
			case .rightward:
				endNodeOrigin = GridPoint(gx: startNodeOrigin.gx + component.frame.width / gridSize, gy: startNodeOrigin.gy)
				middleNodeOrigin = GridPoint(gx: startNodeOrigin.gx + component.frame.width / (2.0 * gridSize), gy: startNodeOrigin.gy + component.frame.height / (2.0 * gridSize))
			case .leftward:
				endNodeOrigin = GridPoint(gx: startNodeOrigin.gx - component.frame.width / gridSize, gy: startNodeOrigin.gy)
				middleNodeOrigin = GridPoint(gx: startNodeOrigin.gx - component.frame.width / (2.0 * gridSize), gy: startNodeOrigin.gy - component.frame.height / (2.0 * gridSize))
			case .upward:
				endNodeOrigin = GridPoint(gx: startNodeOrigin.gx, gy: startNodeOrigin.gy - component.frame.height / gridSize)
				middleNodeOrigin = GridPoint(gx: startNodeOrigin.gx + component.frame.width / (2.0 * gridSize), gy: startNodeOrigin.gy - component.frame.height / (2.0 * gridSize))
			case .downward:
				endNodeOrigin = GridPoint(gx: startNodeOrigin.gx, gy: startNodeOrigin.gy + component.frame.height / gridSize)
				middleNodeOrigin = GridPoint(gx: startNodeOrigin.gx - component.frame.width / (2.0 * gridSize), gy: startNodeOrigin.gy + component.frame.height / (2.0 * gridSize))
			}
			
			let nodeManager = ECNodeManager.sharedInstance
			
			// Create the nodes
			createdNodes.append(nodeManager.getECNode(at: startNodeOrigin, allowOverlapped: false))
			createdNodes.append(nodeManager.getECNode(at: endNodeOrigin, allowOverlapped: false))
			
			// Create the middle node if the ECC requires 3 nodes
			if component.numberOfNodes == 3 {
				createdNodes.append(nodeManager.getECNode(at: middleNodeOrigin, allowOverlapped: false))
			}
			
			// Connect each node then add to the array to be added to the parent
			connect(ecComponent: component, to: createdNodes)
			for node in createdNodes {
				nodesToAdd.insert(node)
			}
		}
		
		return Array(nodesToAdd)
	}
	
	// MARK: - Disconnect the ECC
	
	/// Disconnect the ECC from the ECN
	///
	/// - Parameters:
	///   - ecComponent: an ECC to be disconnected
	///   - ecNode: an ECN connected to the ECC
	func disconnect(ecComponent: ECComponentView, from ecNode: ECNodeView) {
		var components = graph[ecNode]
		if components != nil {
			components!.remove(ecComponent)
			graph[ecNode] = components!.count == 0 ? nil : components!
		}
	}
	
	/// Disconnect the ECC from all the ECN. The ECC will be removed from the graph.
	///
	/// - Parameter ecComponent: an ECC to be removed from the graph
	/// - Returns: the ECNs that had been connected to the ECC
	func disconnect(ecComponent: ECComponentView) -> [ECNodeView] {
		let nodes = findECNodes(connectedTo: ecComponent)
		for node in nodes {
			disconnect(ecComponent: ecComponent, from: node)
		}
		
		return nodes
	}
	
	/// Remove an ECN
	///
	/// - Parameter ecNode: an ECN to be removed
	func disconnect(ecNode: ECNodeView) {
		graph[ecNode] = nil
	}
	
	/// Disconnect the Ecc from the ECN
	///
	/// - Parameters:
	///   - ecComponent: an ECC to be disconnected
	///   - atOrigin: If this option is true, the ECN at the origin of the ECC will be disconnected
	/// - Returns: the ECNs disconnected. nil in case that the ECC wasn't in the graph.
	func disconnect(ecComponent: ECComponentView, atOrigin: Bool) -> [ECNodeView] {
		var disconnectedNodes: [ECNodeView] = []
		
		for node in findECNodes(connectedTo: ecComponent) {
			if (node.gOrigin == ecComponent.gOrigin) == atOrigin {
				disconnect(ecComponent: ecComponent, from: node)
				disconnectedNodes.append(node)
			}
		}
		
		return disconnectedNodes
	}
	
	// MARK: - Find an ECC or ECN
	
	/// Find the ECNs connected to the given ECC
	///
	/// - Parameter ecComponent: the ECC to be searched
	/// - Returns: the array of ECNs connected to the given ECC
	func findECNodes(connectedTo ecComponent: ECComponentView) -> [ECNodeView] {
		return graph.filter { $1.contains(ecComponent) }.map { $0.key }
	}
	
	/// Find the ECN at the given position
	///
	/// - Parameters:
	///   - ecComponent: connected ECC
	///   - position: the position related to the ECC
	/// - Returns: an ECN at the given position
	func findECNode(connectedTo ecComponent: ECComponentView, at position: ECNodePosition) -> ECNodeView? {
		for node in findECNodes(connectedTo: ecComponent) {
			if position == .startpoint && node.gOrigin == ecComponent.gOrigin {
				return node
			} else if position == .endpoint && node.gOrigin == ecComponent.endpoint {
				return node
			} else if position == .middlepoint && node.gOrigin != ecComponent.gOrigin && node.gOrigin != ecComponent.endpoint {
				return node
			}
		}
		return nil
	}
	
	/// Get the ECNs connected to the ECC
	///
	/// - Parameters:
	///   - ecComponent: a base ECC
	///   - option: a search option
	/// - Returns: the ECNs which is connected to the ECC
	func findECNodes(connectedTo ecComponent: ECComponentView, option: ECNodeSearchOption) -> [ECNodeView] {
		switch option {
		case .all:
			return graph.filter { $1.contains(ecComponent) }.map { $0.key }
		case .single:
			return graph.filter { $1.contains(ecComponent) && $1.count == 1 }.map { $0.key }
		case .multiple:
			return graph.filter { $1.contains(ecComponent) && $1.count > 1 }.map { $0.key }
		}
	}
	
	/// Get the ECNs connected to the ECC
	///
	/// - Parameters:
	///   - ecComponent: an base ECC
	///   - option: a search option
	///   - graph: search in this graph
	/// - Returns: the ECNs which is connected to the ECC
	func findECNodes(connectedTo ecComponent: ECComponentView, option: ECNodeSearchOption, in graph: ECNDictionary) -> [ECNodeView] {
		switch option {
		case .all:
			return graph.filter { $1.contains(ecComponent) }.map { $0.key }
		case .single:
			return graph.filter { $1.contains(ecComponent) && $1.count == 1 }.map { $0.key }
		case .multiple:
			return graph.filter { $1.contains(ecComponent) && $1.count > 1 }.map { $0.key }
		}
	}
	
	/// Find the ECCs that is adjacent to the given ECC
	///
	/// - Parameters:
	///   - ecComponent: the base ECC
	///   - ecNode: The ECCs should be adjacent through this node
	/// - Returns: adjacent ECCs
	func findECComponents(adjacentTo ecComponent: ECComponentView, through ecNode: ECNodeView) -> [ECComponentView] {
		var adjacentComponents: [ECComponentView] = []
		if let components = graph[ecNode] {
			for component in components {
				if component != ecComponent {
					adjacentComponents.append(component)
				}
			}
		}
		
		return adjacentComponents
	}
	
	/// Find the ECCs that is adjacent to the given ECC
	///
	/// - Parameters:
	///   - ecComponent: the base ECC
	///   - ecNode: The ECCs should be adjacent through this node
	///   - graph: search in this graph
	/// - Returns: adjacent ECCs
	func findECComponents(adjacentTo ecComponent: ECComponentView, through ecNode: ECNodeView, in graph: ECNDictionary) -> [ECComponentView] {
		var adjacentComponents: [ECComponentView] = []
		if let components = graph[ecNode] {
			for component in components {
				if component != ecComponent {
					adjacentComponents.append(component)
				}
			}
		}
		
		return adjacentComponents
	}
	
	/// Find an ECC that includes the EC cable. If the EC cable is extension, nil will be returned
	///
	/// - Parameter ecCable: the EC cable which is included
	/// - Returns: an ECC that includes the EC cable
	func findECComponent(includes ecCable: ECComponentView) -> ECComponentView? {
		for node in findECNodes(connectedTo: ecCable) {
			// Get all adjacent ECCs connected the ECN
			let adjacentComponents = findECComponents(adjacentTo: ecCable, through: node)
			
			// Check the ECC is not cable
			for component in adjacentComponents {
				if !component.isCable {
					return component
				}
			}
		}
		return nil
	}
	
	/// Find the ECN adjacent to the given ECN
	///
	/// - Parameters:
	///   - ecNode: base ECN
	///   - ecComponent: the ECC which is included to the ECN
	/// - Returns: the ECN that includes the given ECC
	func findECNode(adjacentTo ecNode: ECNodeView, through ecComponent: ECComponentView) -> ECNodeView? {
		let nodes = findECNodes(connectedTo: ecComponent)
		
		if !nodes.contains(ecNode) {
			return nil
		}
		
		for node in nodes {
			if node != ecNode {
				return node
			}
		}
		
		return nil
	}
	
	/// Get the list of ECCs that contains the given set of ECCs
	///
	/// - Parameters:
	///   - ecComponents: the list of ECCs that should be contained
	///   - graph: searched graph
	/// - Returns: the list of ECCs
	func findECNodes(connectedTo ecComponents: Set<ECComponentView>, in graph: ECNDictionary) -> [ECNodeView] {
		return graph.filter { $1.isSuperset(of: ecComponents) }.map { $0.0 }
	}
	
	/// Get the arrays of EC cables and ECNs dependent for the given ECC
	///
	/// - Parameter ecComponent: a base ECC
	/// - Returns: a tuple of EC vables and ECNs dependent for the given ECC
	func getECCablesAndNodes(dependentFor ecComponent: ECComponentView) -> ([ECComponentView], [ECNodeView]) {
		var dependentCables: [ECComponentView] = []
		var dependentNodes: [ECNodeView] = []
		
		getECCablesAndNodes(dependentFor: ecComponent, ioDependentECCables: &dependentCables, ioDependentECNodes: &dependentNodes)
		
		return (dependentCables, dependentNodes)
	}
	
	/// Get the arrays of EC cables and ECNs dependent for the given ECC recursively (private function)
	///
	/// - Parameters:
	///   - ecComponent: a base ECC
	///   - ioDependentECCables: the io variable for the EC cable dependent for the ECC
	///   - ioDependentECNodes: the io variable for the ECN dependent for the ECC
	private func getECCablesAndNodes(dependentFor ecComponent: ECComponentView, ioDependentECCables: inout [ECComponentView], ioDependentECNodes: inout [ECNodeView]) {
		// Return if the ECC is already included in the array
		if ioDependentECCables.contains(ecComponent) {
			return
		}
		
		// Add the ECC to the array
		ioDependentECCables.append(ecComponent)
		
		// Get two ECNs which is connected
		let newConnectedNodes = findECNodes(connectedTo: ecComponent)
		
		for node in newConnectedNodes {
			// Pass the ECN in case checked already or dependent to the other ECC
			if ioDependentECNodes.contains(node) || graph[node]!.count >= 3 {
				continue
			}
			
			// Add both ECNs to the array in case that the ECC is not the cable
			if !ecComponent.isCable || graph[node]!.count <= 1 {
				ioDependentECNodes.append(node)
				
				// Repeat the process
				if let newComponents = graph[node] {
					for newComponent in newComponents {
						getECCablesAndNodes(dependentFor: newComponent, ioDependentECCables: &ioDependentECCables, ioDependentECNodes: &ioDependentECNodes)
					}
				}
			} else {
				// Get another ECC
				if let connectedComponent = findECComponents(adjacentTo: ecComponent, through: node).first {
					
					if connectedComponent.isExtensionCable {
						// Add the ECN to the array if the ECC is the cable
						ioDependentECNodes.append(node)
						
						// Repeat the process
						if let newComponents = graph[node] {
							for newComponent in newComponents {
								getECCablesAndNodes(dependentFor: newComponent, ioDependentECCables: &ioDependentECCables, ioDependentECNodes: &ioDependentECNodes)
							}
						}
					} else {
						// The ECN is not added if the connected EC cable is not the extension
						continue
					}
				}
			}
		}
	}
	
	/// Find an ECC that has a path to the base ECC.
	///
	/// - Parameters:
	///   - baseECC: the base ECC
	///   - throughECN: The path will start at this ECN
	///   - array: the array of ECC
	private func findECComponents(base baseECC: ECComponentView, through throughECN: ECNodeView, storeAt array: inout [ECComponentView]) {
		// Get the connected ECCs
		let connectedECCs = findECComponents(adjacentTo: baseECC, through: throughECN)
		
		for ecc in connectedECCs {
			if !ecc.isCable {
				// Add the array in case of not cable
				array.append(ecc)
			} else {
				// Perform the function recursively
				if let newThroughECN = findECNode(adjacentTo: throughECN, through: ecc) {
					findECComponents(base: ecc, through: newThroughECN, storeAt: &array)
				}
			}
		}
	}
	
	// MARK: - schematics
	
	/// Create the schematics of electric circuit
	///
	/// - Returns: A dictionary of ECC as key and a pair of ECNs as value
	func makeSchematics() -> ECCDictionary {
		var copiedGraph: ECNDictionary = [:]
		let eccManager = ECComponentManager.sharedInstance
		
		//============================================================
		// Split the nonlinear ECC
		//============================================================
		// Get the list of nonlinear ECCs
		let nonlinearECCs = eccManager.getNonlinearComponents()
		
		for ecc in nonlinearECCs {
			if	let startNode = findECNode(connectedTo: ecc, at: .startpoint),
				let endNode = findECNode(connectedTo: ecc, at: .endpoint),
				let middleNode = findECNode(connectedTo: ecc, at: .middlepoint) {
				
				// Disconnect the nonlinear ECC
				_ = disconnect(ecComponent: ecc)
				
				// Add the dummy components
				if ecc.type == .tube {
					addComponents(from: startNode, to: middleNode, type: .dummy)
					addComponents(from: middleNode, to: endNode, type: .dummyTube)
					addComponents(from: startNode, to: endNode, type: .dummyTube)
				} else if ecc.type == .transistor {
					addComponents(from: startNode, to: endNode, type: .dummy)
					addComponents(from: middleNode, to: startNode, type: .dummyTransistor)
					addComponents(from: middleNode, to: endNode, type: .dummyTransistor)
				} else {
//					print("ERROR: Wrong type of nonlinear element(\(ecc.type.rawValue)")
				}
			}
		}
		
		//============================================================
		// Create the schematics
		//============================================================
		for ecc in eccManager.ecComponents {
			// 1. Get the both ECNs connected to the ECC
			for ecn in findECNodes(connectedTo: ecc) {
				
				// 2. Get the list of ECCs through the ECNs
				var connectedECCs: [ECComponentView] = []
				findECComponents(base: ecc, through: ecn, storeAt: &connectedECCs)
				
				// 3. Skip if the connected ECCs are already added
				if connectedECCs.count > 0 && findECNodes(connectedTo: Set(connectedECCs + [ecc]), in: copiedGraph).count > 0 {
					continue
				}
				
				// 4. Add the ECN to the new graph
				copiedGraph[ecn] = Set(connectedECCs + [ecc])
			}
		}
//		print("\nCables removed: \(copiedGraph)")
		
		//============================================================
		// Set the grounding
		//============================================================
		// Create an ECN for grounding
		let ecGroundingNode = ECNodeManager.sharedInstance.getECNode(at: GridPoint(gx: 100, gy: 100), allowOverlapped: true)
		ecGroundingNode.id = ECNodeManager.sharedInstance.groundingNodeId
		
		// Get the list of ECCs that connected to the grounding ECN
		let eccSetForGrounding = copiedGraph.filter { $1.count == 1 }.map { $1 }.reduce([]) { $0 + $1 }
		
		// Set the grounding ECN
		copiedGraph[ecGroundingNode] = Set(eccSetForGrounding)
		
		// Remove the old ECNs that have one ECC
		for ecn in (copiedGraph.filter { $1.count == 1}.map { $0.0 }) {
			copiedGraph[ecn] = nil
		}
		
//		print("\nFinished grounding: \(copiedGraph)")
		
		//============================================================
		// Create the pole table
		//============================================================
		return createPoleTable(in: copiedGraph)
	}
	
	/// Stores the graph
	func backup() {
		lastGraph = graph
	}
	
	/// Restore the lastest stored graph
	func restore() {
		graph = lastGraph
	}
	
	/// Add a set of ECC and EC cables to the graph. The set contains two cables, of which one cable starts at the startNode and another cable ends at endNode, and one ECC.
	///
	/// - Parameters:
	///   - startNode: a startpoint of EC cable
	///   - endNode: an endpoint of EC cable
	///   - type: a type of ECC
	private func addComponents(from startNode: ECNodeView, to endNode: ECNodeView, type: ECComponentType) {
		let eccManager = ECComponentManager.sharedInstance
		let ecnManager = ECNodeManager.sharedInstance
		let dummyOrigin = GridPoint(gx: 0, gy: 0)
		
		var newNode = ecnManager.getECNode(at: dummyOrigin, allowOverlapped: true)
		connect(ecComponent: eccManager.createCable(at: dummyOrigin, for: 0, forward: .downward, isExtension: false)!, to: [startNode, newNode])
		var lastNode = newNode
		
		newNode = ecnManager.getECNode(at: dummyOrigin, allowOverlapped: true)
		connect(ecComponent: eccManager.createECComponent(at: dummyOrigin, forward: .downward, withType: type)!, to: [lastNode, newNode])
		lastNode = newNode
		
		connect(ecComponent: eccManager.createCable(at: dummyOrigin, for: 0, forward: .downward, isExtension: false)!, to: [lastNode, endNode])
	}
	
	/// Add a set of ECC and EC cables to the graph. The set contains two cables, of which one cable starts at the startNode, and one ECC.
	///
	/// - Parameters:
	///   - startNode: a startpoint of EC cable
	///   - type: a type of ECC
	/// - Returns: an ECN which is created last
	private func addComponents(from startNode: ECNodeView, type: ECComponentType) -> ECNodeView {
		let eccManager = ECComponentManager.sharedInstance
		let ecnManager = ECNodeManager.sharedInstance
		let dummyOrigin = GridPoint(gx: 0, gy: 0)
		
		var newNode = ecnManager.getECNode(at: dummyOrigin, allowOverlapped: true)
		connect(ecComponent: eccManager.createCable(at: dummyOrigin, for: 0, forward: .downward, isExtension: false)!, to: [startNode, newNode])
		var lastNode = newNode
		
		newNode = ecnManager.getECNode(at: dummyOrigin, allowOverlapped: true)
		connect(ecComponent: eccManager.createECComponent(at: dummyOrigin, forward: .downward, withType: type)!, to: [lastNode, newNode])
		lastNode = newNode
		
		newNode = ecnManager.getECNode(at: dummyOrigin, allowOverlapped: true)
		connect(ecComponent: eccManager.createECComponent(at: dummyOrigin, forward: .downward, withType: type)!, to: [lastNode, newNode])
		
		return newNode
	}
	
	/// Create a pole table, which describes that which ECN is set to the negative/positive pole of ECC
	///
	/// - Parameter graph: the graph which the pole table is created using
	/// - Returns: an ECC dicrtionary, ECC as key and a pair of ECN as values
	private func createPoleTable(in graph: ECNDictionary) -> ECCDictionary {
		var poleTable: ECCDictionary = [:]
		
		// Find the voltage source
		let eccManager = ECComponentManager.sharedInstance
		var eccVoltageSource: ECComponentView!
		for ecc in eccManager.ecComponents {
			if ecc.type == .acvs {
				eccVoltageSource = ecc
				break
			}
		}
		
		if eccVoltageSource == nil {
			return [:]
		}
		
		// Set the poles of the voltage source
		let ecnManager = ECNodeManager.sharedInstance
		let ecns = graph.filter { $1.contains(eccVoltageSource) }.map { $0.0 }
		poleTable[eccVoltageSource] = ecns[0].id == ecnManager.groundingNodeId ? (ecns[0], ecns[1]) : (ecns[1], ecns[0])
		
		// Set the voltage souce visited
		var visitedECCs: Set<ECComponentView> = []
		visitedECCs.insert(eccVoltageSource)
		
		// Get the ECCs connected to the positive pole of voltage source
		let adjacentECCs = findECComponents(adjacentTo: eccVoltageSource, through: poleTable[eccVoltageSource]!.1, in: graph)
		
		// Set the poles of each node
		for ecc in adjacentECCs {
			addPoles(to: &poleTable, for: ecc, atPositivePole: poleTable[eccVoltageSource]!.1, visited: &visitedECCs, in: graph)
		}
		
		return poleTable
	}
	
	/// Add a pole, a pair of ECN, to the pole table
	///
	/// - Parameters:
	///   - ioPoleTable: the pole table to which the new poles is added
	///   - ecComponent: the ECC of which the poles is created
	///   - prevPositiveECN: the positive pole of adjacent ECC
	///   - ioVisitedECCs: the array of visited ECCs
	///   - graph: the graph which the pole table is created using
	private func addPoles(to ioPoleTable: inout ECCDictionary, for ecComponent: ECComponentView, atPositivePole prevPositiveECN: ECNodeView, visited ioVisitedECCs: inout Set<ECComponentView>, in graph: ECNDictionary) {
		var negativeECN: ECNodeView
		var positiveECN = prevPositiveECN
		let ecnManager = ECNodeManager.sharedInstance
		
		let ecns = findECNodes(connectedTo: ecComponent, option: .all, in: graph)
		
		if ecns.count < 2 {
//			print("Wrong graph!!")
			return
		}
		
		if ecComponent.numberOfNodes == 3 {		// in case that the count of nodes is 3
			// Get the indices of the ECC
			let eccIndex1 = ecComponent.id.getInt()!
			let eccIndex2 = eccIndex1 % 2 == 0 ? eccIndex1 - 1 : eccIndex1 + 1
			
			// Get the ECNs connected to the ECC
			negativeECN = ecns[0]
			positiveECN = ecns[1]
			
			// Change the pole of ECC
			if ecComponent.type == .dummyTube {
				for ecc in graph[positiveECN]! {
					if ecComponent.type == ecc.type && ecc.id.getInt()! == eccIndex2 {
						negativeECN = ecns[1]
						positiveECN = ecns[0]
						break
					}
				}
			} else if ecComponent.type == .dummyTransistor {
				for ecc in graph[negativeECN]! {
					if ecComponent.type == ecc.type && ecc.id.getInt()! == eccIndex2 {
						negativeECN = ecns[1]
						positiveECN = ecns[0]
						break
					}
				}
			}
			
		} else {
			negativeECN = ecns[0] == positiveECN ? ecns[1] : ecns[0]
			
			// The ECN for grounding is should be set negative pole.
			if positiveECN.id == ecnManager.groundingNodeId {
				let tempECN = positiveECN
				positiveECN = negativeECN
				negativeECN = tempECN
			}
		}
		
		// Add a pair of poles to the table
		ioPoleTable[ecComponent] = (negativeECN, positiveECN)
		
		// Set the passed ECC visited
		ioVisitedECCs.insert(ecComponent)
		
		// Get the adjacent ECCs
		let adjacentECCs = findECComponents(adjacentTo: ecComponent, through: negativeECN == prevPositiveECN ? positiveECN : negativeECN, in: graph)
		
		// Perform the function recursively
		for ecc in adjacentECCs {
			if !ioVisitedECCs.contains(ecc) {
				addPoles(to: &ioPoleTable, for: ecc, atPositivePole: negativeECN == prevPositiveECN ? positiveECN : negativeECN, visited: &ioVisitedECCs, in: graph)
			}
		}
	}
}
