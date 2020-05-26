//
//  AppDelegate.m
//  associate-help
//
//  Created by Nathan Jones on 6/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "HelpTableViewController.h"
#import "Bonjour.h"

@interface AppDelegate ()
- (void)helpRequestHandler:(NSNotification*)notification;
@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(helpRequestHandler:)
                                                 name:kHelpRequestedNotification
                                               object:nil];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    HelpTableViewController *helpVC = [[HelpTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:helpVC];
    self.window.rootViewController = nc;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[Bonjour sharedPublisher] stopService];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Notification Handlers
- (void)helpRequestHandler:(NSNotification*)notification {
    HelpRequest *request = (HelpRequest*)[[notification userInfo] objectForKey:kNotificationResultSet];
    NSString *helpString = [NSString 
                            stringWithFormat:@"Help requested in %@ with: %@.", 
                            request.location, 
                            request.question];
    
    UIAlertView *helpAlert = [[UIAlertView alloc] initWithTitle:@"Help Request"
                                                        message:helpString
                                                       delegate:self
                                              cancelButtonTitle:@"I'm Unavailable"
                                              otherButtonTitles:@"I'll Help", nil];
    helpAlert.tag = 1;
    [helpAlert show];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        // Help Requested
        case 1: {
            
            HelpResponse *response = [[HelpResponse alloc] init];
            // Declined to help
            if (buttonIndex == 0) {
                // associate is currently busy
                // please select another associate
                response.response = NO;
            // Offered to help
            } else if (buttonIndex == 1) {
                // associate will be right there
                response.response = YES;
                
                // stop broadcasting
                [[Bonjour sharedPublisher] stopService];
            }
            
            [[Bonjour sharedPublisher] sendHelpResponse:response];
            
            break;
        }
        default:
            break;
    }
}

@end
