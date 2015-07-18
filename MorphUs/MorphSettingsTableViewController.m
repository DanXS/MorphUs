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
#import "MorphSettingsTableViewController.h"


@interface MorphSettingsTableViewController ()

@end

@implementation MorphSettingsTableViewController
@synthesize managedObjectContext;
@synthesize managedObject;
@synthesize framesPerTransitionActionSheet;
@synthesize framesPerSecondActionSheet;
@synthesize hasVideo;
@synthesize videoImageView;
@synthesize videoLabel;
@synthesize videoAssetURL;
@synthesize videoImage;

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
        hasVideo = YES;
        videoAssetURL = [NSURL URLWithString:videoURL];
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoAssetURL options:nil];
        AVAssetImageGenerator* imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        Float64 durationSeconds = CMTimeGetSeconds([asset duration]);
        CMTime midpoint = CMTimeMakeWithSeconds(durationSeconds/2.0, 600);
        NSError *error;
        CMTime actualTime;
        CGImageRef halfWayImage = [imageGenerator copyCGImageAtTime:midpoint actualTime:&actualTime error:&error];
        videoImage = [UIImage imageWithCGImage:halfWayImage];
        CGImageRelease(halfWayImage);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


- (IBAction)onDone:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

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
        {
            videoLabel.hidden = hasVideo;
            if(hasVideo)
            {
                self.videoImageView.image = videoImage;
            }
            break;
        }
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
            switch (indexPath.row)
        {
            case NameRow:
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                break;
            default:
                break;
        }
            break;
        case VideoSection:
            switch (indexPath.row)
        {
            case VideoRow:
                if(hasVideo)
                    [self playVideo];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                break;
            default:
                break;
        }
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
    framesPerTransitionActionSheet = [[UIActionSheet alloc] initWithTitle:@"Select frames per transition" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"15 frames", @"30 frames", @"60 frames", @"90 frames", @"120 frames", nil];
    [framesPerTransitionActionSheet showInView:self.view];
}

- (void)selectFramesPerSecond
{
    framesPerSecondActionSheet = [[UIActionSheet alloc] initWithTitle:@"Select per second" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"15 frames", @"30 frames", @"60 frames", nil];
    [framesPerSecondActionSheet showInView:self.view];
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(actionSheet == framesPerTransitionActionSheet)
    {
        NSArray* frames = @[[NSNumber numberWithInteger:15],
                           [NSNumber numberWithInteger:30],
                           [NSNumber numberWithInteger:60],
                           [NSNumber numberWithInteger:90],
                           [NSNumber numberWithInteger:120]];
        if(buttonIndex < 0 || buttonIndex >= frames.count)
            return;
        NSNumber* selected = [frames objectAtIndex:buttonIndex];
        
        // update data model
        NSManagedObject* record = [self.managedObject valueForKey:@"morphSettings"];
        [record setValue:selected forKey:@"framesPerTransition"];
        [self saveSettings];
        
        // update settings cell
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:FramesPerTransitionRow inSection:ExportSettingsSection];
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [cell.textLabel setText:[NSString stringWithFormat:@"%d frames per transition", [selected intValue]]];
    }
    else if(actionSheet == framesPerSecondActionSheet)
    {
        NSArray* frames = @[[NSNumber numberWithInteger:15],
                            [NSNumber numberWithInteger:30],
                            [NSNumber numberWithInteger:60]];
        if(buttonIndex < 0 || buttonIndex >= frames.count)
            return;
        NSNumber* selected = [frames objectAtIndex:buttonIndex];
        
        // update data model
        NSManagedObject* record = [self.managedObject valueForKey:@"morphSettings"];
        [record setValue:selected forKey:@"framesPerSecond"];
        [self saveSettings];
        
        // update settings cell
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:FramesPerSecondRow inSection:ExportSettingsSection];
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [cell.textLabel setText:[NSString stringWithFormat:@"%d frames per second", [selected intValue]]];

    }
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
        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Unable to save settings." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end