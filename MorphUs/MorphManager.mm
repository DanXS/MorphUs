//
//  MorphManager.m
//  MorphUs
//
//  Created by Dan Shepherd on 06/07/2014.
//  Copyright (c) 2014 cuffedtothekeyboard. All rights reserved.
//

#include "Morph.h"
#import "MorphManager.h"

@interface MorphManager()
{
    Morph* morph;
}
@end

@implementation MorphManager

-(id)init
{
    if(self = [super init]) {
        morph = new Morph();
    }
    return self;
}

-(void)setSourceMakers:(NSArray*)src andDestMarkers:(NSArray*)dest
{
    @synchronized (self)
    {
        morph->ClearMarkers();
        for(ptrdiff_t i = 0; i < src.count; i++) {
            NSDictionary* marker = [src objectAtIndex:i];
            float x = [[marker valueForKey:@"x"] doubleValue];
            float y = [[marker valueForKey:@"y"] doubleValue];
            morph->AddSrcMarker(x, y);
        }
        for(ptrdiff_t i = 0; i < dest.count; i++){
            NSDictionary* marker = [dest objectAtIndex:i];
            float x = [[marker valueForKey:@"x"] doubleValue];
            float y = [[marker valueForKey:@"y"] doubleValue];
            morph->AddDestMarker(x, y);
        }
    }
}

-(int)getWeightCount
{
    @synchronized (self)
    {
        return (int)morph->GetWeightCount();
    }
}

-(Boolean)doMorph:(float)alpha forSrcWeights:(float*)srcWeights andDestWeights:(float*)destWeights InterpolatedMarkers:(float*)interpolatedMarkers
{
    @synchronized (self)
    {
        if(morph->Interpolate(alpha))
        {
            morph->BuildMatrices();
            morph->GetSrcWeights(srcWeights);
            morph->GetDestWeights(destWeights);
            morph->GetInterpolatedMarkers(interpolatedMarkers);
            return YES;
        }
        else
        {
            NSLog(@"Cannot perform morph");
            return NO;
        }
    }
}

@end
