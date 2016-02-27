//
//  AppDelegate.h
//  Selfwe
//
//  Created by Dan Shepherd on 01/07/2014.
//  Copyright (c) 2014 cuffedtothekeyboard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WatchConnectivity/WatchConnectivity.h>
#import "FaceppAPI.h"
#import "Utils.h"
#import "WatchUtil.h"

#define ACTIVE_FACEPP_SERVER 0

#define FACEPP_API_KEY_1 @"d33fe75136463ff7eda4795435d4ba09"
#define FACEPP_API_SECRET_1 @"B6fzKm1NTLjlfDpwiKzzBjKkqmWGJ8yN"

#define FACEPP_API_KEY_2 @"3cbf49ee7910298c31e5e6845cc4bfa2"
#define FACEPP_API_SECRET_2 @"QppNRweNnZ_zJuyg3a3GZHPTrLxUsVKd"


@interface AppDelegate : UIResponder <UIApplicationDelegate, WCSessionDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (NSNumber*)loadActiveFacePPServer;
- (void)saveActiveFacePPServer:(NSNumber*)serverNo;
- (void)startFacePPServer:(NSNumber*)serverNo;

@end
