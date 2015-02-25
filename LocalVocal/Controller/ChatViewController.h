//
//  ChatViewController.h
//  LocalVocal
//
//  Created by Chris Slowik on 2/10/15.
//  Copyright (c) 2015 Chris Slowik. All rights reserved.
//

#import "JSQMessages.h"
#import "DataSource.h"


@interface ChatViewController : JSQMessagesViewController

@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;

@property (strong, nonatomic) MCPeerID *peerID;
@property (strong, nonatomic) MCPeerID *otherPeerID;
@property (strong, nonatomic) User *otherUser;

@property (strong, nonatomic) NSString *username;

@property (strong, nonatomic) NSMutableArray *messages;

@end
