//
//  VideoWriter.h
//  MorphUs
//
//  Created by Dan Shepherd on 08/07/2014.
//  Copyright (c) 2014 cuffedtothekeyboard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>


@interface VideoWriter : NSObject

@property (strong, nonatomic) NSURL* movieURL;

-(id)initWithFileURL:(NSURL*)url withWidth:(int)width andHeight:(int)height;
-(Boolean) writePixels:(CVPixelBufferRef)buffer withPresentationTime:(CMTime)presentTime;
-(void)markAsComplete;

@end
