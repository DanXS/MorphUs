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
}

- (void)session:(WCSession *)session didReceiveUserInfo:(NSDictionary<NSString *, id> *)userInfo {
    
}

- (void)session:(WCSession *)session didReceiveFile:(WCSessionFile *)file {
    NSURL* path = file.fileURL;
    NSDictionary* metadata = file.metadata;
    NSString* type = [metadata valueForKey:@"Type"];
    NSData* data = [NSData dataWithContentsOfURL:path];
    if (data != nil && [type isEqualToString:@"ImageFrame"]) {
        NSNumber* frame = [metadata valueForKey:@"Frame"];
        NSLog(@"Loaded frame %@", frame);
        [self.frames addObject:data];
        self.noFramesLoaded = [NSNumber numberWithInt:[self.noFramesLoaded integerValue] + 1];
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



