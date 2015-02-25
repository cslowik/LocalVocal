//
//  AppDelegate.m
//  LocalVocal
//
//  Created by Chris Slowik on 1/14/15.
//  Copyright (c) 2015 Chris Slowik. All rights reserved.
//

#import "AppDelegate.h"
#import "DataSource.h"
#import <HockeySDK/HockeySDK.h>
#import "Flurry.h"
#import "../../LocalVocal Config/config.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // hockeyapp stuff
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:kHockeyAPIKey];
    //[[BITHockeyManager sharedHockeyManager].authenticator setIdentificationType:BITAuthenticatorIdentificationTypeHockeyAppUser];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
    
    //init Flurry
    [Flurry startSession:kFlurryAPIKey];
    
    // get the DataSource initialized if it's not already
    [DataSource sharedInstance];
    
    // get notification from launchOptions if there is one
    UILocalNotification *chatNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    
    // set badge number to zero
    //application.applicationIconBadgeNumber = 0;
    
    // handle the notification
    if (chatNotification) {
        
    }
    
    
    return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    // check that the application is active
    UIApplicationState state = [application applicationState];
    if (state == UIApplicationStateActive) {
        // notification notification
        NSLog(@"New message");
        
        // if the notification is a message
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"newMessage" object:self];
        
        // if the notification is a new contact
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"newContact" object:self];
        
        //set the badge number to zero
        application.applicationIconBadgeNumber = 0;
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
<<<<<<< HEAD
    //[[DataSource sharedInstance].browser stopBrowsingForPeers];
    //[[DataSource sharedInstance].advertiser stopAdvertisingPeer];
=======
    [[DataSource sharedInstance].browser stopBrowsingForPeers];
    [[DataSource sharedInstance].advertiser stopAdvertisingPeer];
>>>>>>> 0ecc1741dfadc0e02a2ba9e738c55569531806c1
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    self.backgroundTask = [application beginBackgroundTaskWithExpirationHandler:^{
        // kill session, advertisers, browsers, nil delegates,
        // sending disconnect signal to other peers. this helps ensure
        // we can reconnect later.
        
        [[DataSource sharedInstance] cleanUp];
        
        [application endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;  //invalidate background task
    }];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    self.backgroundTask = UIBackgroundTaskInvalid;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // tell datasource to restart sessions, browsers, advertisers, etc
    //[[DataSource sharedInstance].browser startBrowsingForPeers];
<<<<<<< HEAD
    [[DataSource sharedInstance] startServices];
=======
    [[DataSource sharedInstance].advertiser startAdvertisingPeer];
>>>>>>> 0ecc1741dfadc0e02a2ba9e738c55569531806c1
    
    self.backgroundTask = UIBackgroundTaskInvalid;  //invalidate background task
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
