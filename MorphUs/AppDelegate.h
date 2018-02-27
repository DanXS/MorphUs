//
//  AppDelegate.h
//  Selfwe
//
//  Created by Dan Shepherd on 01/07/2014.
//  Copyright (c) 2014 cuffedtothekeyboard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WatchConnectivity/WatchConnectivity.h>

#import "Utils.h"
#import "WatchUtil.h"
#import "FaceDetection.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, WCSessionDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) FaceDetection* faceDetection;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
