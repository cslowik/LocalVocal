//
//  NewConversationTableViewController.m
//  LocalVocal
//
//  Created by Chris Slowik on 2/9/15.
//  Copyright (c) 2015 Chris Slowik. All rights reserved.
//

#import "NewConversationTableViewController.h"


@interface NewConversationTableViewController ()

@end

@implementation NewConversationTableViewController

static NSString * const reuseIdentifier = @"userCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"UserTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:reuseIdentifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadUserTable) name:@"peerOnline" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadUserTable) name:@"peerOffline" object:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [DataSource sharedInstance].nearbyPeers.count;
}


- (UserTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // dequeue a cell
    UserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // get the peer id and user data
    MCPeerID *thisPeer = [DataSource sharedInstance].nearbyPeers[indexPath.row];
    User *user = [[[DataSource sharedInstance].connectedPeers objectForKey:thisPeer.displayName] objectForKey:@"user"];
    
    cell.avatarImage.image = user.avatar;
    cell.usernameLabel.text = user.username;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UserTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ChatViewController *chatVC = [ChatViewController messagesViewController];
    MCPeerID *otherPeer = [DataSource sharedInstance].nearbyPeers[indexPath.row];
    User *otherUser = [DataSource sharedInstance].connectedPeers[otherPeer.displayName][@"user"];
    chatVC.otherPeerID = otherPeer;
    chatVC.username = otherUser.username;
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

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Misc Utility Methods

- (void)reloadUserTable {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

@end
