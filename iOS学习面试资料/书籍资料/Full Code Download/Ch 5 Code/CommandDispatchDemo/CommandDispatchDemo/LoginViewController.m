//
//  LoginViewController.m
//
//  Created by Jack Cox on 8/5/11.
//  
//

#import "LoginViewController.h"
#import "LoginCommand.h"
#import "CommandDispatchDemoAppDelegate.h"

@implementation LoginViewController
@synthesize userField;
@synthesize pwdField;
@synthesize spinner;
@synthesize errorField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void) dealloc {
    [userField release];
    [pwdField release];
    [spinner release];
    [errorField release];
    [super dealloc];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) viewDidDisappear:(BOOL)animated {
    CommandDispatchDemoAppDelegate *delegate = (CommandDispatchDemoAppDelegate *) [[UIApplication sharedApplication] delegate];
    for(BaseCommand *op in triggeringCommands) {
         
        op.token = delegate.token; // provide the token to the requeued command
        [op enqueueOperation];
    }
    [triggeringCommands removeAllObjects];
    self.displayed = NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

/**
 Create and enqueue a login command and await the response
 **/
- (void) doLogin:(id)sender {
    NSLog(@"doing login");
    [spinner startAnimating];
    NSString *user = userField.text;
    NSString *pwd = pwdField.text;
    
    LoginCommand *op = [[LoginCommand alloc] init];
    
    op.user = user;
    op.pwd = pwd;
    [op listenForMyCompletion:self selector:@selector(didLogin:)];
    [op enqueueOperation];
    [op release];
}

/**
 Handle the successful or failed login attempt
 **/
- (void) didLogin:(NSNotification *) notif {
    NSLog(@"did login");
    LoginCommand *op = notif.object; 
    [op retain];
    // make sure you do all UI operations on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [spinner stopAnimating];
        
        
        if (op.status == kSuccess) {
            NSDictionary *results = op.results;
            NSString  *authResponse = [results objectForKey:@"authToken"];
            // dismiss view controller
            CommandDispatchDemoAppDelegate *delegate = (CommandDispatchDemoAppDelegate *) [[UIApplication sharedApplication] delegate];
            delegate.token = authResponse;
            delegate.user = op.user;
            
            [delegate dismissTopMostModalViewControllerAnimated:YES];
          
        } else {
            NSLog(@"Login operation failed");
            errorField.text = @"Invalid Login";
        }
        [op release];
    });
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [theTextField resignFirstResponder];
    if (theTextField == pwdField) {
        [self doLogin:theTextField];
    } else if (theTextField == userField) {
        [pwdField becomeFirstResponder];
    }
    return YES;
}


@end
