//
//  GLKMorphViewController.h
//  MorphUs
//
//  Created by Dan Shepherd on 04/07/2014.
//  Copyright (c) 2014 cuffedtothekeyboard. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreFoundation/CFDictionary.h>
#import "WatchUtil.h"


@interface GLKMorphViewController : GLKViewController

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObject* managedObject;

@property (strong, nonatomic) NSArray* morphSequence;
@property (strong, nonatomic) NSArray* morphTargets;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *playBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *pauseBarButtonItem;
@property (strong, nonatomic) NSURL* movieURL;
@property (strong, nonatomic) NSString* actionIdentifier;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UILabel *exportInfoLabel;
@property (weak, nonatomic) IBOutlet UIView *exportProgressView;
@property (weak, nonatomic) IBOutlet UIProgressView *exportProgressBarView;

- (IBAction)playToggle:(id)sender;
- (IBAction)back:(id)sender;
- (IBAction)abort:(id)sender;

@end
