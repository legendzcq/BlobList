//
//  ViewController.m
//  VideoDownloader
//
//  Created by Jack Cox on 4/5/12.
//   
//

#import "ViewController.h"
#import "FeedLoader.h"
#import "VideoCell.h"
#import "AsyncDownloader.h"
#import "DownloadProgressView.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController ()

@end

@implementation ViewController
@synthesize videoTable;
@synthesize segmentedControl;
@synthesize downloadProgressView;


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self refreshList:self];
    

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showProgress:) name:kShowProgressView object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideProgress:) name:kHideProgressView object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadComplete:) name:kDownloadComplete object:nil];
    
    [self hideProgress:nil];
    
    
}

- (void)viewDidUnload
{
    [self setVideoTable:nil];
    [self setSegmentedControl:nil];
    [self setDownloadProgressView:nil];
    [super viewDidUnload];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark    Methods for extracting entry info

- (NSString *) getVideoURL:(NSDictionary *)entry {
    NSDictionary *enclosure = [entry objectForKey:@"enclosure"]; 
    NSString *url = [enclosure objectForKey:@"url"]; 
    
    return url;
    
}

- (NSString *) getVideoFilename:(NSDictionary *)entry {
    NSString *urlString = [self getVideoURL:entry];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSString *basePath = [url lastPathComponent];
    
    NSArray *pathList = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    
    NSString *docPath = [pathList  objectAtIndex:0];
    
    docPath = [docPath stringByAppendingPathComponent:basePath];
    
    return docPath;
}

- (BOOL) isFileDownloaded:(NSDictionary *)entry {
    
    NSString *docPath = [self getVideoFilename:entry];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:docPath])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

#pragma mark    UITableView methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"VideoCell";
    
    // make a video cell object or reuse one
    VideoCell *cell = (VideoCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"VideoCell" owner:self options:nil];
        cell = (VideoCell *)[nib objectAtIndex:0];
        
    }
    
    NSDictionary *entry  = [self.videos objectAtIndex:indexPath.row];
    
    // get the title
    NSDictionary *titleDict = [entry objectForKey:@"title"];
    // get the description
    NSDictionary *descriptionDict = [entry objectForKey:@"description"];
    
    
    // Configure the cell.
    id title = [titleDict objectForKey:@"text"];
    cell.titleLabel.text = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    cell.descriptionLabel.text = [[descriptionDict objectForKey:@"text"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([self isFileDownloaded:entry]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
        
    return cell;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.videos count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 79.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *entry = [self.videos objectAtIndex:indexPath.row];
    
    if ([self isFileDownloaded:entry]) {
            // play video
        NSURL *videoURL = [NSURL fileURLWithPath:[self getVideoFilename:entry]];
        mp = [[MPMoviePlayerViewController alloc] initWithContentURL: videoURL];

        [mp shouldAutorotateToInterfaceOrientation:YES];
        
        [self presentMoviePlayerViewControllerAnimated:mp];
        
       
    } else {
        // start download
        NSString *url = [self getVideoURL:entry];
        NSString *filename = [self getVideoFilename:entry];
        
        AsyncDownloader *downloader = [AsyncDownloader new];
        
        downloader.srcURL = url;
        downloader.targetFile = filename;
        downloader.progressView = downloadProgressView;
        
        [downloader start];
        
    }
    
}

#pragma mark Actions

- (IBAction)refreshList:(id)sender {
    
    self.videos = [NSArray array];
    
    NSString *feedURL = @"http://www.nasa.gov/rss/NASAcast_vodcast.rss";
    
    FeedLoader *feedLoader = [FeedLoader new];
    
    switch (segmentedControl.selectedSegmentIndex) {
        case 0 : // queued request
            [feedLoader doQueuedRequest:feedURL delegate:self];
            break;
        case 1 : // sync request
            self.videos = [feedLoader doSyncRequest:feedURL];
            break;
        
        default:
            break;
    }
    
}

- (void) showProgress:(NSNotification *)notif {
    [UIView animateWithDuration:0.2 animations:^{
        CGFloat height = downloadProgressView.frame.size.height;
        CGRect oldFrame = downloadProgressView.frame;
        CGRect nf = CGRectMake(oldFrame.origin.x, oldFrame.origin.y-height, oldFrame.size.width, oldFrame.size.height);
        
        downloadProgressView.frame = nf;
        
        oldFrame = videoTable.frame;
        nf = CGRectMake(oldFrame.origin.x, oldFrame.origin.y, oldFrame.size.width, oldFrame.size.height-height);
        videoTable.frame = nf;
        
        downloadProgressView.hidden = NO;
        
    }];
}

- (void) hideProgress:(NSNotification *) notif {
    
    [UIView animateWithDuration:0.2 animations:^{
        CGFloat height = downloadProgressView.frame.size.height;
        CGRect oldFrame = downloadProgressView.frame;
        CGRect nf = CGRectMake(oldFrame.origin.x, oldFrame.origin.y+height, oldFrame.size.width, oldFrame.size.height);
        
        downloadProgressView.frame = nf;
        
        oldFrame = videoTable.frame;
        nf = CGRectMake(oldFrame.origin.x, oldFrame.origin.y, oldFrame.size.width, oldFrame.size.height+height);
        videoTable.frame = nf;
        
        downloadProgressView.hidden = YES;
        
    }];
}

- (void) downloadComplete:(NSNotification *) notif {
    [videoTable reloadData];
    
}

#pragma mark Accessors and Mutators

- (void) setVideos:(NSArray *)videos {
    
    _videos = videos;
    
    [videoTable reloadData];
    
}
- (NSArray *) videos {
    return _videos;
}



@end
