//
//  AppDelegate.m
//  MorphUs
//
//  Created by Dan Shepherd on 01/07/2014.
//  Copyright (c) 2014 cuffedtothekeyboard. All rights reserved.
//

#import "AppDelegate.h"
#import "ProjectsViewController.h"

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    // Set up FaceppAPI for face detection
    [self startFacePPServer:[self loadActiveFacePPServer]];

    UIStoryboard *mainStoryboard = nil;
    // Fetch Main Storyboard
    if([Utils isIPad])
        mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle: nil];
    else
        mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    
    // Instantiate Root Navigation Controller
    UINavigationController *rootNavigationController = (UINavigationController *)[mainStoryboard instantiateViewControllerWithIdentifier:@"rootNavigationController"];
    
    // Configure View Controller
    ProjectsViewController *viewController = (ProjectsViewController *)[rootNavigationController topViewController];
    
    if ([viewController isKindOfClass:[ProjectsViewController class]]) {
        [viewController setManagedObjectContext:self.managedObjectContext];
    }
    
    // Configure Window
    [self.window setRootViewController:rootNavigationController];

    if ([WCSession isSupported]) {
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
    }
    
    return YES;
}

- (void)session:(nonnull WCSession *)session didReceiveMessage:(nonnull NSDictionary<NSString *,id> *)message replyHandler:(nonnull void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler {
    NSLog(@"Recieved call from watch app :%@", message);
    if ([[message valueForKey:@"getProjectPaths"] boolValue])
    {
        NSMutableArray* filenames = [[NSMutableArray alloc] init];
        NSArray* directoryContent = [WatchUtil getDirectoryContent];
        for (int i = 0; i < directoryContent.count; i++) {
            NSString* filename = [directoryContent objectAtIndex:i];
            if ([filename containsString:@"Project"]) {
                [filenames addObject:filename];
            }
        }
        NSDictionary* result = @{@"ProjectPaths" : filenames};
        replyHandler(result);
    }
    else if ([[message valueForKey:@"getProjectDescription"] boolValue]) {
        NSString* filename = [message valueForKey:@"Filename"];
        NSData* file = [WatchUtil readFile:filename];
        [session sendMessageData:file replyHandler:^(NSData * _Nonnull replyMessageData) {
            NSDictionary* replyMesssage = [NSKeyedUnarchiver unarchiveObjectWithData:replyMessageData];
            NSLog(@"reply message data %@", replyMesssage);
        } errorHandler:^(NSError * _Nonnull error) {
            NSLog(@"Error: %@", error.localizedDescription);
        }];
        NSDictionary* result = [[NSDictionary alloc] initWithObjects:@[[NSNumber numberWithBool:YES]] forKeys:@[@"loadingProjectDescription"]];
        replyHandler(result);
    }
    else if ([[message valueForKey:@"getFrames"] boolValue]) {
        NSString* projectFile = [message valueForKey:@"Filename"];
        NSString* uuid = [projectFile substringWithRange:NSMakeRange(8,projectFile.length-14)];
        NSArray* directoryContent = [WatchUtil getDirectoryContent];
        for (int i = 0; i < directoryContent.count; i++) {
            NSString* filename = [directoryContent objectAtIndex:i];
            if ([filename containsString:@"Image"] && [filename containsString:uuid]) {
                NSRange rangeStart = [filename rangeOfString:@"_"];
                NSRange rangeEnd = [filename rangeOfString:@"."];
                NSUInteger start = rangeStart.location+1;
                NSUInteger end = rangeEnd.location;
                NSString* frameString = [filename substringWithRange:NSMakeRange(start, end-start)];
                rangeStart = [frameString rangeOfString:@"_"];
                frameString = [frameString substringFromIndex:rangeStart.location+1];
                NSNumber* frame = [NSNumber numberWithInt:[frameString intValue]];
                NSString* path = [WatchUtil getPath:filename];
                [session transferFile:[NSURL fileURLWithPath:path] metadata:@{@"Type" : @"ImageFrame", @"Frame" : frame}];
            }
        }
        NSDictionary* result = [[NSDictionary alloc] initWithObjects:@[[NSNumber numberWithBool:YES]] forKeys:@[@"loadingImageFrames"]];
        replyHandler(result);
    }
    
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"MorphModel" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"MorphModel.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
        abort();
#endif
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - FacePPServer settings

- (NSNumber*)loadActiveFacePPServer
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber* serverNo = [userDefaults valueForKey:@"activeFacePPServer"];
    if(!serverNo)
    {
        serverNo = [NSNumber numberWithInt:ACTIVE_FACEPP_SERVER];
        [self saveActiveFacePPServer:serverNo];
    }
    return serverNo;
}

- (void)saveActiveFacePPServer:(NSNumber*)serverNo
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:serverNo forKey:@"activeFacePPServer"];
    [userDefaults synchronize];
}

- (void)startFacePPServer:(NSNumber*)serverNo
{
    if([serverNo intValue] == APIServerRegionCN)
    {
        NSLog(@"Connecting to server in China");
        [FaceppAPI initWithApiKey:FACEPP_API_KEY_1 andApiSecret:FACEPP_API_SECRET_1 andRegion:APIServerRegionCN];
    }
    else
    {
        NSLog(@"Connecting to server in USA");
        [FaceppAPI initWithApiKey:FACEPP_API_KEY_2 andApiSecret:FACEPP_API_SECRET_2 andRegion:APIServerRegionUS];
    }
}


@end
