//
//  DataSource.h
//  LocalVocal
//
//  Created by Chris Slowik on 1/26/15.
//  Copyright (c) 2015 Chris Slowik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <JSQMessages.h>
#import <UICKeyChainStore.h>
#import "User.h"

#define kSaveFileName @"LVdata"

typedef NS_ENUM(NSInteger, LVNotifyType) {
    Message       = 0,
    Photo         = 1
};

@interface DataSource : NSObject

@property (strong, nonatomic) NSMutableArray *blockList;       // peer IDs
@property (strong, nonatomic) NSMutableArray *conversationPreviews;
@property (strong, nonatomic) NSMutableArray *blockedConversations;
@property (strong, nonatomic) NSMutableDictionary *transcripts;
@property (strong, nonatomic) User *user;               // the user's info

@property (strong, nonatomic) MCPeerID *peerID;
@property (strong, nonatomic) MCSession *session;
@property (strong, nonatomic) MCNearbyServiceAdvertiser *advertiser;
@property (strong, nonatomic) MCNearbyServiceBrowser *browser;
@property (strong, nonatomic) NSMutableDictionary *connectedPeers;
@property (strong, nonatomic) User *connectedPeer;
@property (strong, nonatomic) NSMutableArray *nearbyPeers;  // for tableview data source 

+ (instancetype) sharedInstance;

- (void) stopServices;
- (void) startServices;

- (void) sendMessage:(JSQMessage *)message toPeer:(MCPeerID *)peer;

- (void) blockUser:(MCPeerID *)user;
- (void) unblockUser:(MCPeerID *)user;

- (void) saveUser;

- (void) cleanUp;

@end
