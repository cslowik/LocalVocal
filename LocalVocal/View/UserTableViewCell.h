//
//  UserTableViewCell.h
//  LocalVocal
//
//  Created by Chris Slowik on 2/10/15.
//  Copyright (c) 2015 Chris Slowik. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface UserTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImage;

@property (assign, nonatomic) IBInspectable CGFloat avatarCornerRadius;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *marginConstraint;

@end
