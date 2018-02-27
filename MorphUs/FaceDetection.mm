//
//  FaceDetection.mm
//  MorphUs
//
//  Created by Dan Shepherd on 25/02/2018.
//  Copyright © 2018 cuffedtothekeyboard. All rights reserved.
//

#import "FaceDetection.h"
#import "ImageUtils.h"

#include <dlib/image_processing.h>
#include <dlib/image_io.h>

@interface FaceDetection()
{
    dlib::shape_predictor sp;
}
@end

@implementation FaceDetection

- (id)init {
    self = [super init];
    if(self)
    {
        [self setupDetector];
    }
    return self;
}

- (void)setupDetector {
    self.isInitialized = false;
    NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];
    if (modelFileName != nil) {
        std::string modelFileNameCString = [modelFileName UTF8String];
        dlib::deserialize(modelFileNameCString) >> sp;
        self.isInitialized = true;
    }
}

- (dlib::array2d<dlib::bgr_pixel>*)createDlibImage:(UIImage*)image {
    dlib::array2d<dlib::bgr_pixel>* pDlibImg = new dlib::array2d<dlib::bgr_pixel>();
    CVPixelBufferRef imageBuffer = [ImageUtils pixelBufferFromCGImage:image.CGImage withWidth:image.size.width andHeight:image.size.height];
    CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    char *baseBuffer = (char *)CVPixelBufferGetBaseAddress(imageBuffer);
    pDlibImg->set_size(height, width);
    pDlibImg->reset();
    long row = 0;
    long column = 0;
    while (pDlibImg->move_next()) {
        dlib::bgr_pixel& pixel = pDlibImg->element();
        long bufferLocation = (row * width + column) * 4;
        char r = baseBuffer[bufferLocation + 1];
        char g = baseBuffer[bufferLocation + 2];
        char b = baseBuffer[bufferLocation + 3];
        dlib::bgr_pixel newpixel(b, g, r);
        pixel = newpixel;
        column = column + 1;
        if (column >= width) {
            row = row + 1;
            column = 0;
        }
    }
    pDlibImg->reset();
    CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    return pDlibImg;
}

- (NSArray*)detectFaces:(UIImage*)image {
    CIContext *context = [CIContext context];
    NSDictionary *opts = @{ CIDetectorAccuracy : CIDetectorAccuracyHigh };
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:context
                                              options:opts];
    CIImage* ciImage = [[CIImage alloc] initWithImage:image];
    NSArray* features = [detector featuresInImage:ciImage options:nil];
    NSMutableArray* rects = [[NSMutableArray alloc] init];
    // just extract the face bounds
    for (int i = 0; i < [features count]; i++) {
        CIFeature* feature = [features objectAtIndex:i];
        CGRect bounds = feature.bounds;
        // Normalised bounds
        // Note: coordinates also flipped vertically
        NSDictionary* rect = [[NSDictionary alloc] initWithObjects:@[
                                [NSNumber numberWithDouble:1.0 - (double)(bounds.origin.y)/(double)image.size.height],
                                [NSNumber numberWithDouble:(double)(bounds.origin.x)/(double)image.size.width],
                                [NSNumber numberWithDouble:1.0 - (double)(bounds.origin.y+bounds.size.height)/(double)image.size.height],
                                [NSNumber numberWithDouble:(double)(bounds.origin.x+bounds.size.width)/(double)image.size.width]]
                                                           forKeys:@[@"bottom", @"left", @"top", @"right"]];
        [rects addObject:rect];
    }
    return rects;
}

- (NSDictionary*)findLargest:(NSArray*)rects {
    NSDictionary* largest = nil;
    double max = 0.0;
    int maxIndex = -1;
    for (int i = 0; i < [rects count]; i++) {
        NSDictionary* rect = [rects objectAtIndex:i];
        NSNumber* top = [rect valueForKey:@"top"];
        NSNumber* left = [rect valueForKey:@"left"];
        NSNumber* bottom = [rect valueForKey:@"bottom"];
        NSNumber* right = [rect valueForKey:@"right"];
        double width = right.doubleValue - left.doubleValue;
        double height = bottom.doubleValue - top.doubleValue;
        if (width*width + height*height > max) {
            max = width*width + height*height;
            maxIndex = i;
        }
    }
    if (maxIndex >= 0) {
        largest = [rects objectAtIndex:maxIndex];
    }
    return largest;
}

- (NSArray*)findLandmarksForImage:(UIImage*)image withRect:(NSDictionary*)rect {
    dlib::array2d<dlib::bgr_pixel>* pDlibImg = [self createDlibImage:image];
    dlib::rectangle dlibRect;
    dlibRect.set_top((long)(((NSNumber*)[rect valueForKey:@"top"]).doubleValue * (double) image.size.height));
    dlibRect.set_left((long)(((NSNumber*)[rect valueForKey:@"left"]).doubleValue * (double) image.size.width));
    dlibRect.set_bottom((long)(((NSNumber*)[rect valueForKey:@"bottom"]).doubleValue * (double) image.size.height));
    dlibRect.set_right((long)(((NSNumber*)[rect valueForKey:@"right"]).doubleValue * (double) image.size.width));
    dlib::full_object_detection shape = sp(*pDlibImg, dlibRect);
    NSMutableArray* landmarks = [[NSMutableArray alloc] init];
    for (unsigned long i = 0; i < shape.num_parts(); i++) {
        dlib::point point = shape.part(i);
        // Normalised marker locations
        NSNumber* x = [NSNumber numberWithDouble: (double)point.x()/(double)image.size.width];
        NSNumber* y = [NSNumber numberWithDouble: (double)point.y()/(double)image.size.height];
        NSDictionary* landmark = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:x, y, nil]
                                                               forKeys:[NSArray arrayWithObjects:@"x", @"y", nil]];
        [landmarks addObject:landmark];
    }
    return landmarks;
}

@end
