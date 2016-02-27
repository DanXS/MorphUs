//
//  WatchUtil.m
//  MorphUs
//
//  Created by Dan Shepherd on 21/02/2016.
//  Copyright © 2016 cuffedtothekeyboard. All rights reserved.
//

#import "WatchUtil.h"
#import "ImageUtils.h"

@implementation WatchUtil

+ (NSString*)storeProjectDescription:(NSManagedObject*)managedObject noFrames:(int)noFrames {
    NSDate* createdAt = [managedObject valueForKey:@"createdAt"];
    NSString* name = [managedObject valueForKey:@"name"];
    NSData* thumb = [managedObject valueForKey:@"thumbImage"];
    NSString* uuid = [managedObject valueForKey:@"uuid"];
    UIImage* thumbImage = [UIImage imageWithData:thumb];
    UIImage* scaledImage = nil;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)]) {
        // Retina display
        scaledImage = [ImageUtils resizeImage:thumbImage scale:[UIScreen mainScreen].scale newSize:CGSizeMake(200.0, 60.0)];;
        
    } else {
        // non-Retina display
        scaledImage = [ImageUtils resizeImage:thumbImage scale:1.0 newSize:CGSizeMake(200.0, 60.0)];
    }
    NSData* scaledThumb = UIImageJPEGRepresentation(scaledImage, 0.3);
    NSDictionary* description = @{@"type" : @"projectDescription", @"createdAt" : createdAt, @"name" : name, @"noFrames" : [NSNumber numberWithInt:noFrames], @"thumbImage" : scaledThumb};
    
    NSFileManager* fileManager = [[NSFileManager alloc] init];
    NSURL* url = [fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.com.cuffedtothekeyboard.MorphUs"];
    NSString* directory = [url path];
    //NSString* uuid = [[NSUUID UUID] UUIDString];
    NSString* filename = [NSString stringWithFormat:@"Project_%@.plist", uuid];
    NSString* path = [directory stringByAppendingPathComponent:filename];
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:description];
    [data writeToFile:path atomically:YES];
    return uuid;
}

+ (void)storeFrame:(int)frame uuid:(NSString*)uuid image:(UIImage*)image {
    NSFileManager* fileManager = [[NSFileManager alloc] init];
    NSURL* url = [fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.com.cuffedtothekeyboard.MorphUs"];
    NSString* directory = [url path];
    NSString* filename = [NSString stringWithFormat:@"Image_%@_%04d.plist", uuid, frame];
    NSString* path = [directory stringByAppendingPathComponent:filename];
    NSData* data = UIImageJPEGRepresentation(image, 0.3);
    [data writeToFile:path atomically:YES];
}

+ (NSArray*)getDirectoryContent {
    NSFileManager* fileManager = [[NSFileManager alloc] init];
    NSURL* url = [fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.com.cuffedtothekeyboard.MorphUs"];
    NSString* directory = [url path];
    NSArray* directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:NULL];
    return directoryContent;
}

+ (NSString*)getPath:(NSString*)filename {
    NSFileManager* fileManager = [[NSFileManager alloc] init];
    NSURL* url = [fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.com.cuffedtothekeyboard.MorphUs"];
    NSString* directory = [url path];
    NSString* path = [directory stringByAppendingPathComponent:filename];
    return path;
}

+ (NSData*)readFile:(NSString*)filename {
    NSFileManager* fileManager = [[NSFileManager alloc] init];
    NSURL* url = [fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.com.cuffedtothekeyboard.MorphUs"];
    NSString* directory = [url path];
    NSString* path = [directory stringByAppendingPathComponent:filename];
    NSData* data = [NSData dataWithContentsOfFile:path];
    return data;
}

@end
