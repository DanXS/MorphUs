//
//  VideoWriter.m
//  MorphUs
//
//  Created by Dan Shepherd on 08/07/2014.
//  Copyright (c) 2014 cuffedtothekeyboard. All rights reserved.
//

#import "VideoWriter.h"
@interface VideoWriter ()
{
    NSURL* _url;
    NSNumber* _width;
    NSNumber* _height;
    AVAssetWriterInput* _writerInput;
    AVAssetWriterInputPixelBufferAdaptor* _adaptor;
    AVAssetWriter* _videoWriter;
}
@end

@implementation VideoWriter

-(id)initWithFileURL:(NSURL*)url withWidth:(int)width andHeight:(int)height
{
    self = [super init];
    if(self) {
        _url = url;
        _width = [NSNumber numberWithInt:width];
        _height = [NSNumber numberWithInt:height];
        [self initWriter];
    }
    return self;
}

- (void) initWriter
{
    NSError *error = nil;
    _videoWriter = [[AVAssetWriter alloc] initWithURL:_url fileType:AVFileTypeQuickTimeMovie error:&error];
    if(error) {
        NSLog(@"error creating AssetWriter: %@",[error description]);
    }
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   _width, AVVideoWidthKey,
                                   _height, AVVideoHeightKey,
                                   nil];
    
    _writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                       outputSettings:videoSettings];
    
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    
    [attributes setObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32ARGB] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
    [attributes setObject:_width forKey:(NSString*)kCVPixelBufferWidthKey];
    [attributes setObject:_height forKey:(NSString*)kCVPixelBufferHeightKey];
    
    _adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_writerInput
                                                     sourcePixelBufferAttributes:attributes];
    
    [_videoWriter addInput:_writerInput];
    
    _writerInput.expectsMediaDataInRealTime = YES;
    
    //Start a session:
    BOOL start = [_videoWriter startWriting];
    NSLog(@"Session started? %d", start);
    [_videoWriter startSessionAtSourceTime:kCMTimeZero];
}

-(Boolean)writePixels:(CVPixelBufferRef)buffer withPresentationTime:(CMTime)presentTime
{
    while(!_adaptor.assetWriterInput.isReadyForMoreMediaData)
        [NSThread sleepForTimeInterval:0.02];
    NSLog(@"present time = %f", CMTimeGetSeconds(presentTime));
    BOOL append_ok = [_adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
    if(!append_ok){
        NSError *error = _videoWriter.error;
        if(error!=nil) {
            NSLog(@"Unresolved error %@,%@.", error, [error userInfo]);
        }
    }
    return append_ok;
}


-(void)waitForComplete:(VideoWriteCompletionBlock) completionBlock;
{
    [_writerInput markAsFinished];
    [_videoWriter finishWritingWithCompletionHandler:^{
        switch (_videoWriter.status)
        {
            case AVAssetWriterStatusUnknown:
                NSLog(@"Movie status unknown");
                completionBlock(NO);
                break;
            case AVAssetWriterStatusCancelled:
                NSLog(@"Movie status cancelled");
                completionBlock(NO);
                break;
            case AVAssetWriterStatusFailed:
                NSLog(@"Movie status failed %@", _videoWriter.error);
                completionBlock(NO);
                break;
            case AVAssetWriterStatusWriting:
                NSLog(@"Movie status writting");
                completionBlock(YES);
                break;
            case AVAssetWriterStatusCompleted:
                NSLog(@"Movie Export completed");
                completionBlock(YES);
                break;
        }
    }];
    CVPixelBufferPoolRelease(_adaptor.pixelBufferPool);
    
}

@end
