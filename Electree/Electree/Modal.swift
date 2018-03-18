//
//  Modal.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 19..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

protocol Modal {
	func show(animated: Bool)
	func dismiss(animated: Bool)
	var backgroundView: UIView { get }
	var dialogView: UIView { get set }
}

extension Modal where Self: UIView {
	func show(animated: Bool) {
		backgroundView.alpha = 0
		dialogView.center = CGPoint(x: center.x, y: frame.height + dialogView.frame.height / 2.0)
		UIApplication.shared.delegate?.window??.rootViewController?.view.addSubview(self)
		
		if animated {
			UIView.animate(withDuration: 0.33, animations: {
				self.backgroundView.alpha = 0.66
			})
			UIView.animate(withDuration: 0.33, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 10.0, options: UIViewAnimationOptions(rawValue: 0), animations: {
				self.dialogView.center  = self.center
			}, completion: { (completed) in
				
			})
		} else {
			backgroundView.alpha = 0.66
			dialogView.center  = center
		}
	}
	
	func dismiss(animated: Bool) {
		if animated {
			UIView.animate(withDuration: 0.33, animations: {
				self.backgroundView.alpha = 0
			}, completion: { (completed) in
				
			})
			UIView.animate(withDuration: 0.33, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 10.0, options: UIViewAnimationOptions(rawValue: 0), animations: {
				self.dialogView.center = CGPoint(x: self.center.x, y: self.frame.height + self.dialogView.frame.height/2)
			}, completion: { (completed) in
				self.removeFromSuperview()
			})
		} else {
			removeFromSuperview()
		}
		
	}
}
