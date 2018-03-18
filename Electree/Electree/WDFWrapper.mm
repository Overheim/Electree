//
//  WDFWrapper.mm
//  Electree
//
//  Created by Won Jae Lee on 2018. 1. 24..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

#import "WDFWrapper.h"
#import "Graph.hpp"

@interface WDFWrapper() {
	Graph* graph;
	SPQRTree* spqrTree;
	WDFTree* wdfTree;
	NSMutableDictionary* edgeDictionary;
	NSMutableArray* outputs;
	NSMutableArray* inputs;
	unsigned int inputIndex;
}

@end


@implementation WDFWrapper

-(instancetype)init {
	if (self = [super init]) {
		graph = NULL;
		spqrTree = NULL;
		wdfTree = NULL;
		edgeDictionary = [NSMutableDictionary dictionary];
		outputs = [[NSMutableArray alloc] init];
		inputs = [[NSMutableArray alloc] init];
		inputIndex = 0;
	}
	return self;
}

-(void)dealloc {
	delete graph;
	delete spqrTree;
	delete wdfTree;
	
	for(NSValue *value in [edgeDictionary allValues])
	{
		Edge* edge = (Edge*)[value pointerValue];
		delete edge;
	}
}

-(void)createGraph {
	if(!graph)
		graph = new Graph();
}

-(void)createTree {
	if(graph != NULL) {
//		NSLog(@"Initial graph:");
//		graph->Print();
		
		spqrTree = new SPQRTree();
		graph->MakeSPQRTree(spqrTree);
//		spqrTree->Print();
		
		spqrTree->ConvertToBinaryTree();
		spqrTree->RemoveDummyLeaves();
		spqrTree->Trim();
		spqrTree->SetRigidNodeAsRoot();
		spqrTree->SplitNonlinearElements();
		spqrTree->Trim();
		spqrTree->SetVertexPair();
		spqrTree->ChangeRootTypeRigid();
		spqrTree->AddNonlinearElementsToRoot();
		spqrTree->MergeChildrenInRoot();
		spqrTree->SetResistanceOfVoltageSource();
//		spqrTree->Print();
	}
}

-(void)setInputFrequency:(float)freq withVoltage:(float)volt {
	if(spqrTree != NULL) {
		spqrTree->SetInputFrequency(freq);
		spqrTree->SetInputVoltage(volt);
	}
}

-(void)createWDFTree:(float)T {
	if(spqrTree != NULL) {
		wdfTree = spqrTree->CreateWDFTree(T);
	}
}

-(void)processSineWave {
	if(wdfTree != NULL) {
		// Initialize input parameters
		const float T = wdfTree->GetSamplingTime();					// sampling period
		const float Fs = 1.0 / T;									// the sampling rate
		const float t = 1.0;										// total sampleing time
		const unsigned int N = (int)(Fs * t);						// the count of samples
		const float gain = wdfTree->GetInputVoltage();				// input gain
		const float F = wdfTree->GetInputFrequency();				// input frequency
		NSMutableArray* inputs = [[NSMutableArray alloc] init];
		
		// Create the sample source
		for (int i = 0; i < N; i++)
			[inputs addObject: [NSNumber numberWithFloat: gain * sin(2.0 * M_PI * F * T * i)]];
		
		// Processing the loop
		float n;
		int i = 0;
		float inVoltage, outVoltage;
		[outputs removeAllObjects];
		
		for(NSNumber *Vin in inputs)
		{
			n = (float)i * T;
			i++;
			
			// Get a input
			inVoltage = [Vin floatValue];
			
			// Process
			outVoltage = wdfTree->Process(inVoltage);
//			NSLog(@"%f", outVoltage);
			[outputs addObject: [NSNumber numberWithFloat: outVoltage]];
			
			if(!isfinite(outVoltage))
			{
				return;
			}
		}
	}
}

-(void)prepareWave {
	if(wdfTree != NULL) {
		// Initialize input parameters
		const float T = wdfTree->GetSamplingTime();					// sampling period
		const float Fs = 1.0 / T;									// the sampling rate
		const float t = 1.0;										// total sampleing time
		const unsigned int N = (int)(Fs * t);						// the count of samples
		const float gain = wdfTree->GetInputVoltage();				// input gain
		const float F = wdfTree->GetInputFrequency();				// input frequency
		[inputs removeAllObjects];
		
		// Create the sample source
		for (int i = 0; i < N; i++)
			[inputs addObject: [NSNumber numberWithFloat: gain * sin(2.0 * M_PI * F * T * i)]];
		
		// Clear the outputs
		[outputs removeAllObjects];
		
		inputIndex = 0;
		wdfTree->Clear();
	}
}

-(bool)getNextSample:(float*)value {
	if(inputIndex >= [inputs count]) {
		return false;
	} else {
		float inVoltage = [inputs[inputIndex++] floatValue];
		float outVoltage = wdfTree->Process(inVoltage);
		*value = outVoltage;
		[outputs addObject: [NSNumber numberWithFloat: outVoltage]];
		
		if(!isfinite(outVoltage))
			return false;
		
		return true;
	}
}

-(NSMutableArray *)getOutputSamples {
	return outputs;
}

-(void)createEdgeWithValues:(NSMutableArray *)values options:(NSMutableArray *)options andId:(NSString *)ID {
	Edge* edge = new Edge();
	
	// for logging
	NSString* valueString = @"";
	NSString* optionString = @"";
	
	for(int i=0; i<8; i++)
	{
		edge->values[i] = [values[i] floatValue];
		edge->options[i] = [options[i] boolValue];
		edge->id = [ID UTF8String];
		
		if(i>0) {
			valueString = [valueString stringByAppendingString:@","];
			optionString = [optionString stringByAppendingString:@","];
		}
		
		valueString = [valueString stringByAppendingString:[NSString stringWithFormat:@"%1.1f", edge->values[i]]];
		optionString = [optionString stringByAppendingString:[NSString stringWithFormat:@"%d", edge->options[i]]];
	}
	
//	NSLog(@"Created a new edge(%s): [%@], [%@]", edge->id.c_str(), valueString, optionString);
	
	// Add the new edge to the dictionary
	[edgeDictionary setValue:[NSValue valueWithPointer:edge] forKey:ID];
}

-(void)connectVertex:(NSString *)vertex1 and:(NSString *)vertex2 with:(NSString *)edgeID {
	Edge* edge = (Edge*)[[edgeDictionary valueForKey:edgeID] pointerValue];
	graph->AddEdge([vertex1 UTF8String], [vertex2 UTF8String], edge);
	
//	NSLog(@"Added a new edge: %s(%@, %@)", edge->id.c_str(), vertex1, vertex2);
}

-(Float32)process:(Float32)sample {
	if(wdfTree != NULL)
		return wdfTree->Process(sample);
	else
		return sample;
}

-(bool)prepareForAudio {
	if(wdfTree != NULL) {
		wdfTree->Clear();
		return true;
	} else {
		return false;
	}
}

@end
