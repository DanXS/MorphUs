//
//  ProjectsTableViewCell.m
//  MorphUs
//
//  Created by Dan Shepherd on 12/07/2015.
//  Copyright (c) 2015 cuffedtothekeyboard. All rights reserved.
//

#import "ProjectsTableViewCell.h"

@implementation ProjectsTableViewCell
@synthesize name;
@synthesize created;
@synthesize thumbImageView;

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
    if(selected)
    {
        [self.thumbImageView setAlpha:0.5];
        [self.name setTextColor:[UIColor blackColor]];
        [self.created setTextColor:[UIColor blackColor]];
    }
    else
    {
        [self.thumbImageView setAlpha:1.0];
        [self.name setTextColor:[UIColor whiteColor]];
        [self.created setTextColor:[UIColor whiteColor]];
    }
}

@end
