//
//  MorphViewController.m
//  MorphUs
//
//  Created by Dan Shepherd on 01/07/2014.
//  Copyright (c) 2014 cuffedtothekeyboard. All rights reserved.
//

#define IS_IPAD [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad
#import "MorphViewController.h"
#import "ImageCollectionViewCell.h"
#import "GLKMorphViewController.h"
#import "ImageUtils.h"

@interface MorphViewController ()
@end

@implementation MorphViewController

@synthesize imageView;
@synthesize library;
@synthesize assetGroup;
@synthesize currentMorphTarget;
@synthesize markersLayer;
@synthesize morphTargets;
@synthesize morphSequence;
@synthesize currentMorphSequenceIndex;
@synthesize activeMarkerIndex;
@synthesize landmarkKeyNames;
@synthesize movieURL;
@synthesize actionIdentifier;
@synthesize choosePhotoActionSheet;

- (void)viewDidLoad
{
    [super viewDidLoad];
    assert(self.managedObjectContext != nil);
    assert(self.managedObject != nil);
    [self createMarkersLayer];
    [self logSelectedProjectInfo];
    [self initLandmarkKeyNames];
    imagePicker = [[UIImagePickerController alloc] init];
    self.library = [[ALAssetsLibrary alloc] init];
    self.currentMorphTarget = nil;
    self.morphTargets = [[NSMutableArray alloc] init];
    self.morphSequence = [[NSMutableArray alloc] init];
    self.imageCollectionView.delegate = self;
    self.imageCollectionView.dataSource = self;
    self.currentMorphSequenceIndex = -1;
    self.activeMarkerIndex = -1;
    self.movieURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"MorphUsMovie.mov"]];
    [self findAlbum:@"MorphUs"];
    [self loadMorphTargetsForProject];
}

- (void)logSelectedProjectInfo
{
    NSString* name = [self.managedObject valueForKey:@"name"];
    NSDate* createdAt = [self.managedObject valueForKey:@"createdAt"];
    NSString* createdAtString = [NSDateFormatter localizedStringFromDate:createdAt
                                                               dateStyle:NSDateFormatterShortStyle
                                                               timeStyle:NSDateFormatterShortStyle];
    NSLog(@"Name = %@", name);
    NSLog(@"Created At = %@", createdAtString);
}

- (void)dealloc
{
    if(IS_IPAD) {
        if(self.imageView) {
            [self removeMarkersLayer];
        }
    }
}

- (void)initLandmarkKeyNames
{
self.landmarkKeyNames = [NSArray arrayWithObjects:
                             @"contour_chin",
                             @"contour_left1",
                             @"contour_left2",
                             @"contour_left3",
                             @"contour_left4",
                             @"contour_left5",
                             @"contour_left6",
                             @"contour_left7",
                             @"contour_left8",
                             @"contour_left9",
                             @"contour_right1",
                             @"contour_right2",
                             @"contour_right3",
                             @"contour_right4",
                             @"contour_right5",
                             @"contour_right6",
                             @"contour_right7",
                             @"contour_right8",
                             @"contour_right9",
                             @"left_eye_bottom",
                             @"left_eye_left_corner",
                             @"left_eye_lower_left_quarter",
                             @"left_eye_lower_right_quarter",
                             @"left_eye_pupil",
                             @"left_eye_right_corner",
                             @"left_eye_top",
                             @"left_eye_upper_left_quarter",
                             @"left_eye_upper_right_quarter",
                             @"left_eyebrow_left_corner",
                             @"left_eyebrow_lower_left_quarter",
                             @"left_eyebrow_lower_middle",
                             @"left_eyebrow_lower_right_quarter",
                             @"left_eyebrow_right_corner",
                             @"left_eyebrow_upper_left_quarter",
                             @"left_eyebrow_upper_middle",
                             @"left_eyebrow_upper_right_quarter",
                             @"mouth_left_corner",
                             @"mouth_lower_lip_bottom",
                             @"mouth_lower_lip_left_contour1",
                             @"mouth_lower_lip_left_contour2",
                             @"mouth_lower_lip_left_contour3",
                             @"mouth_lower_lip_right_contour1",
                             @"mouth_lower_lip_right_contour2",
                             @"mouth_lower_lip_right_contour3",
                             @"mouth_lower_lip_top",
                             @"mouth_right_corner",
                             @"mouth_upper_lip_bottom",
                             @"mouth_upper_lip_left_contour1",
                             @"mouth_upper_lip_left_contour2",
                             @"mouth_upper_lip_left_contour3",
                             @"mouth_upper_lip_right_contour1",
                             @"mouth_upper_lip_right_contour2",
                             @"mouth_upper_lip_right_contour3",
                             @"mouth_upper_lip_top",
                             @"nose_contour_left1",
                             @"nose_contour_left2",
                             @"nose_contour_left3",
                             @"nose_contour_lower_middle",
                             @"nose_contour_right1",
                             @"nose_contour_right2",
                             @"nose_contour_right3",
                             @"nose_left",
                             @"nose_right",
                             @"nose_tip",
                             @"right_eye_bottom",
                             @"right_eye_left_corner",
                             @"right_eye_lower_left_quarter",
                             @"right_eye_lower_right_quarter",
                             @"right_eye_pupil",
                             @"right_eye_right_corner",
                             @"right_eye_top",
                             @"right_eye_upper_left_quarter",
                             @"right_eye_upper_right_quarter",
                             @"right_eyebrow_left_corner",
                             @"right_eyebrow_lower_left_quarter",
                             @"right_eyebrow_lower_middle",
                             @"right_eyebrow_lower_right_quarter",
                             @"right_eyebrow_right_corner",
                             @"right_eyebrow_upper_left_quarter",
                             @"right_eyebrow_upper_middle",
                             @"right_eyebrow_upper_right_quarter",
                             nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImage *)fixOrientation:(UIImage *)aImage {
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}



-(void)findAlbum:(NSString*)albumName;
{
    [self.library addAssetsGroupAlbumWithName:albumName
                                  resultBlock:^(ALAssetsGroup *group) {
                                      NSLog(@"added album:%@", albumName);
                                  }
                                 failureBlock:^(NSError *error) {
                                     NSLog(@"error adding album");
                                 }];
}

-(void)addFaceImageToAlbum:(UIImage*)image toAlbum:(NSString*)albumName
{
    __block ALAssetsLibrary* lib = self.library;
    __block MorphTarget* target = self.currentMorphTarget;
    [lib enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                    if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:albumName]) {
                                        NSLog(@"found album %@", albumName);
                                        [lib writeImageToSavedPhotosAlbum:[image CGImage]
                                                                          metadata:nil
                                                                   completionBlock:^(NSURL* assetURL, NSError* error) {
                                                                       if (error.code == 0) {
                                                                           target.assetURL = assetURL;
                                                                           NSLog(@"saved image completed:\nurl: %@", assetURL);
                                                                           [lib assetForURL:assetURL
                                                                                         resultBlock:^(ALAsset *asset) {
                                                                                             [group addAsset:asset];
                                                                                             NSLog(@"Added asset to album");
                                                                                         }
                                                                                        failureBlock:^(NSError* error) {
                                                                                            NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                                                                                        }];
                                                                       }
                                                                       else {
                                                                           NSLog(@"saved image failed.\nerror code %ld\n%@", (long)error.code, [error localizedDescription]);
                                                                       }
                                                                   }];
                                    }
                                }
                              failureBlock:^(NSError* error) {
                                  NSLog(@"Failed to find asset groups %@", [error localizedDescription] );
                              }];
}

-(void)loadImageFromAssetUrl:(NSURL*)assetURL completionBlock:(LoadImageCompletionBlock)completionBlock
{
    [self.library assetForURL:assetURL
                  resultBlock:^(ALAsset *asset) {
                       ALAssetRepresentation *rep = [asset defaultRepresentation];
                       CGImageRef iref = [rep fullResolutionImage];
                       if (iref) {
                           UIImage* image = [UIImage imageWithCGImage:iref];
                           completionBlock(image, nil);
                       }
                  }
                  failureBlock:^(NSError *error) {
                      completionBlock(nil, error);
                  }];
}

-(NSString*)tryDetectFace:(UIImage*)image
{
    NSString* errorMsg = nil;
    FaceppResult* result = [[FaceppAPI detection] detectWithURL:nil orImageData:UIImageJPEGRepresentation(image, 0.5) mode:FaceppDetectionModeNormal attribute:FaceppDetectionAttributeNone];
    if(result.success)
    {
        NSArray* faces = result.content[@"face"];
        if(faces.count > 0)
        {

            NSString* faceId = faces[0][@"face_id"];
            result = [[FaceppAPI detection] landmarkWithFaceId:faceId andType:FaceppLandmark83P];
            if(result.success) {
                MorphTarget* target = [[MorphTarget alloc] init];
                target.markers = [[NSMutableArray alloc] init];
                for(ptrdiff_t i = 0; i < landmarkKeyNames.count; i++) {
                    NSNumber* x = result.content[@"result"][0][@"landmark"][self.landmarkKeyNames[i]][@"x"];
                    NSNumber* y = result.content[@"result"][0][@"landmark"][self.landmarkKeyNames[i]][@"y"];
                    NSLog(@"Landmark[%td]=[%g %g]", i, [x doubleValue], [y doubleValue]);
                    [target.markers addObject:[[NSDictionary alloc]
                                        initWithObjects:[NSArray arrayWithObjects:x, y, nil]
                                        forKeys:[NSArray arrayWithObjects:@"x", @"y", nil]]];
                }
                [self.morphTargets addObject:target];
                self.currentMorphTarget = target;
            }
            else {
                errorMsg = @"No landmarks found for the detected face";
            }
        }
        else
        {
            errorMsg = @"No faces detected";
        }
    }
    else {
        errorMsg = result.error.message;
    }
    return errorMsg;
}

- (void) redrawImageViewForTarget:(MorphTarget*)target
{
    self.currentMorphTarget = target;
    self.imageView.image = self.currentMorphTarget.image;
    [self.markersLayer setNeedsDisplay];
}



#pragma mark - Morph target methods

-(MorphTarget*)findMorphTargetWithAssetURL:(NSURL*)assetURL
{
    NSString* str1 = assetURL.absoluteString;
    for(ptrdiff_t i = 0; i < self.morphTargets.count; i++) {
        NSString* str2 = ((MorphTarget*)[self.morphTargets objectAtIndex:i]).assetURL.absoluteString;
        if([str1 isEqualToString:str2]) {
            return [self.morphTargets objectAtIndex:i];
        }
    }
    return nil;
}

#pragma mark - Marker layer methods

-(void)createMarkersLayer
{
    if(IS_IPAD) {
        if(self.imageView && !self.markersLayer) {
            self.markersLayer = [CALayer layer];
            self.markersLayer.frame = self.imageView.bounds;
            [self.imageView.layer addSublayer:self.markersLayer];
            self.markersLayer.delegate = self;
        }
    }
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context {
    if(IS_IPAD) {
        if(layer == self.markersLayer) {
            UIColor* markerColor = [UIColor colorWithHue:0.6 saturation:1.0 brightness:1.0 alpha:1.0];
            CGContextSetFillColorWithColor(context, markerColor.CGColor);
            for(ptrdiff_t i = 0; i < self.currentMorphTarget.markers.count; i++) {
                NSDictionary* marker = [self.currentMorphTarget.markers objectAtIndex:i];
                CGPoint point = CGPointMake([[marker valueForKey:@"x"] doubleValue], [[marker valueForKey:@"y"] doubleValue]);
                point.x = point.x/100.0*self.markersLayer.bounds.size.width;
                point.y = point.y/100.0*self.markersLayer.bounds.size.height;
                CGContextFillRect(context, CGRectMake(point.x-1.0, point.y-1.0, 3.0, 3.0));
            }
        }
    }
}

- (int)findNearestMarkerIndex:(CGPoint)point
{
    int nearest = -1;
    if(IS_IPAD)
    {
        double minDistSquared = 0.001;
        if(self.currentMorphTarget) {
            for(int i = 0; i < self.currentMorphTarget.markers.count; i++) {
                NSDictionary* marker = [self.currentMorphTarget.markers objectAtIndex:i];
                CGPoint markerPoint = CGPointMake([[marker valueForKey:@"x"] doubleValue], [[marker valueForKey:@"y"] doubleValue]);
                markerPoint.x = markerPoint.x/100;
                markerPoint.y = markerPoint.y/100;
                double distSquared = (point.x-markerPoint.x)*(point.x-markerPoint.x)+(point.y-markerPoint.y)*(point.y-markerPoint.y);
                if(distSquared < minDistSquared)
                {
                    minDistSquared = distSquared;
                    nearest = (int)i;
                }
            }
        }
    }
    return nearest;
}

-(void)removeMarkersLayer
{
    if(IS_IPAD)
    {
        [self.markersLayer removeFromSuperlayer];
        self.markersLayer=nil;
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    [self dismissViewControllerAnimated:YES completion:nil];
    UIActivityIndicatorView *activityView=[[UIActivityIndicatorView alloc]     initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityView.center=CGPointMake(self.imageView.center.x-self.imageView.frame.origin.x,self.imageView.center.y-self.imageView.frame.origin.y);
    [activityView startAnimating];
    [self.imageView addSubview:activityView];
    image = [self fixOrientation:image];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        MorphTarget* tempTarget = [self findMorphTargetWithAssetURL:[info valueForKey:UIImagePickerControllerReferenceURL]];
        if(tempTarget)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"image markers already found");
                self.currentMorphTarget = tempTarget;
                self.imageView.image = self.currentMorphTarget.image;
                [self.morphSequence addObject:self.currentMorphTarget];
                [self addNewMorphTarget:self.currentMorphTarget];
                [self removeMarkersLayer];
                [self createMarkersLayer];
                [self.markersLayer setNeedsDisplay];
                [activityView stopAnimating];
                [activityView removeFromSuperview];
                self.currentMorphSequenceIndex = self.morphSequence.count-1;
                [self.imageCollectionView reloadData];
                NSIndexPath* indexPath = [NSIndexPath indexPathForItem:self.currentMorphSequenceIndex inSection:0];
                [self.imageCollectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
            });
        }
        else
        {
            NSLog(@"try to detect facial image markers");
            NSString* errorMsg = [self tryDetectFace:image];
            dispatch_async(dispatch_get_main_queue(), ^{
                if(errorMsg)
                {
                    UIAlertView *alert = [[UIAlertView alloc]
                                          initWithTitle:@"Face Detection Error"
                                          message:errorMsg
                                          delegate:nil
                                          cancelButtonTitle:@"OK!"
                                          otherButtonTitles:nil];
                    [alert show];
                }
                else
                {
                    if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0)) {
                        // retina display
                        self.currentMorphTarget.image = [ImageUtils resizeImage:image scale:2.0 newSize:CGSizeMake(1024, 1024)];
                    }
                    else
                    {
                        // non-retina display
                        self.currentMorphTarget.image = [ImageUtils resizeImage:image scale:1.0 newSize:CGSizeMake(1024, 1024)];
                    }
                    if(picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
                        [self addFaceImageToAlbum:image toAlbum:@"MorphUs"];
                    }
                    else {
                        self.currentMorphTarget.assetURL = [info valueForKey:UIImagePickerControllerReferenceURL];
                    }
                    self.imageView.image = self.currentMorphTarget.image;
                    [self.morphSequence addObject:self.currentMorphTarget];
                    [self addNewMorphTarget:self.currentMorphTarget];
                    [self removeMarkersLayer];
                    [self createMarkersLayer];
                    [self.markersLayer setNeedsDisplay];
                    [self.imageCollectionView reloadData];
                    self.currentMorphSequenceIndex = self.morphSequence.count-1;
                    NSIndexPath* indexPath = [NSIndexPath indexPathForItem:self.currentMorphSequenceIndex inSection:0];
                    [self.imageCollectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
                }
                [activityView stopAnimating];
                [activityView removeFromSuperview];

            });
        }
    });
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - core data methods for morph targets

- (void)addNewMorphTarget:(MorphTarget*)morphTarget
{
    // Create entity
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"MorphTarget" inManagedObjectContext:self.managedObjectContext];
    
    // Initialize record
    NSManagedObject* record = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
    
    // Populate record
    NSString* imageURL = [morphTarget.assetURL absoluteString];
    [record setValue:imageURL forKey:@"imageURL"];
    [record setValue:self.managedObject forKey:@"project"];
    
    // Connect to project
    NSMutableOrderedSet* targetSet = [self.managedObject valueForKey:@"morphTargets"];
    [targetSet addObject:record];
    [self.managedObject setValue:targetSet forKey:@"morphTargets"];
    
    // Add Markers
    NSManagedObject* target = [targetSet lastObject];
    // Create entity
    entity = [NSEntityDescription entityForName:@"Marker" inManagedObjectContext:self.managedObjectContext];
    NSMutableOrderedSet* markerSet = [[NSMutableOrderedSet alloc] init];
    for(ptrdiff_t i = 0; i < landmarkKeyNames.count; i++)
    {
        // Initialize record
        record = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
        NSString* name = [self.landmarkKeyNames objectAtIndex:i];
        NSDictionary* marker = [self.currentMorphTarget.markers objectAtIndex:i];
        [record setValue:name forKey:@"name"];
        NSNumber* xVal = [marker valueForKey:@"x"];
        NSNumber* yVal = [marker valueForKey:@"y"];
        [record setValue:xVal forKey:@"x"];
        [record setValue:yVal forKey:@"y"];
        [markerSet addObject:record];
        // Connect marker to target
        [record setValue:target forKey:@"morphTarget"];
    }
    // Connect target to markers
    [target setValue:markerSet forKey:@"markers"];
    
    // Save record
    NSError *error = nil;
    
    if (![self.managedObjectContext save:&error]) {
        if (error) {
            NSLog(@"Unable to save record.");
            NSLog(@"%@, %@", error, error.localizedDescription);
        }
        
        // Show Alert View
        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Morph target could not be saved." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

- (void)loadMorphTargetsForProject
{
    NSSet* targetSet = [self.managedObject valueForKey:@"morphTargets"];
    if(targetSet.count == 0)
        return;
    __weak MorphViewController* weakSelf = self;

    __block UIActivityIndicatorView* activityView=[[UIActivityIndicatorView alloc]     initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityView.center=CGPointMake(self.imageView.center.x-self.imageView.frame.origin.x,self.imageView.center.y-self.imageView.frame.origin.y);
    [activityView startAnimating];
    [self.imageView addSubview:activityView];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block int index = 0;
        [targetSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            NSManagedObject* record = obj;
            NSString* imageURL = [record valueForKey:@"imageURL"];
            NSURL* assetURL = [NSURL URLWithString:imageURL];
            [weakSelf loadImageFromAssetUrl:assetURL completionBlock:^(UIImage* image, NSError* error) {
                if(error)
                {
                    NSLog(@"Can't find image - %@",[error localizedDescription]);
                }
                else
                {
                    MorphTarget* target = [weakSelf findMorphTargetWithAssetURL:assetURL];
                    if(!target)
                    {
                        target = [[MorphTarget alloc] init];
                        [weakSelf.morphTargets addObject:target];
                    }
                    if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0)) {
                        // retina display
                        target.image = [ImageUtils resizeImage:image scale:2.0 newSize:CGSizeMake(1024, 1024)];
                    }
                    else
                    {
                        // non-retina display
                        target.image = [ImageUtils resizeImage:image scale:1.0 newSize:CGSizeMake(1024, 1024)];
                    }
                    [weakSelf.morphSequence addObject:target];
                    weakSelf.currentMorphSequenceIndex = weakSelf.morphSequence.count-1;
                    NSSet* markerSet = [record valueForKey:@"markers"];
                    target.markers = [[NSMutableArray alloc] init];
                    [markerSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                        NSManagedObject* record = obj;
                        NSNumber* xVal = [record valueForKey:@"x"];
                        NSNumber* yVal = [record valueForKey:@"y"];
                        [target.markers addObject:[[NSDictionary alloc]
                                                   initWithObjects:[NSArray arrayWithObjects:xVal, yVal, nil]
                                                   forKeys:[NSArray arrayWithObjects:@"x", @"y", nil]]];
                        
                    }];
                    if(index == targetSet.count-1)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            weakSelf.imageView.image = ((MorphTarget*)[weakSelf.morphSequence firstObject]).image;
                            [weakSelf.imageCollectionView reloadData];
                            NSIndexPath* indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
                            [weakSelf.imageCollectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
                            [activityView stopAnimating];
                            [activityView removeFromSuperview];
                            [weakSelf redrawImageViewForTarget:weakSelf.morphSequence[0]];
                        });
                    }
                    index++;
                }
            }];
        }];
    });
}

#pragma mark - collection view methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.morphSequence.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* cellId = @"photoCell";
    ImageCollectionViewCell* cell = (ImageCollectionViewCell*) [collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:indexPath];
    if(indexPath.section == 0) {
        cell.imageView.image = ((MorphTarget*) self.morphSequence[indexPath.item]).image;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0) {
        UICollectionViewCell* cell = [self.imageCollectionView cellForItemAtIndexPath:indexPath];
        [cell setSelected:YES];
        self.imageView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
        [self.imageCollectionView scrollToItemAtIndexPath:indexPath
                                         atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                 animated:YES];
        [self redrawImageViewForTarget:self.morphSequence[indexPath.item]];
        self.currentMorphSequenceIndex = indexPath.item;
    }
}

-(NSString*)makeStringPretty:(NSString*)inStr
{
    NSString* outStr = [[NSMutableString alloc] init];
    NSArray* parts = [inStr componentsSeparatedByString:@"_"];
    for(ptrdiff_t i = 0; i < parts.count; i++) {
        NSString* part = [(NSString*)[parts objectAtIndex:i] capitalizedString];
        outStr = [outStr stringByAppendingString:part];
        if(i != parts.count-1) {
            outStr = [outStr stringByAppendingString:@" "];
        }
    }
    return outStr;
}

#pragma mark - ui actions

- (IBAction)handlePinch:(id)sender {
    UIPinchGestureRecognizer* recognizer = (UIPinchGestureRecognizer*)sender;
    if(recognizer.scale < 1 && (recognizer.view.frame.size.width <= self.view.frame.size.width || recognizer.view.frame.size.height <= self.view.frame.size.height)) {
        recognizer.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
    }
    else {
        recognizer.view.transform = CGAffineTransformScale(recognizer.view.transform, recognizer.scale, recognizer.scale);
    }
    recognizer.scale = 1;
    [self removeMarkersLayer];
    [self createMarkersLayer];
    [self.markersLayer setNeedsDisplay];
    self.activeMarkerIndex = -1;
}

- (IBAction)handlePan:(id)sender {
    UIPanGestureRecognizer* recognizer = (UIPanGestureRecognizer *)sender;
    if(recognizer.numberOfTouches == 2) {
        CGPoint translation = [recognizer translationInView:self.view];
        recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                         recognizer.view.center.y + translation.y);
        int originX = recognizer.view.frame.origin.x;
        int originY = recognizer.view.frame.origin.y;
        int width = recognizer.view.frame.size.width;
        int height = recognizer.view.frame.size.height;
        if(originX > 0)
            originX = 0;
        if(originY > 0)
            originY = 0;
        if(originX + width <= self.view.frame.size.width)
            originX = self.view.frame.size.width - width;
        if(originY + height <= self.view.frame.size.height)
            originY = self.view.frame.size.height - height;
        recognizer.view.frame = CGRectMake(originX, originY, width, height);
        [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
        [self removeMarkersLayer];
        [self createMarkersLayer];
        [self.markersLayer setNeedsDisplay];
        self.activeMarkerIndex = -1;
    }
}

- (IBAction)handleLongTouch:(id)sender {
    UILongPressGestureRecognizer* recognizer = (UILongPressGestureRecognizer*)sender;
    if(recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [recognizer locationOfTouch:0 inView:self.view];
        point.x = (point.x-recognizer.view.frame.origin.x)/recognizer.view.frame.size.width;
        point.y = (point.y-recognizer.view.frame.origin.y)/recognizer.view.frame.size.height;
        self.activeMarkerIndex = [self findNearestMarkerIndex:point];
        if(self.activeMarkerIndex > 0) {
            NSLog(@"Began touch near marker %d", (int)self.activeMarkerIndex);
        }
        if(self.activeMarkerIndex >= 0)
        {
            self.activeMarkerLabel.text = [NSString stringWithFormat:@"Selected: %@", [self makeStringPretty:self.landmarkKeyNames[self.activeMarkerIndex]]];
        }
    }
    else if(recognizer.state == UIGestureRecognizerStateEnded)
    {
        NSLog(@"Touch ended");
        self.activeMarkerIndex = -1;
        self.activeMarkerLabel.text = @"";
    }
    else
    {
        CGPoint point = [recognizer locationOfTouch:0 inView:self.view];
        point.x = (point.x-recognizer.view.frame.origin.x)/recognizer.view.frame.size.width;
        point.y = (point.y-recognizer.view.frame.origin.y)/recognizer.view.frame.size.height;
        if(self.activeMarkerIndex != -1) {
            NSLog(@"Move marker %d to %g, %g", (int)self.activeMarkerIndex, point.x, point.y);
            NSNumber* x = [NSNumber numberWithDouble:(point.x*100)];
            NSNumber* y = [NSNumber numberWithDouble:(point.y*100)];
            NSDictionary* markerPoint = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:x, y, nil] forKeys:[NSArray arrayWithObjects:@"x", @"y", nil]];
            self.currentMorphTarget.markers[self.activeMarkerIndex] = markerPoint;
            [self.markersLayer setNeedsDisplay];
        }
    }
}

- (IBAction)selectProject:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)choosePhoto:(id)sender
{
    choosePhotoActionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Face Photo" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"From Camera", @"From Photo Library", nil];
    [choosePhotoActionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(actionSheet == choosePhotoActionSheet)
    {
        switch (buttonIndex)
        {
            case 0:
                [self pickPhotoFromCamera];
                break;
            case 1:
                [self pickPhotoFromLibrary];
                break;
            default:
                break;
        }
    }
}

- (void)pickPhotoFromCamera
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imageView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
        imagePicker.delegate = self;
        imagePicker.modalPresentationStyle = UIModalPresentationCurrentContext;
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:imagePicker animated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Error"
                              message:@"Failed to access camera"
                              delegate:nil
                              cancelButtonTitle:@"OK!"
                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)pickPhotoFromLibrary
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        self.imageView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
        imagePicker.delegate = self;
        imagePicker.modalPresentationStyle = UIModalPresentationCurrentContext;
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Error"
                              message:@"Failed to access photo library"
                              delegate:nil
                              cancelButtonTitle:@"OK!"
                              otherButtonTitles:nil];
        [alert show];
    }
}

- (IBAction)remove:(id)sender {
    int index = (int)self.currentMorphSequenceIndex-1;
    if(index >= 0)
    {
        [self.morphSequence removeObjectAtIndex:self.currentMorphSequenceIndex];
        NSIndexPath* indexPath = [NSIndexPath indexPathForItem:self.currentMorphSequenceIndex inSection:0];
        UICollectionViewCell* cell = [self.imageCollectionView cellForItemAtIndexPath:indexPath];
        [cell removeFromSuperview];
        [self.imageCollectionView reloadData];
        indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        [self.imageCollectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
        self.imageView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
        [self redrawImageViewForTarget:self.morphSequence[index]];
        self.currentMorphSequenceIndex = index;
    }
    else if(index == -1)
    {
        [self.morphSequence removeObjectAtIndex:self.currentMorphSequenceIndex];
        NSIndexPath* indexPath = [NSIndexPath indexPathForItem:self.currentMorphSequenceIndex inSection:0];
        UICollectionViewCell* cell = [self.imageCollectionView cellForItemAtIndexPath:indexPath];
        [cell removeFromSuperview];
        [self.imageCollectionView reloadData];
        self.currentMorphSequenceIndex = index;
        [self removeMarkersLayer];
        self.imageView.image = nil;
        [self.imageCollectionView reloadData];
        if(self.morphSequence.count > 0)
        {
            indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
            [self.imageCollectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
            self.imageView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
            [self redrawImageViewForTarget:self.morphSequence[0]];
            self.currentMorphSequenceIndex = 0;
        }
    }
}


 #pragma mark - Navigation
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if([identifier  isEqual: @"Help"]) {
        return YES;
    }
    else if(self.morphSequence.count >= 2) {
        self.actionIdentifier = identifier;
        return YES;
    }
    else {
        NSString* message = nil;
        if([identifier  isEqual: @"Play"]) {
            message = @"You need at least two morph targets to perform playback";
        }
        else if([identifier  isEqual: @"Export"]) {
            message = @"You need at least two morph targets to export movie";
        }
        if(message != nil) {
            UIAlertView* alert = [[UIAlertView alloc]
                                  initWithTitle:@"Oops"
                                  message:message
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alert show];
        }
        return NO;
    }
}

 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
     UIBarButtonItem* senderBtn = (UIBarButtonItem*)sender;
     if(senderBtn.tag != 4) // 4 is help button
     {
         self.imageView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
         [self redrawImageViewForTarget:self.morphSequence[self.currentMorphSequenceIndex]];
         GLKMorphViewController* vc = (GLKMorphViewController*)[segue destinationViewController];
         vc.morphSequence = self.morphSequence;
         vc.morphTargets = self.morphTargets;
         vc.actionIdentifier = self.actionIdentifier;
         vc.movieURL = self.movieURL;
     }
 }

@end
