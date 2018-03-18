//
//  LoadOperation.h
//  Electree
//
//  Created by Won Jae Lee on 2018. 2. 27..
//  Copyright © 2018년 Anti Mouse. All rights reserved.
//

#ifndef LoadOperation_h
#define LoadOperation_h

#import <UIKit/UIKit.h>
#import "WDFWrapper.h"

#include <vector>

using namespace std;


/**
 A class that process loading the audio file to the buffer
 */
@interface LoadOperation:NSOperation

/**
 A label that shows the state of process.
 */
@property (nonatomic, weak) UILabel* label;

/**
 An indicator that shows whether the process is performing now.
 */
@property (nonatomic, weak) UIActivityIndicatorView* activityIndicator;

/**
 The raw samples of audio file
 */
@property vector<Float32>* buffer;

/**
 Create an instance with the url of audio file

 @param url url of audio file
 @return new instance
 */
-(id)initWithURL:(CFURLRef)url;

@end
#endif /* LoadOperation_h */
