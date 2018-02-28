//
//  MorphSettingsTableViewController.m
//  MorphUs
//
//  Created by Dan Shepherd on 14/07/2015.
//  Copyright (c) 2015 cuffedtothekeyboard. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreFoundation/CFDictionary.h>
#import <MediaPlayer/MediaPlayer.h>
#import "AppDelegate.h"
#import "MorphSettingsTableViewController.h"

#define YOUR_APP_STORE_ID 898392944

static NSString *const iOS7AppStoreURLFormat = @"itms-apps://itunes.apple.com/app/id%d";
static NSString *const iOSAppStoreURLFormat = @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%d";

@interface MorphSettingsTableViewController ()

@end

@implementation MorphSettingsTableViewController
@synthesize managedObjectContext;
@synthesize managedObject;
@synthesize hasVideo;
@synthesize videoImageView;
@synthesize videoLabel;
@synthesize videoAssetURL;
@synthesize videoImage;
@synthesize playButtonImageView;

- (void)viewDidLoad {
    [super viewDidLoad];
    assert(self.managedObjectContext != nil);
    assert(self.managedObject != nil);
    // update the name field
    [self.nameTextField setText:[self.managedObject valueForKey:@"name"]];
    [self.nameTextField setDelegate:self];
    // determine if a video exists for this project
    NSManagedObject* record = [self.managedObject valueForKey:@"morphSettings"];
    NSString* videoURL = [record valueForKey:@"videoURL"];
    if(videoURL)
    {
        videoAssetURL = [NSURL URLWithString:videoURL];
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoAssetURL options:nil];
        AVAssetImageGenerator* imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        Float64 durationSeconds = CMTimeGetSeconds([asset duration]);
        CMTime midpoint = CMTimeMakeWithSeconds(durationSeconds/2.0, 600);
        NSError *error;
        CMTime actualTime;
        CGImageRef halfWayImage = [imageGenerator copyCGImageAtTime:midpoint actualTime:&actualTime error:&error];
        if (error == nil) {
            self.hasVideo = YES;
            self.playButtonImageView.hidden = NO;
            videoImage = [UIImage imageWithCGImage:halfWayImage];
            CGImageRelease(halfWayImage);
        }
        else {
            NSLog(@"Error: %@", error.localizedDescription);
            self.hasVideo = NO;
            self.playButtonImageView.hidden = YES;
        }
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark button actions

- (IBAction)onDone:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)onRate:(id)sender {
    NSURL* rateURL = [NSURL URLWithString:[NSString stringWithFormat:([[UIDevice currentDevice].systemVersion floatValue] >= 7.0f) ? iOS7AppStoreURLFormat : iOSAppStoreURLFormat, YOUR_APP_STORE_ID]];
    [[UIApplication sharedApplication] openURL:rateURL];
}

- (IBAction)onShare:(id)sender {
    if(videoAssetURL)
    {
        NSArray* shareItems = @[videoAssetURL];
        UIActivityViewController* activityViewController = [[UIActivityViewController alloc] initWithActivityItems:shareItems applicationActivities:nil];
        [activityViewController.popoverPresentationController setSourceView:sender];
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
}

#pragma mark - Table view data source/delegates

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    NSManagedObject* record = [self.managedObject valueForKey:@"morphSettings"];
    if(record == nil)
    {
        // create new morph settings record
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"MorphSettings" inManagedObjectContext:self.managedObjectContext];
        record = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
        // connect to morph project
        [self.managedObject setValue:record forKey:@"morphSettings"];
        [record setValue:self.managedObject forKey:@"project"];
        [self saveSettings];
    }

    switch (indexPath.section)
    {
        case VideoSection:
            videoLabel.hidden = hasVideo;
            self.playButtonImageView.hidden = !hasVideo;
            [self.shareButton setEnabled:hasVideo];
            if(hasVideo)
            {
                self.videoImageView.image = videoImage;
            }
            break;
        case ExportSettingsSection:
            switch (indexPath.row)
        {
            case FramesPerTransitionRow:
                [cell.textLabel setText:[NSString stringWithFormat:@"%d frames per transition", [[record valueForKey:@"framesPerTransition"] intValue]]];
                break;
            case FramesPerSecondRow:
                [cell.textLabel setText:[NSString stringWithFormat:@"%d frames per second", [[record valueForKey:@"framesPerSecond"] intValue]]];
                break;
            default:
                break;
        }
            break;
        default:
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case NameSection:
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        case VideoSection:
            if(hasVideo)
                [self playVideo];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        case ExportSettingsSection:
            switch (indexPath.row)
        {
            case FramesPerTransitionRow:
                [self selectFramesPerTransition];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                break;
            case FramesPerSecondRow:
                [self selectFramesPerSecond];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                break;
            default:
                break;
        }
            break;
        default:
            break;
    }
}

- (void)selectFramesPerTransition
{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Select frames per transition" message:@"Please select the number of frames per you would like per morph transition" preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"15 FPT" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self setFPT:[NSNumber numberWithInt:15]];
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"30 FPT" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self setFPT:[NSNumber numberWithInt:30]];
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"60 FPT" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self setFPT:[NSNumber numberWithInt:60]];
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"90 FPT" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self setFPT:[NSNumber numberWithInt:90]];
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"120 FPT" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self setFPT:[NSNumber numberWithInt:120]];
    }]];
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)selectFramesPerSecond
{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Select frames per second" message:@"Please select the number of frames per second you would like for video playback" preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"15 FPS" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self setFPS:[NSNumber numberWithInt:15]];
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"30 FPS" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self setFPS:[NSNumber numberWithInt:30]];
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"60 FPS" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self setFPS:[NSNumber numberWithInt:60]];
    }]];
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)setFPT:(NSNumber*)fpt {
    // update data model
    NSManagedObject* record = [self.managedObject valueForKey:@"morphSettings"];
    [record setValue:fpt forKey:@"framesPerTransition"];
    [self saveSettings];
    
    // update settings cell
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:FramesPerTransitionRow inSection:ExportSettingsSection];
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [cell.textLabel setText:[NSString stringWithFormat:@"%d frames per transition", [fpt intValue]]];
}

- (void)setFPS:(NSNumber*)fps {
    // update data model
    NSManagedObject* record = [self.managedObject valueForKey:@"morphSettings"];
    [record setValue:fps forKey:@"framesPerSecond"];
    [self saveSettings];
    
    // update settings cell
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:FramesPerSecondRow inSection:ExportSettingsSection];
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [cell.textLabel setText:[NSString stringWithFormat:@"%d frames per second", [fps intValue]]];
}

- (void)saveSettings
{
    NSError* error = nil;
    if (![self.managedObjectContext save:&error]) {
        
        if (error) {
            NSLog(@"Unable to save record.");
            NSLog(@"%@, %@", error, error.localizedDescription);
        }
    
        // Show Alert View
        [self showWarningAlert:@"Unable to save settings."];
    }
}

- (void)showWarningAlert:(NSString*)message {
    UIAlertController* alert = [UIAlertController
                                alertControllerWithTitle:@"Warning"
                                message:message
                                preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"OK!"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action) {
                         }];
    
    
    [alert addAction:ok];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - text field delegates

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self.managedObject setValue:textField.text forKey:@"name"];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - video player
- (void)playVideo
{

    MPMoviePlayerViewController* player = [[MPMoviePlayerViewController alloc] initWithContentURL:videoAssetURL];
    
    [self presentMoviePlayerViewControllerAnimated:player];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoDidStopPlaying:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification object:player];
}

- (void)videoDidStopPlaying:(id)sender
{
    
}

@end
