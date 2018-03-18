//
//  FilterOperation.mm
//  Electree
//
//  Created by Won Jae Lee on 2018. 2. 27..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

#import "FilterOperation.h"

@interface FilterOperation() {
	WDFWrapper *wdfModule;
}
@end


@implementation FilterOperation

@synthesize label, activityIndicator, nonlinearCount;
@synthesize samples, filteredSamples;

-(id)initWithWDFModule:(WDFWrapper *)wdf {
	if(self = [super init]) {
		wdfModule = wdf;
	}
	return self;
}

-(void)main {
	if(self.isCancelled) {
//		printf("Filter Operation is cancelled\n");
		return;
	}
	
	if(samples == NULL || filteredSamples == NULL || wdfModule == NULL)
		return;
	
	// Prepare for wave
	if(![wdfModule prepareForAudio])
		return;
	
	// Calculate the process time ratio
	float processTimeRatio = 1 + 0.6 * nonlinearCount;
	unsigned long samplesSize = samples->size();
	unsigned long playStartIndex = samplesSize - samplesSize / processTimeRatio;
	
	// Update the UIViews
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		[label setText:@"Processing..."];
		[activityIndicator startAnimating];
	}];
	
//	printf("starting to apply filter...\n");
//	NSDate *methodStart = [NSDate date];
	
	bool changeText = true;
	for(unsigned long i=0; i<samplesSize; i++) {
		if(self.isCancelled) {
//			printf("Filter Operation is cancelled\n");
			return;
		}
		
		// Process the WDF wave
		filteredSamples->push_back([wdfModule process:(*samples)[i]]);
		
		// Update the UIViews
		if(changeText && i > playStartIndex) {
			changeText = false;
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				[label setText:@"Can play (still processing...)"];
			}];
		}
	}
	
//	NSDate *methodFinish = [NSDate date];
//	NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
//	printf("finished to apply filter: %.3fs\n", executionTime);
	
	// Update the UIViews
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		[label setText:@"Process Complete"];
		[activityIndicator stopAnimating];
	}];
}
@end
