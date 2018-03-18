//
//  ECFileManager.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 21..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit

/// A class that manages the electric circuit file, by saving or loading the datum
class ECFileManager {
	let stringECF: String = ".ecf"
	let stringSCREEN: String = ".screen"
	
	/// Save an EC file
	///
	/// - Parameters:
	///   - file: an ECF instance
	///   - filename: the name of ECF to be saved
	func save(_ file: ECFile, to filename: String, with fileImage: UIImage?) {
		let filepath = makeFilePath(with: filename) + stringECF
		NSKeyedArchiver.archiveRootObject(file, toFile: filepath)
		
		if let image = fileImage {
			NSKeyedArchiver.archiveRootObject(image, toFile: filepath + stringSCREEN)
		}
	}
	
	/// Load an EC file
	///
	/// - Parameter filename: the name of ECF to be loaded
	/// - Returns: loaded ECF instance
	func load(_ filename: String) -> ECFile? {
		let filepath = makeFilePath(with: filename) + stringECF
		if let file = NSKeyedUnarchiver.unarchiveObject(withFile: filepath) as? ECFile {
			return file
		}
		
		return nil
	}
	
	/// Delete an EC file
	///
	/// - Parameter filename: the filename to be removed
	func delete(_ filename: String) {
		let filepath = makeFilePath(with: filename) + stringECF
		do {
			try FileManager.default.removeItem(atPath: filepath)
		} catch {
			print(error.localizedDescription)
		}
	}
	
	/// Get the list of ECFs that is saved in the device
	///
	/// - Returns: the dictionary of ECFs and the image of the file
	func getFileList() -> [String : UIImage?] {
		let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		
		do {
			// Get the directory contents urls (including subfolders urls)
			let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: [])
			
			// Filter the directory contents
			let files = directoryContents.filter{ $0.pathExtension == "ecf" }
			let images = directoryContents.filter{ $0.pathExtension == "screen" }
			
			// Get the list of filenames
			let fileNames = files.map{ $0.deletingPathExtension().lastPathComponent }
			let imageNames = images.map{ $0.deletingPathExtension().lastPathComponent }
			
			var result: [String : UIImage?] = [:]
			for filename in fileNames {
				if let index = imageNames.index(of: filename + stringECF) {
					let filepath = makeFilePath(with: imageNames[index]) + stringSCREEN
					result[filename] = NSKeyedUnarchiver.unarchiveObject(withFile: filepath) as? UIImage
				} else {
					result[filename] = UIImage()
				}
			}
			
			return result
		} catch {
			print(error.localizedDescription)
		}
		
		return [:]
	}
	
	/// Makes the filepath
	///
	/// - Parameter filename: the name of file stored in the doc folder
	/// - Returns: filepath
	private func makeFilePath(with filename: String) -> String {
		let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
		return url.appendingPathComponent(filename)!.path
	}
}
