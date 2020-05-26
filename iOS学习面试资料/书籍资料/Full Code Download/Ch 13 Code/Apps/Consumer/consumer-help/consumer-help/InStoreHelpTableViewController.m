//
//  InStoreHelpTableViewController.m
//  consumer-help
//
//  Created by Nathan Jones on 6/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InStoreHelpTableViewController.h"
#import "HelpRequestTableViewController.h"
#import "BonjourBrowser.h"

@interface InStoreHelpTableViewController () {
    BOOL loading;
}

- (void)handleBonjourBrowseStart:(NSNotification*)notification;
- (void)handleBonjourBrowseSuccess:(NSNotification*)notification;
- (void)handleBonjourBrowseError:(NSNotification*)notification;

- (void)handleBonjourRemoveService:(NSNotification*)notification;

@end

@implementation InStoreHelpTableViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // customize the tab bar item
        UITabBarItem *tbi = [[UITabBarItem alloc] initWithTitle:@"Help"
                                                          image:[UIImage imageNamed:@"help"]
                                                            tag:0];
        self.tabBarItem = tbi;
        
        loading = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Available Associates";
    self.tabBarItem.title = @"Help";
    
    // add notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBonjourBrowseStart:)
                                                 name:kBrowseStartNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBonjourBrowseSuccess:)
                                                 name:kBrowseSuccessNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBonjourBrowseError:)
                                                 name:kBrowseErrorNotification
                                               object:nil];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[BonjourBrowser sharedBrowser] browseForHelp];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (loading == NO) {
        return [[[BonjourBrowser sharedBrowser] availableServices] count];
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (loading == NO) {
        NSNetService *service = [[[BonjourBrowser sharedBrowser] availableServices] objectAtIndex:indexPath.row];
        cell.textLabel.text = service.name;
        cell.textLabel.textAlignment = UITextAlignmentLeft;
    } else {
        cell.textLabel.text = @"loading...";
        cell.textLabel.textAlignment = UITextAlignmentCenter;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSNetService *service = [[[BonjourBrowser sharedBrowser] availableServices] objectAtIndex:indexPath.row];
    [[BonjourBrowser sharedBrowser] connectToService:service];
    
    HelpRequestTableViewController *hrtvc = [[HelpRequestTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:hrtvc];
    
    [self presentModalViewController:nc animated:YES];
}

#pragma mark - Notification Handlers
- (void)handleBonjourBrowseStart:(NSNotification*)notification {
    loading = YES;
    [self.tableView reloadData];
}

- (void)handleBonjourBrowseSuccess:(NSNotification*)notification {
    loading = NO;
    [self.tableView reloadData];
}

- (void)handleBonjourBrowseError:(NSNotification*)notification {
    [[[UIAlertView alloc] initWithTitle:@"Browse Error"
                                message:@"Oops, we are unable to browse for help at the moment."
                               delegate:nil 
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

- (void)handleBonjourRemoveService:(NSNotification*)notification {
#warning test if this fixes the issue where services weren't updated
    [self.tableView reloadData];
}

@end
