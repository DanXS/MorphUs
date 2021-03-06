//
//  MorphSettingsTableViewController.h
//  MorphUs
//
//  Created by Dan Shepherd on 14/07/2015.
//  Copyright (c) 2015 cuffedtothekeyboard. All rights reserved.
//

#import <UIKit/UIKit.h>

enum
{
    NameSection = 0,
    VideoSection,
    ExportSettingsSection
};

enum
{
    FramesPerTransitionRow = 0,
    FramesPerSecondRow
};

@interface MorphSettingsTableViewController : UITableViewController <UITextFieldDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObject* managedObject;
@property (assign, atomic) BOOL hasVideo;
@property (strong, nonatomic) NSURL* videoAssetURL;
@property (strong, nonatomic) UIImage* videoImage;

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UIImageView *videoImageView;
@property (weak, nonatomic) IBOutlet UIImageView *playButtonImageView;
@property (weak, nonatomic) IBOutlet UILabel *videoLabel;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;

- (IBAction)onDone:(id)sender;
- (IBAction)onRate:(id)sender;
- (IBAction)onShare:(id)sender;

@end
