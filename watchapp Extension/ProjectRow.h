//
//  ProjectRow.h
//  MorphUs
//
//  Created by Dan Shepherd on 21/02/2016.
//  Copyright © 2016 cuffedtothekeyboard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface ProjectRow : NSObject

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *name;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *thumbImage;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *createdAt;

@end
