//
//  ConversationTableViewCell.m
//  LocalVocal
//
//  Created by Chris Slowik on 2/17/15.
//  Copyright (c) 2015 Chris Slowik. All rights reserved.
//

#import "ConversationTableViewCell.h"

@implementation ConversationTableViewCell

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

@end
