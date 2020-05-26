//
//  ShopTableViewController.m
//  consumer-help
//
//  Created by Nathan Jones on 6/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ShopTableViewController.h"

@interface ShopTableViewController () {
    NSArray *departments;
}
@end

@implementation ShopTableViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // customize the tab bar item
        UITabBarItem *tbi = [[UITabBarItem alloc] initWithTitle:@"Shop"
                                                          image:[UIImage imageNamed:@"shop"]
                                                            tag:0];
        self.tabBarItem = tbi;
        
        // define store departments
        departments = [NSArray arrayWithObjects:@"Children's Clothing", @"Children's Shoes", @"Men's Clothing", @"Men's Shoes", @"Women's Clothing", @"Womens Shoes", nil];

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Departments";
    self.tabBarItem.title = @"Shop";
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [departments count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [departments objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [[[UIAlertView alloc] initWithTitle:@"Oops"
                                message:@"There's no functionality hooked up to these. Sorry."
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

@end