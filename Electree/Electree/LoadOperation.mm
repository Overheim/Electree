//
//  LoadOperation.mm
//  Electree
//
//  Created by Won Jae Lee on 2018. 2. 27..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

#import "LoadOperation.h"
#import <AudioToolbox/AudioToolbox.h>

@interface LoadOperation() {
	CFURLRef audioURL;
}

@end


@implementation LoadOperation

@synthesize label, activityIndicator, buffer;

-(id)initWithURL:(CFURLRef)url {
	if(self = [super init]) {
		audioURL = url;
	}
	return self;
}

-(void)main {
	if(self.isCancelled) {
//		printf("Load Operation is cancelled\n");
		return;
	}
	
	if(buffer == NULL || audioURL == NULL)
		return;
	
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		[label setText:@"Loading audio file..."];
		[activityIndicator startAnimating];
	}];
	
	// Obtain a reference to the audio file
	ExtAudioFileRef fileRef;
	if(ExtAudioFileOpenURL(audioURL, &fileRef) != noErr) {
//		NSLog(@"Failed to open the file: %@", audioURL);
		return;
	}
	
	// Set up audio format we want the data in each sample is of type Float32
	AudioStreamBasicDescription audioFormat;
	audioFormat.mSampleRate = 44100;
	audioFormat.mFormatID = kAudioFormatLinearPCM;
	audioFormat.mFormatFlags = kLinearPCMFormatFlagIsFloat;
	audioFormat.mBitsPerChannel = sizeof(Float32) * 8;
	audioFormat.mChannelsPerFrame = 1; // Mono
	audioFormat.mBytesPerFrame = audioFormat.mChannelsPerFrame * sizeof(Float32);
	audioFormat.mFramesPerPacket = 1;
	audioFormat.mBytesPerPacket = audioFormat.mFramesPerPacket * audioFormat.mBytesPerFrame;
	
	// Apply audio format to the Extended Audio File
	if(ExtAudioFileSetProperty(fileRef, kExtAudioFileProperty_ClientDataFormat, sizeof (AudioStreamBasicDescription), &audioFormat) != noErr) {
//		NSLog(@"Failed to set data format");
		return;
	}
	
	// Allocate some space in memory
	int numSamples = 1024;		// How many samples to read in at a time
	UInt32 sizePerPacket = audioFormat.mBytesPerPacket;
	UInt32 packetsPerBuffer = numSamples;
	UInt32 outputBufferSize = packetsPerBuffer * sizePerPacket;
	
	if(self.isCancelled) {
//		printf("Load Operation is cancelled\n");
		return;
	}
	
	// So the lvalue of outputBuffer is the memory location where we have reserved space
	UInt8 *outputBuffer = (UInt8 *)malloc(sizeof(UInt8 *) * outputBufferSize);
	
	AudioBufferList convertedData;
	convertedData.mNumberBuffers = 1;		// Set this to 1 for mono
	convertedData.mBuffers[0].mNumberChannels = audioFormat.mChannelsPerFrame;
	convertedData.mBuffers[0].mDataByteSize = outputBufferSize;
	convertedData.mBuffers[0].mData = outputBuffer;
	
	UInt32 frameCount = numSamples;
	Float32 maxValue=0, minValue=0;
	
//	NSDate *methodStart = [NSDate date];
	while(frameCount > 0) {
		if(self.isCancelled) {
			ExtAudioFileDispose(fileRef);
			free(outputBuffer);
			
//			printf("Load Operation is cancelled\n");
			return;
		}
		
		ExtAudioFileRead(fileRef, &frameCount, &convertedData);
		
		if(frameCount > 0)  {
			AudioBuffer audioBuffer = convertedData.mBuffers[0];
			
			// Cast from the audio buffer to a C style array
			float *samplesAsCArray = (float *)audioBuffer.mData;
			
			// And then to a temporary C++ vector;
			std::vector<Float32> samplesAsVector;
			samplesAsVector.assign(samplesAsCArray, samplesAsCArray + frameCount);
			
			// And then into our final samples vector
			buffer->insert(buffer->end(), samplesAsVector.begin(), samplesAsVector.end());
			
			for (int i=0; i < frameCount; i++) {
				if(samplesAsCArray[i] > maxValue)		maxValue = samplesAsCArray[i];
				if(samplesAsCArray[i] < minValue)		minValue = samplesAsCArray[i];
			}
		}
	}
//	NSDate *methodFinish = [NSDate date];
//	NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
	
//	printf("saving to the buffer has finished: %.3fs\n", executionTime);
//	printf("total size: %lu\n", buffer->size());
//	printf("max value: %f\n", maxValue);
//	printf("min value: %f\n", minValue);
	
	// Close the audio file & release the memory
	ExtAudioFileDispose(fileRef);
	free(outputBuffer);
}
@end
