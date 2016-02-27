//
//  InterfaceController.m
//  watchapp Extension
//
//  Created by Dan Shepherd on 21/02/2016.
//  Copyright © 2016 cuffedtothekeyboard. All rights reserved.
//

#import "InterfaceController.h"


@interface InterfaceController()

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    self.noProjects = [NSNumber numberWithInt:0];
    self.noProjectsLoaded = [NSNumber numberWithInt:0];
    self.projects = [[NSMutableArray alloc] init];
    self.projectPaths = [[NSMutableArray alloc] init];
    if ([WCSession isSupported]) {
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
        if ([session isReachable]) {
            [self getProjectPaths];
        }
        else {
            [self errorAlert:@"iPhone not reachable"];
        }
    }
    else {
        [self errorAlert:@"WCSession no supported"];
    }
}

- (void)initProjects {
    if (self.projects != nil) {
        [self.projectsTable setNumberOfRows:self.projects.count withRowType:@"ProjectRow"];
        for (int i = 0; i < self.projects.count; i++) {
            NSDictionary* description = [self.projects objectAtIndex:i];
            NSDate* createdAt = [description valueForKey:@"createdAt"];
            NSDateFormatter* dateFormater = [[NSDateFormatter alloc] init];
            [dateFormater setDateFormat:@"dd MMM yy"];
            NSString* createdAtString = [NSString stringWithFormat:@"Created %@", [dateFormater stringFromDate:createdAt]];
            NSData* thumb = [description objectForKey:@"thumbImage"];
            ProjectRow* row = [self.projectsTable rowControllerAtIndex:i];
            row.name.text = [description valueForKey:@"name"];
            row.thumbImage.image = [UIImage imageWithData:thumb];
            row.createdAt.text = createdAtString;
        }
    }
}

- (void)sessionReachabilityDidChange:(WCSession *)session {
    if ([session isReachable]) {
        [self getProjectPaths];
    }
}

- (id)contextForSegueWithIdentifier:(NSString *)segueIdentifier inTable:(WKInterfaceTable *)table rowIndex:(NSInteger)rowIndex
{
    NSMutableDictionary* context = [[NSMutableDictionary alloc] init];
    if ([segueIdentifier isEqualToString:@"showMorph"])
    {
        NSString* projectPath = [self.projectPaths objectAtIndex:rowIndex];
        NSDictionary* row = [self.projects objectAtIndex:rowIndex];
        [context setObject:projectPath forKey:@"project"];
        [context setObject:[row valueForKey:@"noFrames"] forKey:@"noFrames"];
    }
    return context;
}

- (void)session:(WCSession *)session didReceiveUserInfo:(NSDictionary<NSString *, id> *)userInfo {
    
}

- (void)session:(WCSession *)session didReceiveMessageData:(NSData *)messageData replyHandler:(void (^)(NSData * _Nonnull))replyHandler
{
    NSDictionary* description = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:messageData];
    [self.projects addObject:description];
    self.noProjectsLoaded = [NSNumber numberWithInt:self.noProjectsLoaded.intValue + 1 ];
    if ([self.noProjectsLoaded intValue] == [self.noProjects intValue]) {
        [self initProjects];
    }
    NSDictionary* reply = @{@"result" : @"success"};
    NSData* replyData = [NSKeyedArchiver archivedDataWithRootObject:reply];
    replyHandler(replyData);
}

- (void)getProjectDescription:(NSString*)filename {
    @synchronized(self) {
        NSDictionary* requestData = [[NSDictionary alloc] initWithObjects:@[[NSNumber numberWithBool:YES], filename] forKeys:@[@"getProjectDescription", @"Filename"]];
        
        if ([[WCSession defaultSession] isReachable]) {
            [[WCSession defaultSession] sendMessage:requestData replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
                NSLog(@"result %@", replyMessage);
                [self.projectPaths addObject:[requestData valueForKey:@"Filename"]];
            } errorHandler:^(NSError * _Nonnull error) {
                NSLog(@"Error: %@", error.localizedDescription);
                [self errorAlert:error.localizedDescription];
            }];
        }
        else {
            NSLog(@"Session not reachable");
            [self errorAlert:@"iPhone session not reachable"];
        }
    }
}

- (void)getProjectPaths {
    @synchronized(self) {
        NSDictionary* requestData = [[NSDictionary alloc] initWithObjects:@[[NSNumber numberWithBool:YES]] forKeys:@[@"getProjectPaths"]];
        
        if ([[WCSession defaultSession] isReachable]) {
            [[WCSession defaultSession] sendMessage:requestData replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
                NSLog(@"project paths %@", replyMessage);
                NSArray* paths = [replyMessage valueForKey:@"ProjectPaths"];
                if (paths.count == 0) {
                    WKAlertAction* action = [WKAlertAction actionWithTitle:@"OK" style:WKAlertActionStyleDefault handler:^{
                        [self popController];
                    }];
                    [self presentAlertControllerWithTitle:@"No Morphs!" message:@"No Morphs have been exported from the iPhone application, please click the export button and choose \"Export to apple watch\" from the iPhone application" preferredStyle:WKAlertControllerStyleAlert actions:@[action]];
                }
                else {
                    self.noProjects = [NSNumber numberWithInt:paths.count];
                    for (int i = 0; i < paths.count; i++) {
                        NSString* filename = [paths objectAtIndex:i];
                        if (![self hasFile:filename]) {
                            [self getProjectDescription:filename];
                        }
                    }
                }
            } errorHandler:^(NSError * _Nonnull error) {
                NSLog(@"Error: %@", error.localizedDescription);
                [self errorAlert:error.localizedDescription];
            }];
        }
        else {
            NSLog(@"Session not reachable");
            [self errorAlert:@"iPhone session not reachable"];
        }
    }
}

- (BOOL)hasFile:(NSString*)filename {
    if (self.projectPaths == nil)
        return NO;
    for (int i = 0; i < self.projectPaths.count; i++) {
        NSString* path = [self.projectPaths objectAtIndex:i];
        if ([path isEqualToString:filename]) {
            return YES;
        }
    }
    return NO;
}

- (void)errorAlert:(NSString*)message {
    WKAlertAction* action = [WKAlertAction actionWithTitle:@"OK" style:WKAlertActionStyleDefault handler:^{
        [self popController];
    }];
    [self presentAlertControllerWithTitle:@"Error!" message:message preferredStyle:WKAlertControllerStyleAlert actions:@[action]];
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



