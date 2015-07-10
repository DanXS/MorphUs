//
//  MorphTarget.h
//  MorphUs
//
//  Created by Dan Shepherd on 02/07/2014.
//  Copyright (c) 2014 cuffedtothekeyboard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MorphTarget : NSObject

@property (strong, nonatomic) NSURL* assetURL;
@property (strong, nonatomic) UIImage* image;
@property (strong, nonatomic) NSMutableArray* markers;

- (id)init;

@end
