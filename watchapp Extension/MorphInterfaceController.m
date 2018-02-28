//
//  MorphInterfaceController.m
//  MorphUs
//
//  Created by Dan Shepherd on 21/02/2016.
//  Copyright © 2016 cuffedtothekeyboard. All rights reserved.
//

#import "MorphInterfaceController.h"

@interface MorphInterfaceController ()

@end

@implementation MorphInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    NSLog(@"Context: %@", context);
    self.noFramesLoaded = [NSNumber numberWithInt:0];
    self.noFrames = [context valueForKey:@"noFrames"];
    self.frames = [[NSMutableArray alloc] init];
    // Initialise slots for image frames as they are loaded out of order
    for(int i = 0; i < [self.noFrames intValue]; i++) {
        [self.frames addObject:[[NSNull alloc] init]];
    }
    [self.morphImagePicker setAlpha:0.0];
    if ([WCSession isSupported]) {
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
        [self loadFramesForProjectFile:[context valueForKey:@"project"]];
    }
}

- (void)buildMorphAnim {
    NSMutableArray* animFrames = [[NSMutableArray alloc] init];
    for (int i = 0; i < [self.noFramesLoaded intValue]; i++) {
        NSData* data = [self.frames objectAtIndex:i];
        WKImage* image = [WKImage imageWithImageData:data];
        WKPickerItem* item = [[WKPickerItem alloc] init];
        [item setContentImage:image];
        [animFrames addObject:item];
    }
    [self.morphImagePicker setItems:animFrames];
    [self animateWithDuration:0.5 animations:^{
        [self.morphImagePicker setAlpha:1.0];
    }];
}

- (void)session:(WCSession *)session didReceiveUserInfo:(NSDictionary<NSString *, id> *)userInfo {
    
}

- (void)updateProgressIndicator:(int)progress of:(int)total
{
    int animFrame = (int)(100.0*(double)progress/(double)total);
    NSString* imageName = [NSString stringWithFormat:@"progress%d.png", animFrame];
    [self.containerGroup setBackgroundImageNamed:imageName];
}

- (void)session:(WCSession *)session didReceiveFile:(WCSessionFile *)file {
    NSURL* path = file.fileURL;
    NSDictionary* metadata = file.metadata;
    NSString* type = [metadata valueForKey:@"Type"];
    NSData* data = [NSData dataWithContentsOfURL:path];
    if (data != nil && [type isEqualToString:@"ImageFrame"]) {
        NSNumber* frame = [metadata valueForKey:@"Frame"];
        NSLog(@"Loaded frame %@", frame);
        // load the frame into the slot
        [self.frames setObject:data atIndexedSubscript:[frame unsignedIntValue] - 1];
        self.noFramesLoaded = [NSNumber numberWithInt:[self.noFramesLoaded intValue] + 1];
        [self updateProgressIndicator:[self.noFramesLoaded intValue] of:[self.noFrames intValue]];
        if ([self.noFramesLoaded intValue] == [self.noFrames intValue]) {
            [self buildMorphAnim];
            NSLog(@"loading complete");
        }
    }
}

- (void)loadFramesForProjectFile:(NSString*)filename {
    NSDictionary* requestData = [[NSDictionary alloc] initWithObjects:@[[NSNumber numberWithBool:YES], filename] forKeys:@[@"getFrames", @"Filename"]];
    
    if ([[WCSession defaultSession] isReachable]) {
        [[WCSession defaultSession] sendMessage:requestData replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
            NSLog(@"result %@", replyMessage);
        } errorHandler:^(NSError * _Nonnull error) {
            NSLog(@"Error: %@", error.localizedDescription);
        }];
    }
    else {
        NSLog(@"Session not reachable");
    }
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



