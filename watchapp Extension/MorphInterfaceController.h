//
//  MorphInterfaceController.h
//  MorphUs
//
//  Created by Dan Shepherd on 21/02/2016.
//  Copyright © 2016 cuffedtothekeyboard. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import <WatchConnectivity/WatchConnectivity.h>

@interface MorphInterfaceController : WKInterfaceController<WCSessionDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfacePicker *morphImagePicker;
@property (strong, nonatomic) NSNumber* noFrames;
@property (strong, nonatomic) NSNumber* noFramesLoaded;
@property (strong, nonatomic) NSMutableArray* frames;

@end
