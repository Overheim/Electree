//
//  WaveGraphViewController.swift
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 23..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

import UIKit
import MediaPlayer

let defaultFrequency: Float = 44100

enum AudioState: Int16 {
	case disabled=0, initial, loading, loadedAndProcessing, readyToPlay, playing, paused
}

/// A class that shows the result graph of WDF waves and plays a music which is filtered
class WaveGraphViewController: UIViewController {
	@IBOutlet weak var progressPopupView: UIView!
	@IBOutlet weak var progressView: UIProgressView!
	@IBOutlet weak var progressLabel: UILabel!
	@IBOutlet weak var progressTitle: UILabel!
	
	@IBOutlet weak var closeButton: UIButton!
	
	var volumeSlider: UISlider!
	var filterButton: UIButton!
	var processLabel: UILabel!
	var activityIndicator: UIActivityIndicatorView!
	
	var openButton: MusicButton!
	var playButton: MusicButton!
	var stopButton: MusicButton!
	var volumeButton: UIButton!
	var isMutted: Bool = false {
		didSet {
			if isMutted {
				volumeButton.setImage(UIImage(named: "volume_mute.png"), for: .normal)
			} else {
				volumeButton.setImage(UIImage(named: "volume.png"), for: .normal)
			}
		}
	}
	var oldVolumeValue: Float = 0.0
	
	var audioState: AudioState = .initial {
		didSet {
			switch audioState {
			case .disabled:
				openButton.isEnabled = false
				playButton.isEnabled = false
				stopButton.isEnabled = false
				volumeButton.isEnabled = false
				volumeSlider.isEnabled = false
				filterButton.isEnabled = false
			case .initial:
				openButton.isEnabled = true
				playButton.isEnabled = false
				stopButton.isEnabled = false
				volumeButton.isEnabled = false
				volumeSlider.isEnabled = false
				filterButton.isEnabled = false
			case .loading:
				openButton.isEnabled = false
				playButton.isEnabled = false
				stopButton.isEnabled = false
				volumeButton.isEnabled = false
				volumeSlider.isEnabled = false
				filterButton.isEnabled = false
			case .loadedAndProcessing:
				openButton.isEnabled = true
				playButton.isEnabled = false
				stopButton.isEnabled = false
				volumeButton.isEnabled = true
				volumeSlider.isEnabled = true
				filterButton.isEnabled = true
			case .readyToPlay:
				openButton.isEnabled = true
				playButton.isEnabled = true
				stopButton.isEnabled = false
				volumeButton.isEnabled = true
				volumeSlider.isEnabled = true
				filterButton.isEnabled = true
			case .playing:
				openButton.isEnabled = true
				playButton.isEnabled = false
				stopButton.isEnabled = true
				volumeButton.isEnabled = true
				volumeSlider.isEnabled = true
				filterButton.isEnabled = true
			case .paused:
				openButton.isEnabled = true
				playButton.isEnabled = true
				stopButton.isEnabled = true
				volumeButton.isEnabled = true
				volumeSlider.isEnabled = true
				filterButton.isEnabled = true
			}
		}
	}
	
	//============================================================
	// Processing
	//============================================================
	/// A total number of progress
	var totalProgress: Int = 1
	
	/// An WDF instance
	var wdf: WDFWrapper!
	
	/// The AudioPlayer instance
	var audioPlayer: AudioPlayer!
	
	var initialized = false
	
	/// A progress value
	private var progress: Int = 0 {
		didSet {
			let fractionalProgress = Float(progress) / Float(totalProgress)
			
			progressView.setProgress(fractionalProgress, animated: progress != 0)
			progressLabel.text = String(Int(fractionalProgress * 100.0)) + "%"
			
			if fractionalProgress == 1.0 {
				progressTitle.text = "complete"
			}
		}
	}
	
	//============================================================
	// Graph
	//============================================================
	/// An array of total samples. The graph will show a part of samples
	var samples: [Float] = []
	
	/// Sampling period
	var T: Float = 1.0 / defaultFrequency
	
	/// A frequency of wave
	var frequency: Float = 1.0
	
	/// The name of schematic
	var schematicName: String = ""
	
	/// The time slice per graph
	private var timePeriod: Float!
	
	var graphView: WaveGraphView!
	
	var nonlinearCount: Int = 0
	
	private var error = false
	
	/// The index of graph being displayed in the screen
	private var graphIndex: Int! {
		didSet {
			// Set the range of graph
			graphView.xRange.0 = Float(graphIndex) * timePeriod
			graphView.xRange.1 = Float(graphIndex + 1) * timePeriod - T
			
			// Set the datum of graph
			graphView.datum.removeAll()
			for index in index(of: graphView.xRange.0)...index(of: graphView.xRange.1) {
				if index < samples.count {
					graphView.datum.append(samples[index])
				}
			}
			
			graphView.setNeedsDisplay()
			
		}
	}
	
	/// The maximum number of the index of graph
	private var maxGraphIndex = 0
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		progressView.setProgress(0, animated: false)
		wdf = WDFWrapper()
		audioPlayer = AudioPlayer(wdf)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Process the wave, then get the output
		if !initialized {
			initialized = true
			processSineWave()
		}
		
		if error {
			dismiss(animated: false) {
				ECPopUpView(title: "Error", message: "The input parameters are invalid", option: .ok) {
					
					}.show(animated: false)
			}
		}
	}
	
	@IBAction func close(_ sender: UIButton) {
		dismiss(animated: true, completion: nil)
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		if let touch = touches.first {
			if touch.view is GridView {
				let location = touch.location(in: graphView)
				if location.x >= 0 || location.y >= 0 || location.x <= graphView.frame.width || location.y <= graphView.frame.height {
					if location.x <= graphView.frame.width / 2.0 {
						if graphIndex > 0 {
							graphIndex = graphIndex - 1
						}
					} else {
						if graphIndex < maxGraphIndex {
							graphIndex = graphIndex + 1
						}
					}
				}
			}
		}
	}
	
	// MARK: - show the wave graph
	
	/// Process the WDF waves using sine wave as input for one second.
	private func processSineWave() -> () {
		let eccManager = ECComponentManager.sharedInstance
		let ecnManager = ECNodeManager.sharedInstance
		let ecGraph = ECGraph.sharedInstance
		
		// Backup all states
		eccManager.backup()
		ecnManager.backup()
		ecGraph.backup()
		
		// Create the schematics
		let schematics = ecGraph.makeSchematics()
//		print("\nschematics: \(schematics)")
		
		// Restore all states
		eccManager.restore()
		ecnManager.restore()
		ecGraph.restore()
		
		wdf.createGraph()
		
		var inputFrequency: Float = 1
		var inputVoltage: Float = 0
		
		// Create the edges
		for ecc in schematics.keys {
			var values = Array(repeating: Float(0), count: 8);
			var options = Array(repeating: false, count: 8);
			
			switch ecc.type {
			case .acvs:
				values[WDFIndex.portsCount] = Float(1)
				values[WDFIndex.frequency] = ecc.property.values["FREQUENCY"]!
				values[WDFIndex.voltage] = ecc.property.values["VOLTAGE"]!
				options[WDFIndex.input] = ecc.property.options["INPUT"]!
				
				if options[WDFIndex.input] {
					inputFrequency = values[WDFIndex.frequency]
					inputVoltage = values[WDFIndex.voltage]
				}
			case .dcvs:
				values[WDFIndex.portsCount] = Float(1)
				values[WDFIndex.voltage] = ecc.property.values["VOLTAGE"]!
			case .resistor:
				values[WDFIndex.portsCount] = Float(1)
				values[WDFIndex.resistance] = ecc.property.values["RESISTANCE"]!
				options[WDFIndex.output] = ecc.property.options["OUTPUT"]!
			case .capacitor:
				values[WDFIndex.portsCount] = Float(1)
				values[WDFIndex.capacitance] = ecc.property.values["CAPACITANCE"]!
				options[WDFIndex.output] = ecc.property.options["OUTPUT"]!
			case .inductor:
				values[WDFIndex.portsCount] = Float(1)
				values[WDFIndex.inductance] = ecc.property.values["INDUCTANCE"]!
				options[WDFIndex.output] = ecc.property.options["OUTPUT"]!
			case .diode:
				values[WDFIndex.portsCount] = Float(1)
				options[WDFIndex.nonlinear] = true
				nonlinearCount += 1
			case .tube, .dummyTube:
				values[WDFIndex.portsCount] = Float(1)
				values[WDFIndex.tubeModel] = Float(ecc.property.modelIndex)
				options[WDFIndex.nonlinear] = true
				nonlinearCount += 2
			case .transistor, .dummyTransistor:
				values[WDFIndex.portsCount] = Float(1)
				values[WDFIndex.transistorModel] = Float(ecc.property.modelIndex)
				options[WDFIndex.nonlinear] = true
				nonlinearCount += 2
			case .dummy:
				values[WDFIndex.portsCount] = Float(1)
				options[WDFIndex.dummy] = true
			default:
				break
			}
			
			// Create the edge for the graph
			wdf.createEdge(withValues: NSMutableArray(array:values), options: NSMutableArray(array:options), andId: ecc.id)
			
			// Connect the two vertices
			if let ecns = schematics[ecc] {
				wdf.connectVertex(ecns.1.id, and: ecns.0.id, with: ecc.id)
			}
		}
		
		// Check the frequency and the voltage
		if inputFrequency <= 1 || inputVoltage == 0 {
			error = true
			return
		}
		
		self.progressTitle.text = "creating the tree..."
		DispatchQueue.global().async {
			// Create the WDF tree
			self.wdf.createTree()
			self.wdf.setInputFrequency(inputFrequency, withVoltage: inputVoltage)
			self.wdf.createWDFTree(1.0 / defaultFrequency)
			
			DispatchQueue.main.async {
				self.progressTitle.text = "processing..."
				self.progressLabel.isHidden = false
			}
			
			// Prepare the wave
			self.wdf.prepareWave()
			
			// Get the next sample
			var value: Float = 0
			var processing = true
			var counter = 0
			while processing {
				processing = self.wdf.getNextSample(&value)
				
				if processing {
					counter += 1
					if counter % 441 == 0 {
						DispatchQueue.main.async {
							self.progress = counter
						}
					}
				}
			}
			
			DispatchQueue.main.async {
//				print("========================================")
//				print("Finished to processing sine wave")
//				print("========================================")
				
				// Get the output samples
				if let samples = self.wdf.getOutputSamples() as? [Float] {
					// Create the view for the result
					self.createGraphViews(samples: samples, frequency: inputFrequency, voltage: inputVoltage)
					self.createMusicPlayerViews()
					
					// For the protection
					if samples.max()! > 1.5 || samples.min()! < -1.5 {
						self.audioState = .disabled
					} else {
						self.audioState = .initial
					}
				}
			}
		}
	}
	
	/// Convert the time of sample to the index of sample
	///
	/// - Parameter time: the time of sample
	/// - Returns: converted index
	private func index(of time: Float) -> Int {
		return Int(time / T)
	}
	
	/// Convert the index of sample to the time at that sample
	///
	/// - Parameter index: the index of sample
	/// - Returns: converted time
	private func time(of index: Int) -> Float {
		return Float(index) * T
	}
	
	/// Create the subviews for the wave graph
	///
	/// - Parameters:
	///   - samples: total samples of the graph
	///   - frequency: the frequency value
	///   - voltage: the voltage value
	func createGraphViews(samples: [Float], frequency: Float, voltage: Float) {
		self.samples = samples
		self.frequency = frequency
		
		// Create the graph
		let waveGraphRect = CGRect(x: view.frame.origin.x + view.frame.width * 0.05, y: view.frame.origin.y + view.frame.height * 0.05, width: view.frame.width * 0.9, height: view.frame.height * 0.75)
		graphView = WaveGraphView(frame: waveGraphRect, title: schematicName + ", " + String(frequency) + "Hz" + ", " + String(voltage) + "V")
		
		// Set the initial range of datum for the graph
		let waveCount: Float = 4.0
		timePeriod = min(1.0, waveCount / frequency)
		graphIndex = 0
		maxGraphIndex = Int(1.0 / timePeriod)
		
		// Enable the touch event
		view.isUserInteractionEnabled = true
		closeButton.isHidden = false
		
		// Show the graph
		progressPopupView.isHidden = true
		view.addSubview(graphView)
	}
	
	// MARK: - play the music
	
	/// Creates the views for playing the music
	func createMusicPlayerViews() {
		let buttonSize: CGFloat = 64
		let margin: CGFloat = 16
		let space: CGFloat = margin * 2.0
		
		var startPoint = CGPoint(x: margin, y: view.frame.height - margin - buttonSize - 25)
		
		// Open button
		openButton = MusicButton(frame: CGRect(x: startPoint.x, y: startPoint.y, width: buttonSize, height: buttonSize), type: .open)
		openButton.addTarget(self, action: #selector(open), for: .touchUpInside)
		startPoint.x += buttonSize + space
		view.addSubview(openButton)
		
		// Play button
		playButton = MusicButton(frame: CGRect(x: startPoint.x, y: startPoint.y, width: buttonSize, height: buttonSize), type: .play)
		startPoint.x += buttonSize + space
		playButton.addTarget(self, action: #selector(play), for: .touchUpInside)
		view.addSubview(playButton)
		
		// Stop button
		stopButton = MusicButton(frame: CGRect(x: startPoint.x, y: startPoint.y, width: buttonSize, height: buttonSize), type: .stop)
		startPoint.x += buttonSize + space
		stopButton.addTarget(self, action: #selector(stop), for: .touchUpInside)
		view.addSubview(stopButton)
		
		// Volume Button
		volumeButton = UIButton(frame: CGRect(x: startPoint.x, y: startPoint.y, width: buttonSize, height: buttonSize))
		startPoint.x += buttonSize + margin
		volumeButton.addTarget(self, action: #selector(mute), for: .touchUpInside)
		volumeButton.setImage(UIImage(named: "volume.png"), for: .normal)
		view.addSubview(volumeButton)
		
		// Volume slider
		volumeSlider = UISlider(frame: CGRect(x: startPoint.x, y: startPoint.y + 20, width: 200, height: 30))
		volumeSlider.minimumValue = 0
		volumeSlider.maximumValue = 2
		volumeSlider.value = 1
		volumeSlider.addTarget(self, action: #selector(volumeChanged), for: .valueChanged)
		startPoint.x += volumeSlider.frame.width + space
		oldVolumeValue = volumeSlider.value
		view.addSubview(volumeSlider)
		
		filterButton = UIButton(type: .custom)
		filterButton.frame = CGRect(x: startPoint.x, y: startPoint.y, width: buttonSize, height: buttonSize)
		filterButton.isSelected = true
		filterButton.setImage(UIImage(named: "filter_on.png"), for: .selected)
		filterButton.setImage(UIImage(named: "filter_off.png"), for: .normal)
		filterButton.addTarget(self, action: #selector(filterOptionChanged), for: .touchUpInside)
		view.addSubview(filterButton)
		startPoint.x += buttonSize + space
		
		// Processing label
		processLabel = UILabel(frame: CGRect(x: startPoint.x, y: startPoint.y, width: 200, height: 50))
		processLabel.font = UIFont(name: fontLight, size: 17)
		processLabel.addObserver(self, forKeyPath: "text", options: [.old, .new], context: nil)
		startPoint.x += processLabel.frame.width
		view.addSubview(processLabel)
		
		// Activity indicator
		activityIndicator = UIActivityIndicatorView(frame: CGRect(x: startPoint.x, y: startPoint.y - 15, width: 100, height: 100))
		activityIndicator.activityIndicatorViewStyle = .whiteLarge
		activityIndicator.color = .black
		activityIndicator.hidesWhenStopped = true
		view.addSubview(activityIndicator)
	}
	
	@objc func open() {
		let mediaPicker = MPMediaPickerController(mediaTypes: .anyAudio)
		mediaPicker.delegate = self
		present(mediaPicker, animated: true, completion: nil)
	}
	
	@objc func play() {
		audioState = .playing
		audioPlayer.play()
	}
	
	@objc func stop() {
		audioState = .readyToPlay
		audioPlayer.stop()
	}
	
	@objc func mute() {
		isMutted = !isMutted
		
		if isMutted {
			oldVolumeValue = volumeSlider.value
			volumeSlider.value = 0
		} else {
			volumeSlider.value = oldVolumeValue
		}
		audioPlayer.volume = volumeSlider.value
		
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if keyPath == "text" {
			let string: String = change?[.newKey] as! String
			if string == "Loading audio file..." {
				audioState = .loading
			} else if string == "Processing..." {
				audioState = .loadedAndProcessing
			} else if string == "Can play (still processing...)" {
				audioState = .readyToPlay
			}
		}
	}
	
	@objc func volumeChanged() {
		if isMutted {
			isMutted = false
		}
		audioPlayer.volume = volumeSlider.value
	}
	
	@objc func filterOptionChanged() {
		filterButton.isSelected = !filterButton.isSelected
		audioPlayer.filterApplied = filterButton.isSelected
	}
}

// MARK: - extension for media picker

extension WaveGraphViewController: MPMediaPickerControllerDelegate {
	func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
		if let audioURL = mediaItemCollection.items.first?.assetURL{
			audioState = .loadedAndProcessing
			
			// Initialize the audio player
			audioPlayer.clear()
			
			audioPlayer.nonlinearCount = Int32(nonlinearCount)
			
			// Prepare the audio
			audioPlayer.prepare(withAudioFile: audioURL as CFURL, processLabel: processLabel, andProcessIndicator: activityIndicator)
			
			// Set the volume
			audioPlayer.volume = volumeSlider.value
			
			// Set the filter options
			audioPlayer.filterApplied = filterButton.isSelected
		}
		
		mediaPicker.dismiss(animated: true, completion: nil)
	}
	
	func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
		mediaPicker.dismiss(animated: true, completion: nil)
	}
}

private class WDFIndex {
	//==================================================
	// Values
	//==================================================
	// common
	static let portsCount = 0
	
	// voltage source
	static let frequency = 1
	static let voltage = 2
	
	// resistor
	static let resistance = 1
	
	// capacitor
	static let capacitance = 1
	
	// inductor
	static let inductance = 1
	
	// rigid adaptor
	static let numberOfNodes = 1
	
	// vacuum tube
	static let tubeModel = 1
	
	// BJT transistor
	static let transistorModel = 1;
	
	//==================================================
	// Options
	//==================================================
	static let dummy = 0
	static let input = 1
	static let output = 2
	static let nonlinear = 3
	static let pole = 4
}
