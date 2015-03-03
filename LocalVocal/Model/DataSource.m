//
//  DataSource.m
//  LocalVocal
//
//  Created by Chris Slowik on 1/26/15.
//  Copyright (c) 2015 Chris Slowik. All rights reserved.
//

#import "DataSource.h"
#import "User.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

#define kUser @"savedUser"                      // user file name
#define kConversations @"conversations"         // conversation list file name
#define kTranscripts @"transcripts"             // full chat transcripts
#define kBlockedUsers @"blockedUsers"           // blocked user list
#define kBlockedConversations @"blockedConversations"

#define kServiceType @"lv-messenger"            // service type string

@interface DataSource () <MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate>


@end

@implementation DataSource

+ (instancetype) sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype) init {
    self = [super init];
    
    if (self) {
        self.connectedPeers = [@{} mutableCopy];
        self.nearbyPeers = [[NSMutableArray alloc] initWithCapacity:1];
        // check for saved user info and block list
        [self loadUser];
        [self loadBlockList];
        
        // read conversations and previews from saved data
        self.conversationPreviews = [NSMutableArray new];
        self.blockedConversations = [NSMutableArray new];
        [self loadConversationList];
        [self loadBlockedConversationList];
        
        self.transcripts = [@{} mutableCopy];
        [self loadTranscripts];
        
        [self generatePeer];
        
        // create browser based on peer name
        self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID
                                                        serviceType:kServiceType];
        
        // create advertiser based on peer name
        self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID
                                                            discoveryInfo:nil                 // no info needed really
                                                              serviceType:kServiceType];
        
        self.advertiser.delegate = self;
        self.browser.delegate = self;
        
        [self stopServices];
        
        // register for notifications the DS needs to know about
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserInfo) name:@"userInfoUpdated" object:nil];
        
    }
    
    return self;
}

#pragma mark - Memory management

- (void)dealloc
{
    // Unregister for notifications on deallocation.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Nil out delegates
    _advertiser.delegate = nil;
    _browser.delegate = nil;
}

#pragma mark - User Management

- (void) blockUser:(MCPeerID *)user {
    // add peer id to block list
    if (self.blockList == nil) {
        self.blockList = [@[user] mutableCopy];
    } else {
        [self.blockList insertObject:user atIndex:0];
    }
    [self saveBlockList];
    [self saveBlockedConversationList];
    [self saveConversationList];
}

- (void) unblockUser:(MCPeerID *)user {
    [self.blockList enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        MCPeerID *blockUser = (MCPeerID *)obj;
        if (blockUser.displayName == user.displayName) {
            [self.blockList removeObject:obj];
        }
    }];
    
    [self saveBlockList];
    [self saveBlockedConversationList];
    [self saveConversationList];
}

#pragma mark - MC setup
- (void) generatePeer {
    // check keychain for unique identifier, if not there create one
    NSString *deviceIdentifier = [UICKeyChainStore stringForKey:@"deviceIdentifier"];
    if (!deviceIdentifier) {
        NSString *deviceString = [[NSUUID UUID] UUIDString];
        [UICKeyChainStore setString:deviceString forKey:@"deviceIdentifier"];
        deviceIdentifier = deviceString;
    }
    self.peerID = [[MCPeerID alloc] initWithDisplayName:deviceIdentifier];
}

- (void) startServices {
    [self.advertiser startAdvertisingPeer];
    [self.browser startBrowsingForPeers];
}

- (void) stopServices {
    [self.browser stopBrowsingForPeers];
    [self.advertiser stopAdvertisingPeer];
}

- (void) cleanUp {
    [self stopServices];
    [self.nearbyPeers enumerateObjectsUsingBlock:^(id nP, NSUInteger idx, BOOL *stop) {
        MCPeerID *peer = nP;
        [self.connectedPeers[peer.displayName][@"session"] disconnect];
        //self.connectedPeers[peer.displayName][@"session"] = nil;
    }];
}

#pragma mark - MCSessionDelegate

- (void) session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    if (![self.blockList containsObject:peerID]) {
        // decode the data
        NSObject *decodedData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        // if the data is a user
        if ([decodedData isKindOfClass:[User class]]) {
            User *user = (User *)decodedData;
            
            [self.connectedPeers[peerID.displayName] setObject:user forKey:@"user"];
            self.connectedPeer = user;
            
            [self.nearbyPeers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id nP, NSUInteger idx, BOOL *stop) {
                MCPeerID *peer = nP;
                
                if ([peer.displayName isEqual:peerID.displayName]) {
                    [self.nearbyPeers removeObjectAtIndex:idx];
                }
            }];
            [self.nearbyPeers addObject:peerID];
            
            NSMutableArray *tempPreviews = self.conversationPreviews;
            
            [tempPreviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSMutableDictionary *conversationPreview = obj;
                MCPeerID *peer = conversationPreview[@"peer"];
                if ([peer.displayName isEqual:peerID.displayName]) {
                    conversationPreview[@"username"] = user.username;
                    conversationPreview[@"avatar"] = user.avatar;
                }
            }];
            self.conversationPreviews = tempPreviews;
            
            // notify
            [[NSNotificationCenter defaultCenter] postNotificationName:@"peerOnline" object:nil];
            
            // make a local notification
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            [localNotification setFireDate:[NSDate date]];
            [localNotification setAlertBody:[NSString stringWithFormat:@"New user %@ online", user.username]];
            [localNotification setAlertAction:@"Chat Now"];
            [localNotification setHasAction:YES];
            localNotification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
        }
        
        // if the data is a jsqmessage
        if ([decodedData isKindOfClass:[JSQMessage class]]) {
            // create JSQMessage
            JSQMessage *incomingMessage = (JSQMessage *)decodedData;
            
            // add the message to the transcript and save it
            if (self.transcripts[peerID.displayName] == nil) {
                [self.transcripts setObject:[@[incomingMessage] mutableCopy] forKey:peerID.displayName];
            } else {
                [self.transcripts[peerID.displayName] addObject:incomingMessage];
            }
            [self saveTranscripts];
            
            // generate the conversation preview
            NSDictionary *conversationPreview = [self generateConversationPreviewFromMessage:incomingMessage withPeer:peerID];
            
            // remove the previous conversation preview, if any.
            [self.conversationPreviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id cnv, NSUInteger idx, BOOL *stop) {
                NSMutableDictionary *conversation = (NSMutableDictionary *)cnv;
                MCPeerID *peer = conversation[@"peer"];
                if ([peer.displayName isEqual:peerID.displayName]) {
                    [self.conversationPreviews removeObjectAtIndex:idx];
                }
            }];
            
            // add the conversation preview to the lists
            [self.conversationPreviews insertObject:conversationPreview atIndex:0];
            [self saveConversationList];
            
            // post a notification
            [[NSNotificationCenter defaultCenter] postNotificationName:@"messageReceived" object:nil];
            
            // make a local notification
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            [localNotification setFireDate:[NSDate date]];
            [localNotification setAlertBody:[NSString stringWithFormat:@"New message from %@", conversationPreview[@"username"]]];
            [localNotification setAlertAction:@"Read It"];
            [localNotification setHasAction:YES];
            [localNotification setSoundName:@"notification.mp3"];
            NSString *type = (!incomingMessage.text) ? @"Photo" : @"Message";
            NSDictionary *userInfo = @{@"peer" : peerID.displayName,
                                       @"notificationType" : type};
            [localNotification setUserInfo:userInfo];
            localNotification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
            
            // handleNotificationsForMessage:
            
        }

    }
}

- (void) session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    // update nearby peer list
    // post a notification
    if (state == MCSessionStateConnected) {
        //send user data to other peer
        NSData *userData = [NSKeyedArchiver archivedDataWithRootObject:self.user];
        BOOL success = [session sendData:userData toPeers:@[peerID] withMode:MCSessionSendDataReliable error:nil];
        if (!success) {
            NSLog(@"Error sending user data");
        }
    } else if (state == MCSessionStateNotConnected) {
        [session disconnect];
        [self.connectedPeers removeObjectForKey:peerID.displayName];
    }
}

- (void) session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void (^)(BOOL accept))certificateHandler
{
    certificateHandler(YES);
}

//the methods below are required by the protocol but won't be used by the app..

- (void) session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
    
}

- (void) session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
    
}

- (void) session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
    
}

#pragma mark - MCSession Misc Methods

- (void) updateUserInfo {
    for (MCPeerID *peerID in [DataSource sharedInstance].nearbyPeers) {
        NSData *userData = [NSKeyedArchiver archivedDataWithRootObject:self.user];
        NSError *error = nil;
        BOOL success = [[DataSource sharedInstance].connectedPeers[peerID.displayName][@"session"] sendData:userData toPeers:@[peerID] withMode:MCSessionSendDataReliable error:&error];
        if (!success) {
            NSLog(@"Error: %@", error.localizedDescription);
        }
    }
}

- (void) sendMessage:(JSQMessage *)message toPeer:(MCPeerID *)peer{
    
    // encode message for sending
    NSData *messageData = [NSKeyedArchiver archivedDataWithRootObject:message];
    NSError *error = nil;
    
    BOOL success = [[DataSource sharedInstance].connectedPeers[peer.displayName][@"session"] sendData:messageData toPeers:@[peer] withMode:MCSessionSendDataReliable error:&error];
    if (success) {
        // add the message to the transcript and save it
        if (self.transcripts[peer.displayName] == nil) {
            [self.transcripts setObject:[@[message] mutableCopy] forKey:peer.displayName];
        } else {
            [self.transcripts[peer.displayName] addObject:message];
        }
        [self saveTranscripts];
        
        // generate the conversation preview
        NSDictionary *conversationPreview = [self generateConversationPreviewFromMessage:message withPeer:peer];
        
        // remove the previous conversation preview, if any.
        [self.conversationPreviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id cnv, NSUInteger idx, BOOL *stop) {
            NSDictionary *conversation = (NSDictionary *)cnv;
            MCPeerID *blockPeer = conversation[@"peer"];
            if ([blockPeer.displayName isEqual:peer.displayName]) {
                [self.conversationPreviews removeObjectAtIndex:idx];
            }
        }];
        
        // add the conversation preview to the list
        [self.conversationPreviews insertObject:conversationPreview atIndex:0];
        [self saveConversationList];
        
        // notify
        [[NSNotificationCenter defaultCenter] postNotificationName:@"messageSent" object:nil];
    } else {
        NSLog(@"Message Send Error: %@", error.localizedDescription);
    }
}

#pragma mark - MCNearbyServiceBrowserDelegate

- (void) browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
    // invite user if not on blocked list
    if ([self.blockList containsObject:peerID]) {
        return;
    }
    if ((peerID.displayName != _peerID.displayName) && (self.connectedPeers[peerID.displayName] == nil) && (peerID.displayName > _peerID.displayName)) {
        // create session
        MCSession *session = [[MCSession alloc] initWithPeer:self.peerID securityIdentity:nil encryptionPreference:MCEncryptionNone];
        session.delegate = self;
        
        // invite peer
        [browser invitePeer:peerID toSession:session withContext:nil timeout:30];
        
        [self.connectedPeers setObject:[@{@"session" : session,
                                          @"user"    : [[User alloc] init]} mutableCopy]
                             forKey:peerID.displayName];
    }
}

- (void) browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    // kill session
    //[self.connectedPeers[peerID.displayName][@"session"] disconnect];
    //[self.connectedPeers removeObjectForKey:peerID.displayName];
    NSLog(@"lost peer");
    // notify
    [[NSNotificationCenter defaultCenter] postNotificationName:@"peerOffline" object:nil];
}

#pragma mark - MCNearbyServiceAdvertiserDelegate

- (void) advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler {
    // if the peer id is blocked, don't accept an invitation.
    if ([self.blockList containsObject:peerID]) {
        invitationHandler(NO, nil);
        return;
    }
    
    // create session
    MCSession *session = [[MCSession alloc] initWithPeer:self.peerID securityIdentity:nil encryptionPreference:MCEncryptionNone];
    session.delegate = self;
        
    invitationHandler(YES, session);
        
    [self.connectedPeers setObject:[@{@"session" : session,
                                      @"user"    : [[User alloc] init]} mutableCopy]
                            forKey:peerID.displayName];
}

#pragma mark - File Misc

- (NSString *) pathForFilename:(NSString *) filename {
    // get user document directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:filename];
    
    return dataPath;
}

#pragma mark - File Loading

- (void) loadUser {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // create file path and decode data for that file
        NSString *fullPath = [self pathForFilename:kUser];
        User *savedUser = [NSKeyedUnarchiver unarchiveObjectWithFile:fullPath];
        
        self.user = savedUser;
    });
}

- (void) loadConversationList {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *fullPath = [self pathForFilename:kConversations];
        NSArray *conversations = [NSKeyedUnarchiver unarchiveObjectWithFile:fullPath];
        
        if (conversations != nil) {
            self.conversationPreviews = [conversations mutableCopy];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadedConversations" object:nil];
        }
    });
}

- (void) loadBlockedConversationList {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *fullPath = [self pathForFilename:kBlockedConversations];
        NSArray *blockedConversations = [NSKeyedUnarchiver unarchiveObjectWithFile:fullPath];
        
        if (blockedConversations != nil) {
            self.blockedConversations = [blockedConversations mutableCopy];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadedConversations" object:nil];
        }
    });
}

- (void) loadTranscripts {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
        NSString *fullPath = [self pathForFilename:kTranscripts];
        NSArray *transcripts = [NSKeyedUnarchiver unarchiveObjectWithFile:fullPath];
        
        if (transcripts != nil) {
            self.transcripts = [transcripts mutableCopy];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadedTranscripts" object:nil];
        }
    });
}

#pragma mark - File Saving

- (void) saveUser {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // set up file path and encode the data to save to the file
        NSString *fullPath = [self pathForFilename:kUser];
        NSData *userDataToSave = [NSKeyedArchiver archivedDataWithRootObject:self.user];
        
        // save the data to file, post a message if there's an error saving
        NSError *dataError;
        BOOL wroteSuccessfully = [userDataToSave writeToFile:fullPath options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&dataError];
        
        if (!wroteSuccessfully) {
            //TODO: Add error reporting through Hockey here?
            NSLog(@"Error writing file: %@", dataError);
        }
    });
}

- (void) saveConversationList {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *fullPath = [self pathForFilename:kConversations];
        NSData *dataToSave = [NSKeyedArchiver archivedDataWithRootObject:self.conversationPreviews];
        
        NSError *dataError;
        BOOL wroteSuccessfully = [dataToSave writeToFile:fullPath options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&dataError];
        
        if (!wroteSuccessfully) {
            //TODO: Add error reporting through Hockey here?
            NSLog(@"Error writing file: %@", dataError);
        }
    });
}

- (void) saveBlockedConversationList {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *fullPath = [self pathForFilename:kBlockedConversations];
        NSData *dataToSave = [NSKeyedArchiver archivedDataWithRootObject:self.blockedConversations];
        
        NSError *dataError;
        BOOL wroteSuccessfully = [dataToSave writeToFile:fullPath options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&dataError];
        
        if (!wroteSuccessfully) {
            //TODO: Add error reporting through Hockey here?
            NSLog(@"Error writing file: %@", dataError);
        }
    });

}

- (void) saveTranscripts {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *fullPath = [self pathForFilename:kTranscripts];
        NSData *dataToSave = [NSKeyedArchiver archivedDataWithRootObject:self.transcripts];
        
        NSError *dataError;
        BOOL wroteSuccessfully = [dataToSave writeToFile:fullPath options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&dataError];
        
        if (!wroteSuccessfully) {
            //TODO: Add error reporting through Hockey here?
            NSLog(@"Error writing file: %@", dataError);
        }
    });
}

#pragma mark - NSUserDefaults

- (void) saveBlockList {
    NSData *blockListToSave = [NSKeyedArchiver archivedDataWithRootObject:self.blockList];
    [[NSUserDefaults standardUserDefaults] setObject:blockListToSave forKey:kBlockedUsers];
}

- (void) loadBlockList {
    NSData *savedBlockList = [[NSUserDefaults standardUserDefaults] objectForKey:kBlockedUsers];
    if (savedBlockList) {
        self.blockList = [NSKeyedUnarchiver unarchiveObjectWithData:savedBlockList];
    }
}

#pragma mark - Conversation Misc 

- (NSMutableDictionary *) generateConversationPreviewFromMessage:(JSQMessage *) message withPeer:(MCPeerID *) peer {
    
    // create parts for the conversation preview dictionary
    
    // truncate message text for preview
    NSString *messagePreview = message.text;
    if(messagePreview.length > 50) {
        messagePreview = [NSString stringWithFormat:@"%@...",[messagePreview substringToIndex:100]];
    } else if (!messagePreview) {
        messagePreview = @"Photo Message";
    }
    
    // user variable for easy reading.
    User *user = self.connectedPeers[peer.displayName][@"user"];
    
    // make the preview
    
    NSMutableDictionary *conversationPreview = [@{ @"peer"     : peer,
                                                   @"username" : user.username,
                                                   @"avatar"   : user.avatar,
                                                   @"message"  : messagePreview,
                                                   @"unread"   : @YES } mutableCopy];
    
    return conversationPreview;
}

@end
