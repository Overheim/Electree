//
//  AudioFile.mm
//  Electree
//
//  Created by Won Jae Lee on 2018. 2. 23..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

#import "AudioPlayer.h"
#import "FilterOperation.h"
#import "LoadOperation.h"

//============================================================
// Rendering functions
//============================================================
/**
 Structure for rendering the audio file
 */
typedef struct _InputRenderStruct {
	vector<Float32> samples;
	vector<Float32> filtered_samples;
	unsigned long sampleIndex;
	AudioUnit outputUnit;
	Float32 volumeLevel;
	bool filterApplied;
} InputRenderStruct;

/**
 Rendering function for the audio samples
 */
OSStatus inputRenderProc(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
	InputRenderStruct *inputData = (InputRenderStruct *)inRefCon;
	
	// Siginal Processing...
	for(int frame = 0; frame < inNumberFrames; frame++) {
		Float32 *data = (Float32 *)ioData->mBuffers[0].mData;
		if(inputData->filterApplied)
			data[frame] = inputData->filtered_samples[inputData->sampleIndex] * inputData->volumeLevel;
		else
			data[frame] = inputData->samples[inputData->sampleIndex] * inputData->volumeLevel;
		
		inputData->sampleIndex++;
	}
	
	if(inputData->sampleIndex >= inputData->samples.size()) {
		inputData->sampleIndex = 0;
		AudioOutputUnitStop(inputData->outputUnit);
	}
	
	return noErr;
}

//============================================================
// AudioPlayer Implementation
//============================================================
/**
 Extension for the private variables
 */
@interface AudioPlayer() {
	InputRenderStruct inputData;
	__weak WDFWrapper *wdfModule;
	NSOperationQueue *operationQueue;
}

/**
 Create the Audio Unit for output
 */
-(void)createOutputUnit;

/**
 Print the description of audio file

 @param description ASBD of audio file
 */
-(void)print:(AudioStreamBasicDescription)description;

@end

@implementation AudioPlayer

@synthesize nonlinearCount;

#pragma mark Init functions

-(instancetype)init:(WDFWrapper*)wdfModule {
	if(self = [super init]) {
		inputData.sampleIndex = 0;
		self->wdfModule = wdfModule;
		
		operationQueue = NULL;
	}
	return self;
}

-(void)dealloc {
	[self close];
	
//	NSLog(@"audio player terminated");
}

#pragma mark Managing audio

-(void)prepareWithAudioFile:(CFURLRef)url processLabel:(UILabel*)label andProcessIndicator:(UIActivityIndicatorView*)indicator {
	@autoreleasepool {
		if(!operationQueue)
			operationQueue = [[NSOperationQueue alloc] init];
		
		LoadOperation* loadOp;
		loadOp = [[LoadOperation alloc] initWithURL:url];
		loadOp.label = label;
		loadOp.activityIndicator = indicator;
		loadOp.buffer = &inputData.samples;
		
		FilterOperation* filterOp;
		filterOp = [[FilterOperation alloc] initWithWDFModule:wdfModule];
		filterOp.nonlinearCount = nonlinearCount;
		filterOp.label = label;
		filterOp.activityIndicator = indicator;
		filterOp.samples = &inputData.samples;
		filterOp.filteredSamples = &inputData.filtered_samples;
		[filterOp addDependency:loadOp];
		
		[operationQueue addOperation:loadOp];
		[operationQueue addOperation:filterOp];
		
		[self createOutputUnit];
	}
}

-(void)play {
//	if(AudioOutputUnitStart(inputData.outputUnit) != noErr)
//		NSLog(@"Failed to play audio");
	AudioOutputUnitStart(inputData.outputUnit);
}

-(void)stop {
//	if(AudioOutputUnitStop(inputData.outputUnit) != noErr)
//		NSLog(@"Failed to stop the audio");
	AudioOutputUnitStop(inputData.outputUnit);
	inputData.sampleIndex = 0;
}

-(void)close {
	AudioOutputUnitStop(inputData.outputUnit);
	AudioUnitUninitialize(inputData.outputUnit);
	AudioComponentInstanceDispose(inputData.outputUnit);
	
	[operationQueue cancelAllOperations];
}

-(void)clear {
	[self close];
	
	[operationQueue waitUntilAllOperationsAreFinished];
	
	inputData.samples.clear();
	inputData.filtered_samples.clear();
	inputData.sampleIndex = 0;
}

-(Float32)getVolume {
	return inputData.volumeLevel;
}

-(void)setVolume:(Float32)value {
	inputData.volumeLevel = value;
}

-(bool)getFilterOption {
	return inputData.filterApplied;
}

-(void)setFilterOption:(bool)option {
	inputData.filterApplied = option;
}

-(void)createOutputUnit {
	// First, get the description of output(speaker)
	AudioComponentDescription outputDescription = { 0 };
	outputDescription.componentType = kAudioUnitType_Output;
	outputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
	outputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	
	// Get the output audio unit
	AudioComponent outputComponent = AudioComponentFindNext(NULL, &outputDescription);
	AudioComponentInstanceNew(outputComponent, &inputData.outputUnit);
	
	// Set the render callback function
	AURenderCallbackStruct inputRenderer;
	inputRenderer.inputProc = inputRenderProc;
	inputRenderer.inputProcRefCon = &inputData;
	AudioUnitSetProperty(inputData.outputUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &inputRenderer, sizeof(AURenderCallbackStruct));
	
	// Set the format to 32 bit, single channel, floating point, linear PCM
	const int four_bytes_per_float = 4;
	const int eight_bits_per_byte = 8;
	AudioStreamBasicDescription streamFormat;
	streamFormat.mSampleRate = 44100;
	streamFormat.mFormatID = kAudioFormatLinearPCM;
	streamFormat.mFormatFlags =	kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
	streamFormat.mBytesPerPacket = four_bytes_per_float;
	streamFormat.mFramesPerPacket = 1;
	streamFormat.mBytesPerFrame = four_bytes_per_float;
	streamFormat.mChannelsPerFrame = 1;
	streamFormat.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;
	if(AudioUnitSetProperty (inputData.outputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &streamFormat, sizeof(AudioStreamBasicDescription)) != noErr ) {
//		printf("failed to set property\n");
		exit(1);
	}
	
	// Initialize the output audio unit
	AudioUnitInitialize(inputData.outputUnit);
}

-(void)print:(AudioStreamBasicDescription)description {
//	printf("========== Audio Description ==========\n");
//	printf("bits per channel: %u\n", description.mBitsPerChannel);
//	printf("bytes per frame: %u\n", description.mBytesPerFrame);
//	printf("bytes per packet: %u\n", description.mBytesPerPacket);
//	printf("channels per frame: %u\n", description.mChannelsPerFrame);
//	printf("frames per packet: %u\n", description.mFramesPerPacket);
//	printf("sample rate: %.1f\n", description.mSampleRate);
}
@end
