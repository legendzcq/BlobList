//
//  NetworkErrorViewController.m
//
//  Created by Jack Cox on 8/8/11.
//  
//

#import "NetworkErrorViewController.h"
#import "BaseCommand.h"
#import "CommandDispatchDemoAppDelegate.h"

@implementation NetworkErrorViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        // Custom initialization
    }
    return self;
}


/**
 Resend collected commands when the view disappears
 **/
- (void) viewDidDisappear:(BOOL)animated {
    if (retryFlag) {
        // re-enqueue all of the failed commands
        [self performSelectorAndClear:@selector(enqueueOperation)];
    } else {
        // just send a failure notification for all failed commands
        [self performSelectorAndClear:@selector(sendCompletionFailureNotification)];
    }
    self.displayed = NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


/**
 Handle the user pressing the retry button.  Make this view disappear and retry the commands
 **/
- (IBAction)retry:(id)sender {
    NSLog(@"Retrying operation");
    retryFlag = TRUE; // indicates to teh controller whether to retry when it disappears
    CommandDispatchDemoAppDelegate *delegate = (CommandDispatchDemoAppDelegate *) [[UIApplication sharedApplication] delegate];
    [delegate dismissTopMostModalViewControllerAnimated:YES];
    
}
/**
 Handle the user pressing the cancel button.  Send completion notification for the commands with a failure status
 **/
- (IBAction)abort:(id)sender {
    NSLog(@"Aborting operation");
    retryFlag = false; // indicates to the controller to abort when it disappears 
    CommandDispatchDemoAppDelegate *delegate = (CommandDispatchDemoAppDelegate *) [[UIApplication sharedApplication] delegate];
    [delegate dismissTopMostModalViewControllerAnimated:YES ];
}

@end
