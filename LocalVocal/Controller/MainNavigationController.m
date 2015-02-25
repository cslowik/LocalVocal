//
//  MainNavigationController.m
//  LocalVocal
//
//  Created by Chris Slowik on 2/2/15.
//  Copyright (c) 2015 Chris Slowik. All rights reserved.
//

#import "MainNavigationController.h"


@interface MainNavigationController ()

@property (assign, nonatomic) SystemSoundID soundID;

@end

@implementation MainNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationBar.titleTextAttributes = @{NSFontAttributeName:[UIFont fontWithName:@"Open Sans" size:17], NSForegroundColorAttributeName: [UIColor colorWithRed:0.200 green:0.200 blue:0.200 alpha:1]};
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end
