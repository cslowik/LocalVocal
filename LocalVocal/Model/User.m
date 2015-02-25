//
//  User.m
//  LocalVocal
//
//  Created by Chris Slowik on 1/15/15.
//  Copyright (c) 2015 Chris Slowik. All rights reserved.
//

#import "User.h"

@implementation User

- (id) init {
    self = [super init];
    
    return self;
}

- (id) initWithPeerID:(MCPeerID *)peerID username:(NSString *)username avatar:(UIImage *)avatar {
    self = [super init];
    
    if (self) {
        self.peerID = peerID;
        self.username = username;
        self.avatar = avatar;
    }
    
    return self;
}

#pragma mark - NSCoding

#define kPeerID     @"peerID"
#define kUsername   @"username"
#define kAvatar     @"avatar"

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.peerID forKey:kPeerID];;
    [aCoder encodeObject:self.username forKey:kUsername];
    [aCoder encodeObject:self.avatar forKey:kAvatar];
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    MCPeerID *peerID = [aDecoder decodeObjectForKey:kPeerID];
    NSString *username = [aDecoder decodeObjectForKey:kUsername];
    UIImage *avatar = [aDecoder decodeObjectForKey:kAvatar];
    
    return [self initWithPeerID:peerID username:username avatar:avatar];
}

@end
