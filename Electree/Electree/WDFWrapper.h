//
//  WDFWrapper.h
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 24..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

#ifndef WDFWrapper_h
#define WDFWrapper_h

#import <UIKit/UIKit.h>

@interface WDFWrapper: NSObject {
	
}

-(instancetype)init;

// MARK: - Create the WDF Graph and WDF Tree

/**
 Create the graph
 */
-(void)createGraph;

/**
 create the SPQR tree
 */
-(void)createTree;

/**
 Create the WDF tree
 
 @param T the sampling period
 */
-(void)createWDFTree: (float)T;

/**
 Create the edge of graph using the electric circuit components
 
 @param values the property values of ECC
 @param options the options of ECC
 @param ID the id of ECC
 */
-(void)createEdgeWithValues: (NSMutableArray *)values options: (NSMutableArray *)options andId: (NSString*)ID;

/**
 Connect the two vertices
 
 @param vertex1 a vertex to be connected
 @param vertex2 another vertex to be connected
 @param edgeID the id of edge used to connect the two vertices
 */
-(void)connectVertex:(NSString*)vertex1 and:(NSString*)vertex2 with:(NSString*)edgeID;

// MARK: - Sine Wave

/**
 Set the input properties

 @param freq the frequency of the source
 @param volt the voltage of the source
 */
-(void)setInputFrequency: (float)freq withVoltage: (float)volt;

/**
 Feed the sine samples to the WDF tree
 */
-(void)processSineWave;

/**
 Create the input samples and initialize the WDF tree
 */
-(void)prepareWave;

/**
 Get the current output value

 @param value the output value
 @return false if the processing is over, or true
 */
-(bool)getNextSample: (float*)value;

/**
 Get the filtered samples
 */
-(NSMutableArray *)getOutputSamples;

// MARK: - Real Audio DSP

/**
 Process the audio sample

 @param sample the input audio sample
 @return the output audio sample
 */
-(Float32)process: (Float32)sample;


/**
 Initialize the WDF tree for processing

 @return true if the WDF tree is valid, or false
 */
-(bool)prepareForAudio;

@end

#endif /* WDFWrapper_h */
