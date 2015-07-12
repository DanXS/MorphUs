//
//  Utils.m
//  MorphUs
//
//  Created by Dan Shepherd on 12/07/2015.
//  Copyright (c) 2015 cuffedtothekeyboard. All rights reserved.
//

#import "Utils.h"

@implementation Utils

+ (BOOL)isIPad
{
    static BOOL isIPad = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isIPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    });
    return isIPad;
}

@end
