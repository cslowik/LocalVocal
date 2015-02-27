//
//  UserSettingsViewController.m
//  LocalVocal
//
//  Created by Chris Slowik on 1/31/15.
//  Copyright (c) 2015 Chris Slowik. All rights reserved.
//

#import "UserSettingsViewController.h"


@interface UserSettingsViewController () <UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *avatarButton;
@property (weak, nonatomic) IBOutlet UISwitch *visibleSwitch;

@property (strong, nonatomic) User *user;
@property (strong, nonatomic) UIImage *avatarImage;

@end

@implementation UserSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // set up the save button appearance
    self.saveButton.backgroundColor = [UIColor colorWithRed:0.129 green:0.753 blue:0.392 alpha:1];
    self.nameField.borderStyle = UITextBorderStyleNone;
    
    // avatar button appearance
    self.avatarButton.layer.cornerRadius = self.avatarButton.frame.size.width / 2;
    self.avatarButton.clipsToBounds = YES;
    
    // set up bar buttons
    // TODO: think about this
    UIButton *backButton = [[UIButton alloc] initWithFrame: CGRectMake(0, 0, 14.0f, 13.0f)];
    [backButton setTitle:@"" forState:UIControlStateNormal];
    [backButton setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(popBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.navigationItem.leftBarButtonItem = backButtonItem;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    // set text field delegate
    [self.nameField setDelegate:self];
    
    //if there's a photo, show it, otherwise use largeAvatar
    if ([DataSource sharedInstance].user.avatar != nil) {
        self.avatarImage = [DataSource sharedInstance].user.avatar;
        [self.avatarButton setImage:self.avatarImage forState:UIControlStateNormal];
        [self.avatarButton setImage:self.avatarImage forState:UIControlStateHighlighted];
    }
    
    self.user = [DataSource sharedInstance].user;
    
    if (self.user.username == nil) {     // && first load
        /*UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Introduce Yourself" message:@"Enter your name and, if you wish, your picture to start chatting! You can edit your information at any time." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Ok action") style:UIAlertActionStyleCancel handler:nil]];
        [self.parentViewController presentViewController:alert animated:YES completion:nil];*/
        [DataSource sharedInstance].user = [[User alloc] init];
    } else {
        self.nameField.text = self.user.username;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button Actions

- (IBAction)didPressSave:(UIButton *)sender {
    [DataSource sharedInstance].user.username = self.nameField.text;
    if (self.avatarImage) {
        [DataSource sharedInstance].user.avatar = self.avatarImage;
    }
    if (self.visibleSwitch.on) {
        [[DataSource sharedInstance].advertiser startAdvertisingPeer];
        [[NSUserDefaults standardUserDefaults] setValue:@YES forKey:@"isVisible"];
    } else {
        [[NSUserDefaults standardUserDefaults] setValue:@NO forKey:@"isVisible"];
    }
    
    // notify
    [[NSNotificationCenter defaultCenter] postNotificationName:@"userInfoUpdated" object:nil];
    
    // save settings
    [[DataSource sharedInstance] saveUser];
    
    [self popBack];
}
- (IBAction)didPressAvatar:(UIButton *)sender {
    [[DataSource sharedInstance].advertiser stopAdvertisingPeer];
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

#pragma mark - misc view controller stuff

-(void) popBack {
    [self.navigationController popViewControllerAnimated:YES];
    //[[DataSource sharedInstance].browser startBrowsingForPeers];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // stop advertising because we're changing name
    [[DataSource sharedInstance].advertiser stopAdvertisingPeer];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void) dismissKeyboard {
    [self.nameField resignFirstResponder];
}

#pragma mark - Camera Functions

- (void)takePhoto {
    // allow user to take a picture from the camera
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self.view.window.rootViewController presentViewController:picker animated:YES completion:NULL];
    
}

- (void)selectPhoto {
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
    UIImage *resizedImage = [self imageResize:chosenImage andResizeTo:CGSizeMake(125.0, 125.0)];
    self.avatarImage = resizedImage;
    self.avatarButton.imageView.image = resizedImage;
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

#pragma mark - Image Processing

- (UIImage *)imageResize :(UIImage*)img andResizeTo:(CGSize)newSize {
    CGFloat scale = [[UIScreen mainScreen]scale];
    UIGraphicsBeginImageContextWithOptions(newSize, NO, scale);
    [img drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
