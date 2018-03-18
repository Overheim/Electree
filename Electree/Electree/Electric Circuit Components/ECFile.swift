//
//  ECFile.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 21..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

/// A class that stores the datum of electric circuit
class ECFile: NSObject, NSCoding {
	var views = [UIView]()
	var graph = [String : Set<UIView>]()
	var data = [String : String]()
	
	override init() {
		
	}
	
	required init?(coder aDecoder: NSCoder) {
		views = aDecoder.decodeObject(forKey: "views") as! [UIView]
		graph = aDecoder.decodeObject(forKey: "graph") as! [String : Set<UIView>]
		data = aDecoder.decodeObject(forKey: "data") as! [String : String]
	}
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(views, forKey: "views")
		aCoder.encode(graph, forKey: "graph")
		aCoder.encode(data, forKey: "data")
	}
	
	/// Add an electirc circuit view to the array
	///
	/// - Parameter view: a EC view to be added
	func add(_ view: UIView) {
		views.append(view)
	}
	
	/// Add EC views to the array
	///
	/// - Parameter views: EC views to be added
	func add(_ views: [UIView]) {
		self.views.append(contentsOf: views)
	}
	
	/// Set the EC views' array
	///
	/// - Parameter views: EC views to be set
	func set(_ views: [UIView]) {
		self.views.removeAll()
		self.views = views
	}
	
	/// Add a pair of ECN and the set of ECCs
	///
	/// - Parameter pair: a pair to be added
	func add(_ pair: (String, Set<UIView>)) {
		graph[pair.0] = pair.1
	}
	
	/// Add an array of pairs of ECN and ECCs
	///
	/// - Parameter pairs: an array of pairs of ECN and ECCs to be added
	func set(_ pairs: [String : Set<UIView>]) {
		graph.removeAll()
		graph = pairs
	}
	
	/// Add an index of ECN
	///
	/// - Parameters:
	///   - key: node index
	///   - value: the index of ECN
	func add(key: String,  value: Int) {
		data[key] = String(value)
	}
}
