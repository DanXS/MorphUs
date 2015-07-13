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

#define FACEPP_API_KEY @"d33fe75136463ff7eda4795435d4ba09"
#define FACEPP_API_SECRET @"B6fzKm1NTLjlfDpwiKzzBjKkqmWGJ8yN"


@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
