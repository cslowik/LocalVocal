//
//  ChatViewController.m
//  LocalVocal
//
//  Created by Chris Slowik on 2/10/15.
//  Copyright (c) 2015 Chris Slowik. All rights reserved.
//

#import "ChatViewController.h"

@interface ChatViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"More"
                                                                    style:UIBarButtonItemStylePlain target:nil action:@selector(chatOptions)];
    self.navigationItem.rightBarButtonItem = rightButton;
    
    // initialize the user infos for quick access
    self.peerID = [DataSource sharedInstance].peerID;
    
    // mark conversation as read
    [[DataSource sharedInstance].conversationPreviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSMutableDictionary *conversationPreview = (NSMutableDictionary *)obj;
        MCPeerID *thisPeer = conversationPreview[@"peer"];
        if ([thisPeer.displayName isEqual:self.otherPeerID.displayName]) {
            [DataSource sharedInstance].conversationPreviews[idx][@"unread"] = @NO;
        }
    }];
    
    // set up the chat bubble stuff JSQ needs
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor colorWithRed:0.090 green:0.329 blue:0.941 alpha:1]];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor colorWithRed:0.910 green:0.910 blue:0.910 alpha:1]];
    
    // set senderID and display name
    self.senderId = [DataSource sharedInstance].peerID.displayName;
    self.senderDisplayName = [DataSource sharedInstance].user.username;
    
    // set avatar sizes to zero - not using
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    //self.showLoadEarlierMessagesHeader = YES;
    
    self.title = [NSString stringWithFormat:@"%@", self.username];
    
    // set bubble font to open sans
    self.collectionView.collectionViewLayout.messageBubbleFont = [UIFont fontWithName:@"Open Sans" size:13.0];
    
    // register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageReceived) name:@"messageReceived" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // enable springy bubbles
    self.collectionView.collectionViewLayout.springinessEnabled = NO;
}


#pragma mark - JSQMessagesViewController

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    /**
     *  Sending a message.
     *  1. Play sound (optional)
     *  2. Add new id<JSQMessageData> object to your data source
     *  3. Call `finishSendingMessage`
     */
    //[JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:senderId
                                             senderDisplayName:senderDisplayName
                                                          date:date
                                                          text:text];
    [[DataSource sharedInstance] sendMessage:message toPeer:self.otherPeerID];
    
    [self finishSendingMessageAnimated:YES];
}

- (void) didPressAccessoryButton:(UIButton *)sender {
    UIAlertController *cameraAlert = [UIAlertController alertControllerWithTitle:@"Choose photo source" message:@"Would you like to choose a picture from your camera roll, or take a new picture?" preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Take a Picture", @"Camera action") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self takePhoto];
    }];
    UIAlertAction *cameraRollAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Choose from Camera Roll", @"Camera roll action") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self selectPhoto];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action") style:UIAlertActionStyleCancel handler:nil];
    [cameraAlert addAction:cameraAction];
    [cameraAlert addAction:cameraRollAction];
    [cameraAlert addAction:cancelAction];
    [self.view.window.rootViewController presentViewController:cameraAlert animated:YES completion:nil];
}

#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [DataSource sharedInstance].transcripts[self.otherPeerID.displayName][indexPath.row];
    
    return message;
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  You may return nil here if you do not want bubbles.
     *  In this case, you should set the background color of your collection view cell's textView.
     */
    
    JSQMessage *message = [[DataSource sharedInstance].transcripts[self.otherPeerID.displayName] objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outgoingBubbleImageData;
    }
    
    return self.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Return `nil` here if you do not want avatars.
     *  If you do return `nil`, be sure to do the following in `viewDidLoad`:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
     *
     *  It is possible to have only outgoing avatars or only incoming avatars, too.
     */
    
    /**
     *  Return your previously created avatar image data objects.
     *
     *  Note: these the avatars will be sized according to these values:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize
     *
     *  Override the defaults in `viewDidLoad`
     */
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
     *  The other label text delegate methods should follow a similar pattern.
     */
    
    /* Show timestamp for every third message
     if (indexPath.item % 3 == 0) {
        JSQMessage *message = [[DataSource sharedInstance].connectedPeers[@"messages"] objectAtIndex:indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }*/
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    //JSQMessage *message = [[DataSource sharedInstance].connectedPeers[self.otherPeerID][@"messages"] objectAtIndex:indexPath.item];
    
    /**
     *  iOS7-style sender name labels
     */
    
    /*
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    // get the previous message, if it's the same sender don't add the sender name
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [[DataSource sharedInstance].connectedPeers[self.otherPeerID][@"messages"] objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }
     
     */
    
    /**
     *  Don't specify attributes to use the defaults.
     */
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[DataSource sharedInstance].transcripts[self.otherPeerID.displayName] count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    /**
     *  Configure almost *anything* on the cell
     *
     *  Text colors, label text, label colors, etc.
     *
     *
     *  DO NOT set `cell.textView.font` !
     *  Instead, you need to set `self.collectionView.collectionViewLayout.messageBubbleFont` to the font you want in `viewDidLoad`
     *
     *
     *  DO NOT manipulate cell layout information!
     *  Instead, override the properties you want on `self.collectionView.collectionViewLayout` from `viewDidLoad`
     */
    
    JSQMessage *msg = [[DataSource sharedInstance].transcripts[self.otherPeerID.displayName] objectAtIndex:indexPath.item];
    
    if (!msg.isMediaMessage) {
        
        if ([msg.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor whiteColor];
        }
        else {
            cell.textView.textColor = [UIColor blackColor];
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    return cell;
}

#pragma mark - JSQMessages collection view flow layout delegate

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
     */
    
    /**
     *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
     *  The other label height delegate methods should follow similarly
     *
     *  Show a timestamp for every 3rd message
     */
    
    /*
    if (indexPath.item % 3 == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }*/
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    NSLog(@"Load earlier messages!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped message bubble!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}

#pragma mark - Camera Functions

- (void) takePhoto {
    // allow user to take a picture from the camera
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self.view.window.rootViewController presentViewController:picker animated:YES completion:NULL];
    
}

- (void) selectPhoto {
    // allow user to select a photo from their camera roll
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self.view.window.rootViewController presentViewController:picker animated:YES completion:NULL];
    
    
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    // the image picker controller finishes by masking the image to a circle. this should be an elegant way to handle it because it's
    // the single entry point to the app for images (avatar images at least)
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:chosenImage];
    JSQMessage *photoMessage = [JSQMessage messageWithSenderId:self.senderId displayName:self.senderDisplayName media:photoItem];
    [[DataSource sharedInstance] sendMessage:photoMessage toPeer:self.otherPeerID];
    
    [self finishSendingMessageAnimated:YES];
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

#pragma mark - Misc utility

- (void) messageReceived {
    // play sound and finish receiving
    [self finishReceivingMessage];
    [[JSQSystemSoundPlayer sharedPlayer] playAlertSoundWithFilename:@"pop3" fileExtension:@"mp3"];
}

- (void) chatOptions {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Conversation Options" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"Block User" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[DataSource sharedInstance] blockUser:self.otherPeerID];
    }]];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
    // TODO: completion handler for if user is blocked - conversation should close and the appropriate visual changes have to happen on the home screen.
    // probably need to update datasource block user method..
}


@end
