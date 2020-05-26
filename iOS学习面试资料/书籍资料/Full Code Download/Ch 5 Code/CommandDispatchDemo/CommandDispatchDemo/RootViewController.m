//
//  RootViewController.m
//  CommandDispatchDemo
//
//  Created by Jack Cox on 9/10/11.
//  
//

#import "RootViewController.h"
#import "GetFeed.h"
#import "BaseCommand.h"
#import "YouTubeVideoCell.h"
#import "CommandDispatchDemoAppDelegate.h"

@implementation RootViewController
@synthesize feed;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Go get the user's set of uploaded videos
    [self requestVideoFeed];

}



- (void)refresh:(id)sender {
    self.feed = [NSDictionary dictionary];
    [self.tableView reloadData];
    [self requestVideoFeed];
}
#pragma mark    Command Dispatch methods

/**
 Request videos that the current user has uploaded
 **/
- (void)requestVideoFeed {
    // mand the command
    GetFeed *op = [[GetFeed alloc] init];
    // add the current authentication token to the command
    CommandDispatchDemoAppDelegate *delegate = (CommandDispatchDemoAppDelegate *)[[UIApplication sharedApplication] delegate ];
    op.token = delegate.token;
    
    // register to hear the completion of the command
    [op listenForMyCompletion:self selector:@selector(gotFeed:)];
    // put it on the queue for execution
    [op enqueueOperation];
    [op release];
    
}
/**
 This method is called by the completed command 
 **/
- (void) gotFeed:(NSNotification *)notif {
    NSLog(@"User info = %@", notif.userInfo);
    BaseCommand *op = notif.object;
    
    if (op.status == kSuccess) {
        self.feed = op.results;
        
        // if entry is a single item, change it to an array
        id entries = [[feed objectForKey:@"feed"] objectForKey:@"entry"];
        if ([entries isKindOfClass:[NSDictionary class]]) {
            NSArray *entryArray = [NSArray arrayWithObject:entries];
            [[feed objectForKey:@"feed"] setObject:entryArray forKey:@"entry"];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Videos" message:@"The login to YouTube failed" delegate:self cancelButtonTitle:@"Retry" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self refresh:self];
}

#pragma -


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 79.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (feed != nil) {
        NSArray *entries = [[feed objectForKey:@"feed"] objectForKey:@"entry"];
        return [entries count];
    } else {
        return 0;
    }
}

/** 
 handle the loading of a cell
 **/
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"YouTubeVideoCell";
    
    // make a video cell object or reuse one
    YouTubeVideoCell *cell = (YouTubeVideoCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
       
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"YouTubeVideoCell" owner:self options:nil];
        cell = (YouTubeVideoCell *)[nib objectAtIndex:0];
    }
    
    // get the entry for this cell
    NSArray *entries = [[feed objectForKey:@"feed"] objectForKey:@"entry"];
    NSDictionary *entry  = [entries objectAtIndex:indexPath.row];
    
    // get the title
    NSDictionary *titleDict = [entry objectForKey:@"title"];
    // get the description
    NSDictionary *contentDict = [entry objectForKey:@"content"];
    
    NSArray *mediaThumbs = [[entry objectForKey:@"media:group"] objectForKey:@"media:thumbnail"];
    // Configure the cell.
    id title = [titleDict objectForKey:@"text"];
    cell.titleLabel.text = title;
    cell.descriptionLabel.text = [contentDict objectForKey:@"text"];
    // get a URL for a thumbnail
    if ([mediaThumbs count] > 0) {
        NSString *thumb = [[mediaThumbs objectAtIndex:0] objectForKey:@"url"];
        cell.imageUrl = thumb;
        [cell startImageLoad];
    }
    
    return cell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)dealloc
{
    [feed release];
    [super dealloc];
}

@end
