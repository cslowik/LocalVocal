//
//  ConversationTableViewCell.h
//  LocalVocal
//
//  Created by Chris Slowik on 2/17/15.
//  Copyright (c) 2015 Chris Slowik. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SWTableViewCell.h>

@interface ConversationTableViewCell : SWTableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatarImage;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UITextView *previewLabel;
@property (weak, nonatomic) IBOutlet UIImageView *redactedTextImage;
@property (weak, nonatomic) IBOutlet UIImageView *onlineIndicator;

@end
