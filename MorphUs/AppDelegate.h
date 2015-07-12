//
//  AppDelegate.h
//  Selfwe
//
//  Created by Dan Shepherd on 01/07/2014.
//  Copyright (c) 2014 cuffedtothekeyboard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FaceppAPI.h"
#import "Utils.h"

#define FACEPP_API_KEY @"3cbf49ee7910298c31e5e6845cc4bfa2"
#define FACEPP_API_SECRET @"QppNRweNnZ_zJuyg3a3GZHPTrLxUsVKd"


@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
