//
//  HomeTableViewController.m
//  LocalVocal
//
//  Created by Chris Slowik on 1/15/15.
//  Copyright (c) 2015 Chris Slowik. All rights reserved.
//

#import "HomeTableViewController.h"


@interface HomeTableViewController () <SWTableViewCellDelegate, UIGestureRecognizerDelegate>

@property (assign, nonatomic) BOOL newPeers;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *chatButton;

@end

@implementation HomeTableViewController

static NSString * const reuseIdentifier = @"conversationCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.newPeers = NO;
    
    if ([DataSource sharedInstance].user == nil) {
        [self performSegueWithIdentifier:@"userSettingsSegue" sender:self];
    } else {
        [[DataSource sharedInstance] startServices];
    }
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ConversationTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:reuseIdentifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(indicateNewUsers) name:@"peerOnline" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageReceived) name:@"messageReceived" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadUserTable) name:@"messageSent" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadUserTable) name:@"conversationsLoaded" object:nil];
    
    // gesture recognizer for long-press
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 1.0;   //seconds
    longPress.delegate = self;
    [self.tableView addGestureRecognizer:longPress];
    
    /*
     * Persmission to show Local Notification.
     */
    UIApplication *application = [UIApplication sharedApplication];
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
    
    // remove separator insets. makes swtableviewcell look weird
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // two sections - one for normal, one for blocked
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    NSInteger count;
    
    if (section == 0) {
        count = [DataSource sharedInstance].conversationPreviews.count;
    } else {
        count = [DataSource sharedInstance].blockedConversations.count;
    }
    
    return count;
}


- (ConversationTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ConversationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        // if it's not blocked, display the preview as normal
        
        /* conversationPreview dictionary:
         @{ @"peer",
         @"username",
         @"avatar",
         @"message",
         @"unread"};
         */
        NSMutableDictionary *conversationPreview = [DataSource sharedInstance].conversationPreviews[indexPath.row];
        
        cell.avatarImage.image = conversationPreview[@"avatar"];
        cell.usernameLabel.text = conversationPreview[@"username"];
        cell.previewLabel.text = conversationPreview[@"message"];
        cell.redactedTextImage.hidden = YES;
        cell.previewLabel.hidden = NO;
        if ([DataSource sharedInstance].connectedPeers[((MCPeerID *)conversationPreview[@"peer"]).displayName]) {
            cell.onlineIndicator.hidden = NO;
        } else {
            cell.onlineIndicator.hidden = YES;
        }
        
        if ([conversationPreview[@"unread"]  isEqual: @YES]) {
            cell.usernameLabel.textColor = [UIColor colorWithRed:0.173 green:0.322 blue:0.886 alpha:1];
        } else {
            cell.usernameLabel.textColor = [UIColor colorWithRed:0.200 green:0.200 blue:0.200 alpha:1];
        }
        
        
    } else {
        // if it's blocked, display generic avatar and text, and rename to "Blocked user xx"
        cell.usernameLabel.text = [NSString stringWithFormat:@"Blocked User %ld", (long)indexPath.row];
        cell.avatarImage.image = [UIImage imageNamed:@"Avatar"];
        cell.redactedTextImage.hidden = NO;
        cell.previewLabel.hidden = YES;
        cell.onlineIndicator.hidden = YES;
        cell.usernameLabel.textColor = [UIColor colorWithRed:0.200 green:0.200 blue:0.200 alpha:1];
    }
    
    [cell setRightUtilityButtons:[self rightButtons] WithButtonWidth:120];
    [cell setLeftUtilityButtons:[self leftButtons] WithButtonWidth:120];
    cell.delegate = self;
    
    return cell;
}

- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    
    // add utility button here
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor colorWithRed:0.875 green:0.259 blue:0.259 alpha:1] icon:[UIImage imageNamed:@"deleteWhite"]];
    
    return rightUtilityButtons;
}

- (NSArray *)leftButtons
{
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    
    // add utility button here
    [leftUtilityButtons sw_addUtilityButtonWithColor:[UIColor colorWithRed:0.329 green:0.412 blue:0.475 alpha:1] icon:[UIImage imageNamed:@"blockWhite"]];
    
    return leftUtilityButtons;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ChatViewController *chatVC = [ChatViewController messagesViewController];
    chatVC.otherPeerID = [DataSource sharedInstance].conversationPreviews[indexPath.row][@"peer"];
    chatVC.username = [DataSource sharedInstance].conversationPreviews[indexPath.row][@"username"];
    [self.navigationController pushViewController:chatVC animated:YES];
}

#pragma mark - SWTableViewCell Delegate

// delete button
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    switch (index) {
        case 0:
        {
            // Delete button was pressed
            NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
            MCPeerID *peerID = [DataSource sharedInstance].conversationPreviews[cellIndexPath.row][@"peer"];
            
            [[DataSource sharedInstance].conversationPreviews removeObjectAtIndex:cellIndexPath.row];
            [[DataSource sharedInstance].transcripts removeObjectForKey:peerID.displayName];
            [self.tableView deleteRowsAtIndexPaths:@[cellIndexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
        default:
            break;
    }
}

// block button
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
    switch (index) {
        case 0:
        {
            NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
            NSMutableDictionary *conversationToMove = [@{} mutableCopy];
            
            if (cellIndexPath.section == 0) {
                // if it's not blocked, block it.
                // TODO: move all this code to the datasource. alhgvalsdifheiwhfgiwhg
                MCPeerID *peerID = [DataSource sharedInstance].conversationPreviews[cellIndexPath.row][@"peer"];
                conversationToMove = [DataSource sharedInstance].conversationPreviews[cellIndexPath.row];
                //conversationToMove[@"unread"] = @YES;
                [[DataSource sharedInstance].conversationPreviews removeObjectAtIndex:cellIndexPath.row];
                if ([DataSource sharedInstance].blockedConversations == nil) {
                    [DataSource sharedInstance].blockedConversations = [@[conversationToMove] mutableCopy];
                } else {
                    [[DataSource sharedInstance].blockedConversations insertObject:conversationToMove atIndex:0];
                }
                [[DataSource sharedInstance] blockUser:peerID];
            } else {
                // if it's blocked, unblock it.
                // this too.. why here?????
                MCPeerID *peerID = [DataSource sharedInstance].blockedConversations[cellIndexPath.row][@"peer"];
                conversationToMove = [DataSource sharedInstance].blockedConversations[cellIndexPath.row];
                [[DataSource sharedInstance].blockedConversations removeObjectAtIndex:cellIndexPath.row];
                [[DataSource sharedInstance].conversationPreviews addObject:conversationToMove];
                [[DataSource sharedInstance] unblockUser:peerID];
            }
            
            [self reloadUserTable];
            
            break;
        }
        default:
            break;
    }
}

#pragma mark - Actions

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self.tableView];
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
    
    if ((indexPath != nil) && (gestureRecognizer.state == UIGestureRecognizerStateBegan)) {
        NSLog(@"long press on table view at row %ld", (long)indexPath.row);
        [DataSource sharedInstance].conversationPreviews[indexPath.row][@"unread"] = @NO;
        [self reloadUserTable];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier  isEqual: @"userSettingsSegue"]) {
        [[DataSource sharedInstance] stopServices];
    }
    
    if ([segue.identifier isEqual: @"newConversationSegue"]) {
        self.newPeers = NO;
        [self.chatButton setImage:[UIImage imageNamed:@"chat"]];
    }
}

#pragma mark - random utility

- (void)indicateNewUsers {
    self.chatButton.image = [UIImage imageNamed:@"chatNew"];
    NSString *message = [NSString stringWithFormat:@"New user %@ found.", [DataSource sharedInstance].connectedPeer.username];
    UIAlertController *userAlert = [UIAlertController alertControllerWithTitle:@"New User Found" message:message preferredStyle:UIAlertControllerStyleAlert];
    [userAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:userAlert animated:YES completion:nil];
}

- (void) messageReceived {
    [self reloadUserTable];
    [[JSQSystemSoundPlayer sharedPlayer] playAlertSoundWithFilename:@"pop3" fileExtension:@"mp3"];
}

- (void)reloadUserTable {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

@end
