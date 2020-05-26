//
//  ViewController.h
//  VideoDownloader
//
//  Created by Jack Cox on 4/5/12.
//   
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@class DownloadProgressView;

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    NSArray      *_videos;
    MPMoviePlayerViewController *mp;
}
@property (weak, nonatomic) IBOutlet UITableView *videoTable;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet DownloadProgressView *downloadProgressView;
@property (strong, nonatomic) NSArray *videos;

- (IBAction)refreshList:(id)sender;

@end
