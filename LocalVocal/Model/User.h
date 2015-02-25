//
//  User.h
//  LocalVocal
//
//  Created by Chris Slowik on 1/15/15.
//  Copyright (c) 2015 Chris Slowik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

/*!
 @class User
 @abstract
 The basic user model for LocalVocal. Contains an avatar image, username, and peer ID for the user.
 
 @discussion
 No comment
 */

@interface User : NSObject <NSCoding>

@property (strong, nonatomic) UIImage *avatar;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) MCPeerID *peerID;

@end
