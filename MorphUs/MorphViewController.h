//
//  MorphViewController.h
//  MorphUs
//
//  Created by Dan Shepherd on 01/07/2014.
//  Copyright (c) 2014 cuffedtothekeyboard. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <WatchConnectivity/WatchConnectivity.h>
#import <Photos/Photos.h>

#import "FaceDetection.h"
#import "MorphTarget.h"

@interface MorphViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, WCSessionDelegate, CALayerDelegate>
{
    UIImagePickerController* imagePicker;
}
typedef void(^LoadImageCompletionBlock)(UIImage*, NSError*);

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObject* managedObject;
@property (weak, nonatomic) FaceDetection* faceDetection;
@property (strong, nonatomic) PHAssetCollection* assetCollection;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) NSArray* landmarkKeyNames;
@property (strong, nonatomic) CALayer* markersLayer;
@property (weak, nonatomic) MorphTarget* currentMorphTarget;
@property (strong, nonatomic) NSMutableArray* morphTargets;
@property (strong, nonatomic) NSMutableArray* morphSequence;
@property (weak, nonatomic) IBOutlet UICollectionView* imageCollectionView;
@property NSInteger currentMorphSequenceIndex;
@property NSInteger activeMarkerIndex;
@property (weak, nonatomic) IBOutlet UILabel *activeMarkerLabel;
@property (strong, nonatomic) NSURL* movieURL;
@property (strong, nonatomic) NSString* actionIdentifier;

- (IBAction)selectProject:(id)sender;
- (IBAction)choosePhoto:(id)sender;
- (IBAction)handlePinch:(id)sender;
- (IBAction)handlePan:(id)sender;
- (IBAction)handleLongTouch:(id)sender;
- (IBAction)remove:(id)sender;
- (IBAction)onExport:(id)sender;


@end
