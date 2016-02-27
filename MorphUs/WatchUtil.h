//
//  WatchUtil.h
//  MorphUs
//
//  Created by Dan Shepherd on 21/02/2016.
//  Copyright © 2016 cuffedtothekeyboard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WatchUtil : NSObject

+ (NSString*)storeProjectDescription:(NSManagedObject*)managedObject noFrames:(int)noFrames;

+ (void)storeFrame:(int)frame uuid:(NSString*)uuid image:(UIImage*)image;

+ (NSArray*)getDirectoryContent;

+ (NSString*)getPath:(NSString*)filename;

+ (NSData*)readFile:(NSString*)filename;

@end
