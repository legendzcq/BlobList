//
//  HelpTableViewController.m
//  associate-help
//
//  Created by Nathan Jones on 6/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "HelpTableViewController.h"
#import "Bonjour.h"

@interface HelpTableViewController () {
    UITextField *serviceNameField;
    NSIndexPath *availabilityCellPath;
    BOOL        available;
}

- (void)handleBonjourPublishStart:(NSNotification*)notification;
- (void)handleBonjourPublishSuccess:(NSNotification*)notification;
- (void)handleBonjourPublishError:(NSNotification*)notification;
- (void)handleBonjourStopSuccess:(NSNotification*)notification;

@end

@implementation HelpTableViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        available = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Associate Help";
    
    // register for Bonjour notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBonjourPublishStart:)
                                                 name:kPublishBonjourStartNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBonjourPublishSuccess:)
                                                 name:kPublishBonjourSuccessNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBonjourPublishError:)
                                                 name:kPublishBonjourErrorNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBonjourStopSuccess:)
                                                 name:kStopBonjourSuccessNotification
                                               object:nil];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Department / Device Name Field
    if (section == 0) {
        return 1;
        
    // Availability Action Section
    } else if (section == 1) {
        return 1;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *InputIdentifier = @"InputCell";
    UITableViewCell *inputCell = [tableView dequeueReusableCellWithIdentifier:InputIdentifier];
    
    static NSString *ActionIdentifier = @"ActionCell";
    UITableViewCell *actionCell = [tableView dequeueReusableCellWithIdentifier:ActionIdentifier];
    
    // Department / Device Name Field
    if (indexPath.section == 0) {
        
        if (inputCell == nil) {
            inputCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                               reuseIdentifier:InputIdentifier];
        }
        
        inputCell.textLabel.text = @"Department";
        inputCell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // add the text field
        if (serviceNameField == nil) {
            serviceNameField = [[UITextField alloc] initWithFrame:CGRectMake(0, 
                                                                             2,
                                                                             160,
                                                                             40)];
            serviceNameField.placeholder = @"Department Name";
            serviceNameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        }
        inputCell.accessoryView = serviceNameField;
        
        
        return inputCell;
    
    // Availability Actions
    } else if (indexPath.section == 1) {
        
        if (actionCell == nil) {
            actionCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                reuseIdentifier:ActionIdentifier];
            
            actionCell.textLabel.textAlignment = UITextAlignmentCenter;
            actionCell.textLabel.textColor = [UIColor blueColor];

        }
        
        // Available
        if (indexPath.row == 0) {
            availabilityCellPath = indexPath;
            if (available == YES) {
                actionCell.textLabel.text = @"No Longer Available";
            } else {
                actionCell.textLabel.text = @"I'm Available";
            }
            
        }
        return actionCell;
    }
    
    return nil;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView 
        didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1) {
        // Available
        if (indexPath.row == 0) {
            // become unavailable
            if (available == YES) {
                [[Bonjour sharedPublisher] stopService];
                available = NO;
                
            // become available
            } else {
                
                // validate that department name has been specified
                if (serviceNameField.text == nil) {
                    [[[UIAlertView alloc] 
                        initWithTitle:@"Error"
                              message:@"Department name is required."
                             delegate:nil
                    cancelButtonTitle:@"OK"
                    otherButtonTitles:nil] show];
                    return;
                }
                
                BOOL serviceRslt = 
                    [[Bonjour sharedPublisher] publishServiceWithName:serviceNameField.text];

                if (serviceRslt == NO) {
                    NSString *errorMsg = 
                        @"Unable to publish your services at this time. Please try again.";
                    [[[UIAlertView alloc] initWithTitle:@"Error"
                                                message:errorMsg
                                               delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil] show];
                }
            }
        }
    }
}

#pragma mark - Bonjour Notifications
- (void)handleBonjourPublishStart:(NSNotification*)notification {
    NSLog(@"Started publishing");
}

- (void)handleBonjourPublishSuccess:(NSNotification*)notification {
    available = YES;
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:availabilityCellPath]
                          withRowAnimation:UITableViewRowAnimationNone];
}

- (void)handleBonjourPublishError:(NSNotification*)notification {
    NSLog(@"Error publishing");
}

- (void)handleBonjourStopSuccess:(NSNotification*)notification {
    available = NO;
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:availabilityCellPath]
                          withRowAnimation:UITableViewRowAnimationNone];
}

@end