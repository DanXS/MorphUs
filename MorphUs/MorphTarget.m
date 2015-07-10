//
//  MorphTarget.m
//  MorphUs
//
//  Created by Dan Shepherd on 02/07/2014.
//  Copyright (c) 2014 cuffedtothekeyboard. All rights reserved.
//

#import "MorphTarget.h"

@implementation MorphTarget

@synthesize assetURL;
@synthesize image;
@synthesize markers;

- (id)init {
    self = [super init];
    if (self) {
        self.assetURL = nil;
        self.image = nil;
        self.markers = nil;
    }
    return self;
}

@end
