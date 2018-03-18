//
//  FilterOperation.h
//  Electree
//
//  Created by Won Jae Lee on 2018. 2. 27..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

#ifndef FilterOperation_h
#define FilterOperation_h

#import <UIKit/UIKit.h>
#import "WDFWrapper.h"

#include <vector>

using namespace std;


/**
 A class that process filtration of audio samples
 */
@interface FilterOperation:NSOperation

/**
 A label that shows the state of process.
 */
@property (nonatomic, weak) UILabel* label;

/**
 An indicator that shows whether the process is performing now.
 */
@property (nonatomic, weak) UIActivityIndicatorView* activityIndicator;

/**
 The number of nonlinear element in the schematic.
 */
@property int nonlinearCount;

/**
 The raw samples of audio file
 */
@property vector<Float32>* samples;

/**
 The samples of audio file filtered by WDF module
 */
@property vector<Float32>* filteredSamples;

/**
 Create the instance with WDF module

 @param wdf WDF module
 @return created instance
 */
-(id)initWithWDFModule:(WDFWrapper*)wdf;

@end

#endif /* FilterOperation_h */
