//
//  HelpRequestTableViewController.m
//  consumer-help
//
//  Created by Nathan Jones on 7/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "HelpRequestTableViewController.h"
#import "BonjourBrowser.h"

@interface HelpRequestTableViewController () {
    UITextView  *questionTextView;
    UITextField *locationTextField;
}
- (void)saveAction;
- (void)cancelAction;

- (void)handleBonjourConnectStart:(NSNotification*)notification;
- (void)handleBonjourConnectSuccess:(NSNotification*)notification;
- (void)handleBonjourConnectError:(NSNotification*)notification;

- (void)helpRequestedHandler:(NSNotification*)notification;
- (void)helpResponseHandler:(NSNotification*)notification;

@end

@implementation HelpRequestTableViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Listen for connection notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleBonjourConnectStart:)
                                                     name:kConnectStartNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleBonjourConnectSuccess:)
                                                     name:kConnectSuccessNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleBonjourConnectError:)
                                                     name:kConnectErrorNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(helpRequestedHandler:)
                                                     name:kHelpRequestedNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(helpResponseHandler:)
                                                     name:kHelpResponseNotification
                                                   object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Help Details";
    
    UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithTitle:@"Submit"
                                                             style:UIBarButtonSystemItemSave 
                                                            target:self 
                                                            action:@selector(saveAction)];
    self.navigationItem.rightBarButtonItem = save;
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                               style:UIBarButtonSystemItemCancel 
                                                              target:self 
                                                              action:@selector(cancelAction)];
    self.navigationItem.leftBarButtonItem = cancel;
}

#pragma UI Response
- (void)saveAction {
    if (questionTextView.text.length == 0 ||
        locationTextField.text.length == 0) {
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:@"Question and Location are required."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
    HelpRequest *request = [[HelpRequest alloc] init];
    request.question = questionTextView.text;
    request.location = locationTextField.text;
    [[BonjourBrowser sharedBrowser] sendHelpRequest:request];
}

- (void)cancelAction {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Question field
    if (indexPath.section == 0) {
        return 100.0;
    }
    
    return 44.0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Question";
            break;
        
        case 1:
        default:
            return @"Location";
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Question Field
    if (indexPath.section == 0) {
        
        // add the text view
        if (questionTextView == nil) {
            questionTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 
                                                                            4,
                                                                            290,
                                                                            92)];
            questionTextView.backgroundColor = [UIColor clearColor];
        }
        cell.accessoryView = questionTextView;
        
    // Location field
    } else if (indexPath.section == 1) {
        
        // add the text view
        if (locationTextField == nil) {
            locationTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 
                                                                              2,
                                                                              290,
                                                                              40)];
            
            locationTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        }
        cell.accessoryView = locationTextField;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark - Notification Handlers
- (void)handleBonjourConnectStart:(NSNotification*)notification {
    NSLog(@"Connection / Resolution process started.");
}

- (void)handleBonjourConnectSuccess:(NSNotification*)notification {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)handleBonjourConnectError:(NSNotification*)notification {
    // enable the cancel button
    self.navigationItem.leftBarButtonItem.enabled = YES;
    
    [[[UIAlertView alloc] initWithTitle:@"Connection Error"
                                message:@"Unable to establish connection with associate. Please try again later."
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

- (void)helpRequestedHandler:(NSNotification*)notification {
    // once they've requested help, let the associate respond
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)helpResponseHandler:(NSNotification*)notification {
    HelpResponse *response = (HelpResponse*)[[notification userInfo] objectForKey:kNotificationResultSet];
    NSString *responseString;
    if (response.response == YES) {
        responseString = @"An associate will be with you shortly.";
    } else {
        responseString = @"The associate is currently assisting another customer. Please try another associate.";
    }
    
    [[[UIAlertView alloc] initWithTitle:@"Help Response"
                                message:responseString
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
    
    [self dismissModalViewControllerAnimated:YES];
}

@end
