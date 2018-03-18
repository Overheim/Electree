//
//  ECCableManager.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 8..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

/// A class that manages ECCableView. It creates a view with new id and deletes existing views.
class ECCableManager {
	/// Uses singleton
	static let sharedInstance: ECCableManager = {
		let instance = ECCableManager()
		return instance
	}()
	
	/// The index of cable to be created
	private var ecCableIndex = 1
	
	/// The prefix string of cable's name
	private let ecCableNamePrefix = "CB"
	
	/// The array of existing cables
	private var ecCables: [ECCableView] = []
	
	/// The id of cable to be created next time
	///
	/// - Returns: The new id of the cable
	func getNewID() -> String {
		return ecCableNamePrefix + String(ecCableIndex)
	}
	
	/// Create a new id of the cable. It will not be used again
	///
	/// - Returns: The new id of the cable
	private func createNewID() -> String {
		let newID = getNewID()
		ecCableIndex += 1
		return newID
	}
	
	/// Create an instance of the ECCableView with new id
	///
	/// - Parameters:
	///   - gOrigin: origin by grid
	///   - gLength: length by grid
	///   - direction: direction
	///   - isExtension: extension option
	/// - Returns: new instance of the ECCableView
	func createCable(at gOrigin: GridPoint, for gLength: CGFloat, forward direction: ECComponentDirection, isExtension: Bool) -> ECCableView {
		let newCable = ECCableView(at: gOrigin, id: createNewID(), for: gLength, forward: direction, isExtension: isExtension)
		ecCables.append(newCable)
		
		return newCable
	}
}
