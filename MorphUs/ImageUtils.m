//
//  ImageUtils.m
//  MorphUs
//
//  Created by Dan Shepherd on 11/07/2014.
//  Copyright (c) 2014 cuffedtothekeyboard. All rights reserved.
//

#import "ImageUtils.h"

@implementation ImageUtils


+ (UIImage *)resizeImage:(UIImage*)image scale:(double)scale newSize:(CGSize)newSize {
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = image.CGImage;
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Scale in case of retina display
    CGAffineTransform scaleTransform = CGAffineTransformMake(1.0/scale, 0.0, 0.0, 1.0/scale, 0.0, 0.0);
    CGContextConcatCTM(context, scaleTransform);
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 1.0, newSize.height);
    CGContextConcatCTM(context, flipVertical);
    
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    // Get scaled version
    CGImageRef newImageScaledRef = CGImageCreateWithImageInRect(newImageRef, newRect);
    
    UIImage *newImage = [UIImage imageWithCGImage:newImageScaledRef];
    
    CGImageRelease(newImageScaledRef);
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();

    return newImage;
}

+ (CVPixelBufferRef) pixelBufferFromCGImage:(CGImageRef)image withWidth:(int)width andHeight:(int)height {
    
    CGSize size = CGSizeMake(width, height);
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          size.width,
                                          size.height,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    if (status != kCVReturnSuccess){
        NSLog(@"Failed to create pixel buffer");
    }
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
                                                 size.height, 8, 4*size.width, rgbColorSpace,
                                                 kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}



@end
