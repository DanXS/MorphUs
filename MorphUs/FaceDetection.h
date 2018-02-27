//
//  FaceDetection.h
//  MorphUs
//
//  Created by Dan Shepherd on 25/02/2018.
//  Copyright © 2018 cuffedtothekeyboard. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FaceDetection : NSObject

@property (assign, atomic) bool isInitialized;

- (id)init;
- (NSArray*)detectFaces:(UIImage*)image;
- (NSDictionary*)findLargest:(NSArray*)rects;
- (NSArray*)findLandmarksForImage:(UIImage*)image withRect:(NSDictionary*)rect;

@end
