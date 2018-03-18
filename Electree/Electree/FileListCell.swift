//
//  FileListCell.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 21..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

/// A class that added in the collection view for the ECF
class FileListCell: UICollectionViewCell {
	/// The filename
	@IBOutlet weak var fileName: UILabel!
	
	/// This image will be showen when the user taps the cell
	@IBOutlet weak var checkImage: UIImageView!
	
	/// the image of the file
	@IBOutlet weak var fileImage: UIImageView!
}
