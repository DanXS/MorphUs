//
//  InterfaceController.h
//  watchapp Extension
//
//  Created by Dan Shepherd on 21/02/2016.
//  Copyright © 2016 cuffedtothekeyboard. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import <WatchConnectivity/WatchConnectivity.h>
#import "ProjectRow.h"

@interface InterfaceController : WKInterfaceController<WCSessionDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *projectsTable;
@property (strong, nonatomic) NSMutableArray* projectPaths;
@property (strong, nonatomic) NSMutableArray* projects;
@property (strong, nonatomic) NSNumber* noProjects;
@property (strong, nonatomic) NSNumber* noProjectsLoaded;

@end
