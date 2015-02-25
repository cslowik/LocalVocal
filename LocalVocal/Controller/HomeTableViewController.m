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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // two sections - one for normal, one for blocked
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [DataSource sharedInstance].conversationPreviews.count;
}


- (ConversationTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ConversationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    NSMutableDictionary *conversationPreview = [DataSource sharedInstance].conversationPreviews[indexPath.row];
    /*
     @{ @"peer",
     @"username",
     @"avatar",
     @"message",
     @"unread"};
     */
    
    cell.avatarImage.image = conversationPreview[@"avatar"];
    cell.usernameLabel.text = conversationPreview[@"username"];
    cell.previewLabel.text = conversationPreview[@"message"];
    
    if ([conversationPreview[@"unread"]  isEqual: @YES]) {
        cell.usernameLabel.textColor = [UIColor colorWithRed:0.173 green:0.322 blue:0.886 alpha:1];
    } else {
        cell.usernameLabel.textColor = [UIColor colorWithRed:0.200 green:0.200 blue:0.200 alpha:1];
    }
    
    cell.leftUtilityButtons = [self leftButtons];
    cell.rightUtilityButtons = [self rightButtons];
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


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

#pragma mark - SWTableViewCell Delegate

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

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
    switch (index) {
        case 0:
        {
            NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
            MCPeerID *peerID = [DataSource sharedInstance].conversationPreviews[cellIndexPath.row][@"peer"];
            [[DataSource sharedInstance] blockUser:peerID];
            NSLog(@"Blocked User");
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
