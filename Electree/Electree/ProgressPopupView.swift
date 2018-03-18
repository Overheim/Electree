//
//  ProgressPopupView.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 2. 18..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

class ProgressPopupView: UIView, Modal {
	var backgroundView = UIView()
	var dialogView = UIView()
	
	var progressView: UIProgressView!
	
	var totalProgress: Float = 1
	
	var progress: Int = 0 {
		didSet {
			let fractionalProgress = Float(progress) / totalProgress
			progressView.setProgress(fractionalProgress, animated: progress != 0)
		}
	}
	
	init(title: String, totalProgress: Float) {
		self.totalProgress = totalProgress
		super.init(frame: UIScreen.main.bounds)
		
		initialize(title: title)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func initialize(title: String) {
		dialogView.clipsToBounds = true
		
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
		let userTitle = UILabel(frame: CGRect(x: 8.0, y: 8.0, width: dialogViewWidth - 16.0, height: 50.0))
		userTitle.text = title
		userTitle.font = UIFont(name: "ChalkboardSE-Bold", size: 20)
		userTitle.textAlignment = .center
		dialogView.addSubview(userTitle)
		
		// Separation bar
		let separatorLineView = UIView()
		separatorLineView.frame.origin = CGPoint(x: 0.0, y: userTitle.frame.height + 16.0)
		separatorLineView.frame.size = CGSize(width: dialogViewWidth, height: 1.0)
		separatorLineView.backgroundColor = UIColor.groupTableViewBackground
		dialogView.addSubview(separatorLineView)
		
		// Progress bar
		progressView = UIProgressView(frame: CGRect(x: 16.0, y: dialogViewHeight / 2.0 + userTitle.frame.height, width: dialogViewWidth - 32.0, height: 10.0));
		progressView.progressViewStyle = .bar
		progressView.setProgress(0, animated: false);
		progressView.trackTintColor = UIColor.lightGray
		progressView.tintColor = UIColor.blue
		dialogView.addSubview(progressView);
		
		// Set dialog frame
		dialogView.frame.size = CGSize(width: dialogViewWidth, height: dialogViewHeight)
		dialogView.backgroundColor = UIColor.gray
		dialogView.layer.cornerRadius = 6.0
		addSubview(dialogView)
	}
	
	func process() {
		for _ in 1...Int(totalProgress) {
			DispatchQueue.global().async {
				sleep(1)
				DispatchQueue.main.async {
					self.progress += 1
					return
				}
			}
		}
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
		dismiss(animated: true)
	}
}
