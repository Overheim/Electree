//
//  AudioPlayer.h
//  Electree
//
//  Created by Won Jae Lee on 2018. 2. 23..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

#ifndef AudioPlayer_h
#define AudioPlayer_h

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

#import "WDFWrapper.h"

@interface AudioPlayer:NSObject

-(instancetype)init:(WDFWrapper *)wdfModule;
-(void)dealloc;

/**
 Load the audio file from the url, then create the output audio unit and start dsp

 @param url the url of audio file
 */
-(void)prepareWithAudioFile:(CFURLRef)url processLabel:(UILabel*)label andProcessIndicator:(UIActivityIndicatorView*)indicator;

/**
 Play the audio
 */
-(void)play;

/**
 Stop the audio
 */
-(void)stop;

/**
 Stop all processes: playing audio & WDF wave
 */
-(void)close;

/**
 Clear all buffers
 */
-(void)clear;

/**
 The volume of audio
 */
@property (getter=getVolume, setter=setVolume:) Float32 volume;

/**
 Play audio through the filter or not
 */
@property (getter=getFilterOption, setter=setFilterOption:) bool filterApplied;

/**
 The count of nonlinear element
 */
@property int nonlinearCount;

@end
#endif /* AudioPlayer_h */
