//
//  FileListViewController.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 21..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

enum SelectFileMode {
	case load, erase
}

class FileListViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	@IBOutlet weak var changeMode: CheckBox!
	@IBOutlet weak var collectionView: UICollectionView!
	
	private let reuseIdentifier = "FileCell"
	private var mode: SelectFileMode = .load
	
	/// A cell for displaying the ECF
	var fileImages = [UIImage?](), fileNames = [String]()
	
	/// The number of items per row
	private let itemsPerRow: CGFloat = 3
	
	/// A complete function to be performed in case the the mode is load
	var loadFunction: ((String)->())?
	
	/// A complete function to be performed in case the the mode is erase
	var eraseFunction: (([String])->())?
	
	/// A list of items to be selected
	private var selectedItems: [IndexPath : String] = [:]
	
	override func viewDidLoad() {
		changeMode.didChangeValue = {
			isChecked in
			if isChecked {
				self.mode = .erase
			} else {
				let fileManager = ECFileManager()
				
				// Delete the files
				for filename in self.selectedItems.values {
					fileManager.delete(filename)
				}
				
				// Delete from the data source
				for filename in self.selectedItems.values {
					if let index = self.fileNames.index(of: filename) {
						self.fileNames.remove(at: index)
						self.fileImages.remove(at: index)
					}
				}
				
				// Delete from the collection view
				self.collectionView.deleteItems(at: Array(self.selectedItems.keys))
				
				// Clear the list of selected items
				self.selectedItems.removeAll()
				
				// Set the mode default
				self.mode = .load
			}
		}
	}
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return fileNames.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FileListCell
		
		// Configure the cell
		cell.fileName.text = fileNames[indexPath.row]
		cell.fileImage.image = fileImages[indexPath.row]
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		switch mode {
		case .load:
			// Load the selected ECF
			if let load = loadFunction {
				load(fileNames[indexPath.row])
			}
			dismiss(animated: true, completion: nil)
		case .erase:
			// Store the selected ECFs
			if let selectedCell = collectionView.cellForItem(at: indexPath) as? FileListCell {
				if selectedCell.checkImage.isHidden {
					selectedCell.checkImage.isHidden = false
					selectedItems[indexPath] = fileNames[indexPath.row]
				} else {
					selectedCell.checkImage.isHidden = true
					selectedItems[indexPath] = nil
				}
			}
		}
	}
	
	@IBAction func close(_ sender: UIButton) {
		dismiss(animated: true, completion: nil)
	}
}

