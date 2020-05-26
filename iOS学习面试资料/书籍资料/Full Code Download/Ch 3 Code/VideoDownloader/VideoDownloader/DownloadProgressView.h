//
//  DownloadProgressView.h
//  VideoDownloader
//
//  Created by Jack Cox on 4/7/12.
//   
//

#import <UIKit/UIKit.h>

#define kShowProgressView   @"showProgressView"
#define kHideProgressView   @"hideProgressView"

@interface DownloadProgressView : UIView {
    // total number of bytes to download
    long long amountToDownload;
    // total number of bytes downloaded this far
    long long amountDownloaded;
}

@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (assign) BOOL hidden;

// Called on the start of a file download to increment the total amount needed
- (void) addAmountToDownload:(long long)amountToDownload;
// Called on each chunk of data to increment how much has been downloaded
- (void) addAmountDownloaded:(long long)amountDownloaded;

@end
