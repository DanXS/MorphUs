//
//  ImageUtils.h
//  MorphUs
//
//  Created by Dan Shepherd on 11/07/2014.
//  Copyright (c) 2014 cuffedtothekeyboard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageUtils : NSObject

+ (UIImage*)resizeImage:(UIImage*)image scale:(CGFloat)scale newSize:(CGSize)newSize;
+ (CVPixelBufferRef) pixelBufferFromCGImage:(CGImageRef)image withWidth:(int)width andHeight:(int)height;
+ (UIImage*)makeHorizontalThumbWithImages:(NSArray*)scaledImages size:(CGSize)rect withSpacing:(float)spacing;
+ (UIImage*)drawImage:(UIImage*)fgImage inImage:(UIImage*)bgImage atPoint:(CGPoint)point;

@end
