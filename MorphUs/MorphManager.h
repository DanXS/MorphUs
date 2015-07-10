//
//  MorphManager.h
//  Selfwe
//
//  Created by Dan Shepherd on 06/07/2014.
//  Copyright (c) 2014 cuffedtothekeyboard. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface MorphManager : NSObject

-(id)init;
-(int)getWeightCount;
-(Boolean)doMorph:(float)alpha forSrcWeights:(float*)srcWeights andDestWeights:(float*)destWeights InterpolatedMarkers:(float*)interpolatedMarkers;
-(void)setSourceMakers:(NSArray*)src andDestMarkers:(NSArray*)dest;

@end
