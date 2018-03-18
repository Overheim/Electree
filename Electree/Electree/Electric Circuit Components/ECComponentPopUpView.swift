//
//  ECComponentPopUpView.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 6..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

let fontLight = "ChalkboardSE-Light"
let fontRegular = "ChalkboardSE-Regular"
let fontBold = "ChalkboardSE-Bold"

/// Displays a pop-up view that shows a detail info about an electric circuit component like name, resistance, etc, which can be edited.
///
/// This is a modal, so all other views' touch event is limited.
class ECComponentPopUpView: UIView, Modal {
	var backgroundView = UIView()
	var dialogView = UIView()
	
	/// Property view for the EC component
	private var labels: [UILabel] = [],
		userTexts: [UITextField] = [],
		userSwitches: [UISwitch] = [],
		userTitle: UITextField!,
		userPicker: UIPickerView!
	
	/// Name of the EC component
	private var name: String
	
	/// ECProperty value of the EC component
	private var property: ECComponentProperty
	
	/// Passed model list of EC component(vacuum tube only)
	private var models: [String]?
	
	/// Process this function after the OK button is touched
	private var completed: (String, ECComponentProperty)->()
	
	/// Create an instance
	///
	/// - Parameters:
	///   - name: Name of EC component
	///   - property: Property of EC component
	///   - models: The model list of EC component
	///   - completed: Process function for the OK action
	init(name: String, property: ECComponentProperty, models: [String]?, completed: @escaping (String, ECComponentProperty)->()) {
		self.name = name
		self.property = property
		self.completed = completed
		self.models = models
		
		super.init(frame: UIScreen.main.bounds)
		
		// Initialize the views
		initialize()
		
		// Add observers for the keyboard event
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	/// Process a function if the user touched a background of the pop-up
	@objc func didTappedOnBackgroundView() {
		cancel()
	}
	
	/// Process a function if the user touched the cancel button. All modified info about components will be ignored.
	@objc func cancel() {
		dismiss(animated: true)
	}
	
	/// Process a function if the user touched the OK button. All modified info about components will be saved.
	@objc func ok() {
		// name
		name = userTitle.text != nil ? userTitle.text! : name
		
		// values
		for index in 0..<userTexts.count {
			if let key = labels[index].text, let newValue = Float(userTexts[index].text!) {
				property.values[key] = newValue
			}
		}
		
		// options
		for index in 0..<userSwitches.count {
			if let key = labels[index + userTexts.count].text {
				property.options[key] = userSwitches[index].isOn
			}
		}
		
		// Process a complete function(model is already saved)
		completed(name, property)
		
		dismiss(animated: true)
	}
	
	/// Create all views and fill in the detail info.
	private func initialize() {
		dialogView.clipsToBounds = true
		
		// Set the size of the labels
		let basicViewHeight: CGFloat = 40.0		// All the height of views are same
		let basicLabelWidth: CGFloat = 120.0
		
		// Set the size of dialog view
		let dialogViewWidth = frame.width  / 2.5
		let dialogViewHeight = frame.height / 2.5
		
		// Create background view
		backgroundView.frame = frame
		backgroundView.backgroundColor = UIColor.black
		backgroundView.alpha = 0.6
		backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTappedOnBackgroundView)))
		addSubview(backgroundView)
		
		// Title
		userTitle = UITextField(frame: CGRect(x: 8.0, y: 8.0, width: dialogViewWidth - 16.0, height: 50.0))
		userTitle.text = name
		userTitle.textAlignment = .center
		userTitle.delegate = self
		userTitle.keyboardAppearance = .dark
		userTitle.returnKeyType = .done
		userTitle.font = UIFont(name: fontBold, size: 20)
		dialogView.addSubview(userTitle)
		
		// Separation bar
		let separatorLineView = UIView()
		separatorLineView.frame.origin = CGPoint(x: 0.0, y: userTitle.frame.height + 16.0)
		separatorLineView.frame.size = CGSize(width: dialogViewWidth, height: 1.0)
		separatorLineView.backgroundColor = UIColor.groupTableViewBackground
		dialogView.addSubview(separatorLineView)
		
		var lastY = separatorLineView.frame.maxY
		
		// Values
		for key in property.values.keys {
			// Create the label
			let label = UILabel(frame: CGRect(x: 16.0, y: lastY + 16.0, width: basicLabelWidth, height: basicViewHeight))
			label.text = key
			label.font = UIFont(name: fontLight, size: 16)
			labels.append(label)
			dialogView.addSubview(label)
			
			// Create the text field
			let textField = UITextField(frame: CGRect(x: label.frame.maxX + 16.0, y: label.frame.minY, width: dialogViewWidth - basicLabelWidth - 48.0, height: basicViewHeight))
			textField.text = String(property.values[key]!)
			textField.textAlignment = .right
			textField.delegate = self
			textField.keyboardAppearance = .dark
			textField.returnKeyType = .done
			textField.font = UIFont(name: fontBold, size: 17)
			
			userTexts.append(textField)
			dialogView.addSubview(textField)
			
			lastY += basicViewHeight
		}
		
		// Options
		for key in property.options.keys {
			// Create the label
			let label = UILabel(frame: CGRect(x: 16.0, y: lastY + 16.0, width: basicLabelWidth, height: basicViewHeight))
			label.text = key
			label.font = UIFont(name: fontLight, size: 16)
			labels.append(label)
			dialogView.addSubview(label)
			
			// Create the switch
			let switchView = UISwitch(frame: CGRect(x: label.frame.maxX + 16.0, y: label.frame.minY, width: dialogViewWidth - basicLabelWidth - 48.0, height: basicViewHeight))
			switchView.frame.origin.x = dialogViewWidth - 16.0 - switchView.frame.width
			switchView.isOn = property.options[key]!
			
			userSwitches.append(switchView)
			dialogView.addSubview(switchView)
			
			lastY += basicViewHeight
		}
		
		// Models
		if models != nil {
			userPicker = UIPickerView(frame: CGRect(x: 16.0, y: lastY + 8.0, width: dialogViewWidth - 32.0, height: dialogViewHeight - lastY - 16.0 - 50.0))
			userPicker.dataSource = self
			userPicker.delegate = self
			userPicker.showsSelectionIndicator = true
			userPicker.selectRow(property.modelIndex, inComponent: 0, animated: false)
			dialogView.addSubview(userPicker)
		}
		
		let buttonWidth: CGFloat = (dialogViewWidth - 16.0 * 3.0) / 2.0
		
		// Cancel button
		let cancelButton = UIButton(frame: CGRect(x: 16.0, y: dialogViewHeight - 16.0 - 50.0, width: buttonWidth, height: 50.0))
		cancelButton.setTitle("Cancel", for: .normal)
		cancelButton.setTitleColor(UIColor(hex: "ff3b30"), for: .normal)
		cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
		dialogView.addSubview(cancelButton)
		
		// OK button
		let okButton = UIButton(frame: CGRect(x: cancelButton.frame.maxX + 16.0, y: cancelButton.frame.minY, width: buttonWidth, height: 50.0))
		okButton.setTitle("Ok", for: .normal)
		okButton.setTitleColor(tintColor, for: .normal)
		okButton.addTarget(self, action: #selector(ok), for: .touchUpInside)
		dialogView.addSubview(okButton)
		
		// Set dialog frame
		dialogView.frame.size = CGSize(width: dialogViewWidth, height: dialogViewHeight)
		dialogView.backgroundColor = UIColor.gray
		dialogView.layer.cornerRadius = 6.0
		addSubview(dialogView)
	}
}

// MARK: - Extension for the keyboard event
extension ECComponentPopUpView: UITextFieldDelegate {
	@objc func keyboardWillShow(_ notification: Notification) {
		if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
			let keyboardRectangle = keyboardFrame.cgRectValue
			let keyboardHeight = keyboardRectangle.height
			
			UIView.animate(withDuration: 0.3, animations: {
				self.dialogView.center = CGPoint(x: self.center.x, y: (self.frame.height - keyboardHeight) / 2.0)
				
				if self.dialogView.center.y < 0.0 {
					self.dialogView.center.y = 0.0
				}
			})
		}
	}
	
	@objc func keyboardWillDisappear(_ notification: Notification) {
		UIView.animate(withDuration: 0.3, animations: {
			self.dialogView.center  = self.center;
		})
	}
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
}

// MARK: - Extension for the picker
extension ECComponentPopUpView: UIPickerViewDelegate, UIPickerViewDataSource {
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return models!.count
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		property.modelIndex = row
	}
	
	func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
		let label = (view as? UILabel) ?? UILabel()
		
		label.textAlignment = .center
		label.font = UIFont(name: fontLight, size: 16)
		
		// where data is an Array of String
		label.text = models![row]
		
		return label
	}
}

// MARK: - Extension to convert hex-string each other
extension UIColor {
	convenience init(hex: String) {
		let scanner = Scanner(string: hex)
		scanner.scanLocation = 0
		
		var rgbValue: UInt64 = 0
		
		scanner.scanHexInt64(&rgbValue)
		
		let r = (rgbValue & 0xff0000) >> 16
		let g = (rgbValue & 0xff00) >> 8
		let b = rgbValue & 0xff
		
		self.init(red: CGFloat(r) / 0xff, green: CGFloat(g) / 0xff, blue: CGFloat(b) / 0xff, alpha: 1)
	}
	
	var toHexString: String {
		var r: CGFloat = 0
		var g: CGFloat = 0
		var b: CGFloat = 0
		var a: CGFloat = 0
		
		self.getRed(&r, green: &g, blue: &b, alpha: &a)
		
		return String(format: "%02X%02X%02X", Int(r * 0xff), Int(g * 0xff), Int(b * 0xff))
	}
}
