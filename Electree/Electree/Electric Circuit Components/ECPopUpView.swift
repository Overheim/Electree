//
//  ECPopUpView.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 19..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

/// A structure that set the number of buttons in pop-up view
///
/// - ok: Add the OK button
/// - okAndCancel: Add the OK and Cancel button
enum ECPopUpOption {
	case ok, okAndCancel
}

/// A class that creates a pop-up view that includes a title, message and buttons. Also, a complete action can be set when initializing
class ECPopUpView: UIView, Modal {
	var backgroundView = UIView()
	var dialogView = UIView()
	
	/// An action function which is performed after the view is created
	var completed: ()->()
	
	init(title: String, message: String, option: ECPopUpOption, completed: @escaping ()->()) {
		self.completed = completed
		
		super.init(frame: UIScreen.main.bounds)
		
		initialize(title: title, message: message, option: option)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	/// Creates the subviews which compose the pop-up view
	///
	/// - Parameters:
	///   - title: title text
	///   - message: detailed text
	private func initialize(title: String, message: String, option: ECPopUpOption) {
		dialogView.clipsToBounds = true
		
		// Set the size of dialog view
		let dialogViewWidth = frame.width  / 2.5
		let dialogViewHeight = frame.height / 2.5
		
		// Set the size of subviews
		let titleMargin: CGFloat = 8.0
		let titleHeight: CGFloat = 50.0
		
		// Create background view
		backgroundView.frame = frame
		backgroundView.backgroundColor = UIColor.black
		backgroundView.alpha = 0.6
		backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTappedOnBackgroundView)))
		addSubview(backgroundView)
		
		// Title
		let userTitle = UILabel(frame: CGRect(x: titleMargin, y: titleMargin, width: dialogViewWidth - titleMargin * 2.0, height: titleHeight))
		userTitle.text = title
		userTitle.font = UIFont(name: fontBold, size: 20)
		userTitle.textAlignment = .center
		dialogView.addSubview(userTitle)
		
		// Separation bar
		let separatorLineView = UIView()
		separatorLineView.frame.origin = CGPoint(x: 0.0, y: titleHeight + titleMargin * 2.0)
		separatorLineView.frame.size = CGSize(width: dialogViewWidth, height: 1.0)
		separatorLineView.backgroundColor = UIColor.groupTableViewBackground
		dialogView.addSubview(separatorLineView)
		
		let buttonMargin: CGFloat = 16.0
		let buttonWidth: CGFloat = (dialogViewWidth - buttonMargin * 3.0) / 2.0
		let buttonHeight: CGFloat = 50.0
		
		switch option {
		case .ok:
			// OK button
			let okButton = UIButton(frame: CGRect(x: buttonMargin, y: dialogViewHeight - buttonMargin - buttonHeight, width: dialogViewWidth - buttonMargin * 2.0, height: buttonHeight))
			okButton.setTitle("Ok", for: .normal)
			okButton.setTitleColor(tintColor, for: .normal)
			okButton.addTarget(self, action: #selector(ok), for: .touchUpInside)
			dialogView.addSubview(okButton)
		case .okAndCancel:
			// Cancel button
			let cancelButton = UIButton(frame: CGRect(x: buttonMargin, y: dialogViewHeight - buttonMargin - buttonHeight, width: buttonWidth, height: buttonHeight))
			cancelButton.setTitle("Cancel", for: .normal)
			cancelButton.setTitleColor(UIColor(hex: "ff3b30"), for: .normal)
			cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
			dialogView.addSubview(cancelButton)
			
			// OK button
			let okButton = UIButton(frame: CGRect(x: cancelButton.frame.maxX + buttonMargin, y: cancelButton.frame.minY, width: buttonWidth, height: buttonHeight))
			okButton.setTitle("Ok", for: .normal)
			okButton.setTitleColor(tintColor, for: .normal)
			okButton.addTarget(self, action: #selector(ok), for: .touchUpInside)
			dialogView.addSubview(okButton)
		}
		
		// Message
		let userMessage = UITextView(frame: CGRect(x: 16.0, y: separatorLineView.frame.maxY + 16.0, width: dialogViewWidth - 32.0, height: dialogViewHeight - buttonHeight - userTitle.frame.height - 48.0))
		userMessage.backgroundColor = nil
		userMessage.isOpaque = false
		userMessage.isEditable = false
		userMessage.font = UIFont(name: fontRegular, size: 17)
		userMessage.text = message
		userMessage.textAlignment = .center
		
		dialogView.addSubview(userMessage)
		
		// Set dialog frame
		dialogView.frame.size = CGSize(width: dialogViewWidth, height: dialogViewHeight)
		dialogView.backgroundColor = UIColor.gray
		dialogView.layer.cornerRadius = 6.0
		addSubview(dialogView)
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
		// Process a complete function(model is already saved)
		completed()
		
		dismiss(animated: true)
	}
}
