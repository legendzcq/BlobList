//
//  CommandDispatchDemoAppDelegate.h
//  CommandDispatchDemo
//
//  Created by Jack Cox on 9/10/11.
//  
//

#import <UIKit/UIKit.h>
#import "NetworkErrorViewController.h"
#import "LoginViewController.h"

@interface CommandDispatchDemoAppDelegate : NSObject <UIApplicationDelegate> {

NSOperationQueue    *opQueue;
NSString            *token;
NSString            *user;

NetworkErrorViewController  *networkErrorViewController;
LoginViewController         *loginViewController;

}


@property (retain, nonatomic) NSOperationQueue    *opQueue;
@property (retain, nonatomic) NSString            *token;
@property (retain, nonatomic) NSString              *user;

- (void) dismissTopMostModalViewControllerAnimated:(BOOL)flag;
- (void) initializeCommandDispatchListeners;

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@end
