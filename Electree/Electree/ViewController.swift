//
//  ViewController.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 3..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	@IBOutlet weak var scrollView: ScrollView!
	@IBOutlet weak var drawingView: UIImageView!
	@IBOutlet weak var eraserView: CheckBox!
	@IBOutlet weak var titleView: UITextField!
	
	let ecFileManager = ECFileManager()
	
	/// A value that the save function will be executed after editing the title
	var saveAfterEdit = false
	
	/// The EC component button that the user touched last
	weak var lastChosenComponentButton: ComponentButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		scrollView.drawingView = drawingView
		eraserView.didCheck = { self.scrollView.mode = .erase }
		eraserView.didUncheck = { self.scrollView.mode = .draw }
		
		eraserView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(eraseAll)))
		
		// Get the EC component type chosen initially and set chosen last
		for subview in view.subviews {
			if let button = subview as? ComponentButton, button.chosen {
				lastChosenComponentButton = button
				scrollView.ecComponentType = ECComponentType(rawValue: lastChosenComponentButton.tag)
			}
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	/// Select the electronic component's type when the user touches the EC component button
	///
	/// - Parameter sender: The button chosen by the user
	@IBAction func chooseComponent(_ sender: ComponentButton) {
		if sender != lastChosenComponentButton {
			sender.chosen = true
			lastChosenComponentButton.chosen = false
			lastChosenComponentButton = sender
			
			scrollView.ecComponentType = ECComponentType(rawValue: sender.tag)
		}
	}
	
	/// Change the mode to the 'erase'
	///
	/// - Parameter sender: tap event
	@objc func erase(recognizer: UITapGestureRecognizer) {
		if scrollView.mode != .erase {
			scrollView.mode = .erase
		} else {
			scrollView.mode = .draw
		}
	}
	
	/// Create a new document
	///
	/// - Parameter sender: new button
	@IBAction func new(_ sender: UIButton) {
		if titleView.text != "" {
			// Save the current views
			save()
		}
		
		// Clear all Electric Circuit Elements
		scrollView.initialize()
		
		titleView.text = ""
		titleView.becomeFirstResponder()
	}
	
	/// Show the pop-up view for info
	///
	/// - Parameter sender: info button
	@IBAction func showInfo(_ sender: UIButton) {
		view.addSubview(InformationView(frame: view.frame))
	}
	
	/// Clear the screen
	///
	/// - Parameter recognizer: touch event
	@objc func eraseAll(recognizer: UILongPressGestureRecognizer) {
		if recognizer.state == .began {
			ECPopUpView(title: "WARNING", message: "Are you sure to delete ALL electric circuit elements?", option: .okAndCancel) {
				self.scrollView.initialize()
				}.show(animated: true)
		}
	}
	
	// MARK: - Manage the ECF
	
	/// Save an electric circuit datum to the file(ECF)
	private func save() {
		// Create ECF
		let file = ECFile()
		
		// Add the EC views to the file
		for subview in scrollView.subviews {
			if subview is ECComponentView || subview is ECNodeView {
				file.add(subview)
			}
		}
		
		let ecGraph = ECGraph.sharedInstance
		let nodeManager = ECNodeManager.sharedInstance
		
		// Add the graph
		for key in ecGraph.graph.keys {
			file.add((key.id, ecGraph.graph[key]!))
		}
		
		// Add the count of ECNs
		file.add(key: "nodeIndex", value: nodeManager.nodeIndex)
		
		// Save an ECF
		let filename = titleView.text == nil || titleView.text == "" ? "No Title" : titleView.text!.trimmingCharacters(in: .whitespacesAndNewlines)
		ecFileManager.save(file, to: filename, with: UIImage(view: scrollView))
	}
	
	/// Execute the 'save' function
	///
	/// - Parameter sender: touch event
	@IBAction func save(_ sender: UIButton) {
		if titleView.text == "" {
			titleView.becomeFirstResponder()
			saveAfterEdit = true
		} else {
			save()
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "FileList"?:
			let fileListViewController = segue.destination as! FileListViewController
			
			// Get the list of saved file
			let files = ecFileManager.getFileList()
			
			// Pass the datum
			fileListViewController.fileNames = Array(files.keys)
			fileListViewController.fileImages = Array(files.values)
			fileListViewController.loadFunction = {
				selectedFilename in
				// Clear all electric circuit components
				self.scrollView.initialize()
				
				// Load the file
				if let file = self.ecFileManager.load(selectedFilename) {
					// Draw on the screen
					for loadedView in file.views {
						if let node = loadedView as? ECNodeView {
							// Add to the nodes list
							ECNodeManager.sharedInstance.nodes.insert(node)
						} else if let component = loadedView as? ECComponentView {
							// Update the index of the ECC
							ECComponentManager.sharedInstance.ecComponentIndices[component.type] = max(ECComponentManager.sharedInstance.ecComponentIndices[component.type]!, Int(component.id.getInt()!) + 1)
							
							// Add to the ECC list
							if !component.isCable {
								ECComponentManager.sharedInstance.ecComponents.insert(component)
							}
						}
						self.scrollView.addSubview(loadedView)
					}
					
					// Set the graph
					for element in file.graph {
						if let node = ECNodeManager.sharedInstance.findECNode(with: element.key) {
							ECGraph.sharedInstance.graph[node] = element.value as? Set<ECComponentView>
						}
					}
					
					// Set the index of ECN
					if let nodeIndex = Int(file.data["nodeIndex"]!) {
						ECNodeManager.sharedInstance.nodeIndex = nodeIndex
					}
					
					// Set the title
					self.titleView.text = selectedFilename
				}
			}
			break
		case "WaveGraph"?:
			let waveGraphViewController = segue.destination as! WaveGraphViewController
			waveGraphViewController.totalProgress = Int(defaultFrequency)
			waveGraphViewController.schematicName = titleView.text == nil ? "" : titleView.text!
		default:
			break
		}
	}
}

// MARK: - extension to the delegation of UITextField
extension ViewController: UITextFieldDelegate {
	func textFieldDidBeginEditing(_ textField: UITextField) {
		textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		if saveAfterEdit {
			save()
			saveAfterEdit = false
		}
		return true
	}
}

// MARK: - extension to converting the string to integer
extension String {
	func getInt() -> Int? {
		return Int(components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
	}
}

extension UIImage {
	convenience init(view: UIView) {
		UIGraphicsBeginImageContext(view.frame.size)
		view.layer.render(in:UIGraphicsGetCurrentContext()!)
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		self.init(cgImage: image!.cgImage!)
	}
}

private class InformationView: UIView {
	override init(frame rect: CGRect) {
		super.init(frame: rect)
		
		createViews()
		backgroundColor = UIColor(white: 0.5, alpha: 0.5)
		addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func createViews() {
		var startPoint = CGPoint(x: 0, y: 0)
		let font = UIFont(name: fontBold, size: 22.0)
		
		// Views for the ECCs
		startPoint.x = 64.0 * 9.5
		startPoint.y = frame.height - 64.0
		var tip = UILabel(frame: CGRect(x: startPoint.x, y: startPoint.y, width: 100, height: 64.0))
		tip.font = font
		tip.text = ": Select a component to be drawn"
		tip.sizeToFit()
		addSubview(tip)
		
		// View for the erasor
		startPoint.x = 48.0 * 1.5
		startPoint.y = 15.0
		tip = UILabel(frame: CGRect(x: startPoint.x, y: startPoint.y, width: 100.0, height: 48.0))
		tip.font = font
		tip.text = ": Selet a mode - draw or erase"
		tip.sizeToFit()
		addSubview(tip)
		
		// View for the save button
		startPoint.y += 64.0
		tip = UILabel(frame: CGRect(x: startPoint.x, y: startPoint.y, width: 100.0, height: 48.0))
		tip.font = font
		tip.text = ": Save a circuit"
		tip.sizeToFit()
		addSubview(tip)
		
		// View for the open button
		startPoint.y += 64.0
		tip = UILabel(frame: CGRect(x: startPoint.x, y: startPoint.y, width: 100.0, height: 48.0))
		tip.font = font
		tip.text = ": Load a existing circuit"
		tip.sizeToFit()
		addSubview(tip)
		
		// View for the new button
		startPoint.y += 64.0
		tip = UILabel(frame: CGRect(x: startPoint.x, y: startPoint.y, width: 100.0, height: 48.0))
		tip.font = font
		tip.text = ": New circuit"
		tip.sizeToFit()
		addSubview(tip)
		
		// View for the wave button
		startPoint.x = frame.width - 500.0
		startPoint.y = 0.0
		tip = UILabel(frame: CGRect(x: startPoint.x, y: startPoint.y, width: 200.0, height: 48.0))
		tip.font = font
		tip.text = "Process a sine wave through this circuit :"
		tip.sizeToFit()
		addSubview(tip)
		
		// View for the drawing
		let drawingOrder = UITextView(frame: CGRect(x: 0.0, y: 0.0, width: 500.0, height: 300.0))
		drawingOrder.text = "How to draw:\n1. Select a component\n2. Draw a line along the grid line\n3. Set the parameters\n4. Add more components\n5. Let the node disconnected in case of grounding\n6. Process a sine wave"
		drawingOrder.backgroundColor = nil
		drawingOrder.isOpaque = false
		drawingOrder.isEditable = false
		drawingOrder.font = font
		drawingOrder.textAlignment = .center
		drawingOrder.center = self.center
		addSubview(drawingOrder)
	}
	
	@objc func close() {
		removeFromSuperview()
	}
}
