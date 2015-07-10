//
//  ImageCollectionViewCell.m
//  MorphUs
//
//  Created by Dan Shepherd on 03/07/2014.
//  Copyright (c) 2014 cuffedtothekeyboard. All rights reserved.
//

#import "ImageCollectionViewCell.h"

@implementation ImageCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    if (selected) {
        self.contentView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:1.0];
    } else {
        self.contentView.backgroundColor = nil;
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
