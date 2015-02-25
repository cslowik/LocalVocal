//
//  UserTableViewCell.m
//  LocalVocal
//
//  Created by Chris Slowik on 2/10/15.
//  Copyright (c) 2015 Chris Slowik. All rights reserved.
//

#import "UserTableViewCell.h"

@implementation UserTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Layout Stuff

- (void) layoutSubviews {
    [super layoutSubviews];
    
    // set up the rounded corners
    self.avatarImage.layer.cornerRadius = self.avatarImage.frame.size.height / 2;
    self.avatarImage.clipsToBounds = YES;
}

#pragma mark - Properties

- (void) setCornerRadius:(CGFloat)cornerRadius {
    _avatarCornerRadius = cornerRadius;
    self.avatarImage.layer.cornerRadius = cornerRadius;
}

@end
