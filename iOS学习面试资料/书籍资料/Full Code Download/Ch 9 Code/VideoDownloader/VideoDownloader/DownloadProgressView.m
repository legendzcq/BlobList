//
//  DownloadProgressView.m
//  VideoDownloader
//
//  Created by Jack Cox on 4/7/12.
//   
//

#import "DownloadProgressView.h"

@implementation DownloadProgressView
@synthesize progressBar;
@synthesize hidden;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/**
 * Adjust the progress bar for the number of bytes required and the amount downloaded
 *
 **/
- (void) adjustProgressBar {
    
    // Adjust the progress bar
    float progress = (float)amountDownloaded/(float)amountToDownload;
    [progressBar setProgress:progress animated:YES];
    
    //NSLog(@"Downloaded: %lld  to download: %lld", amountDownloaded, amountToDownload);
    
    // Determine if the download is finished or just starting
    if (amountDownloaded == amountToDownload) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kHideProgressView object:nil];
        self.hidden = true;
        // reset the total and amount downloaded so that on the next batch of downloads the progress bar
        // is at a reasonable scale.
        amountDownloaded = 0L;
        amountToDownload = 0L;
    } else if (self.hidden) {
         [[NSNotificationCenter defaultCenter] postNotificationName:kShowProgressView object:nil];
    }
    
}

/**
 * Called on the start of a download to add additional scale to the progress bar.
 **/
- (void) addAmountToDownload:(long long)atd {
    @synchronized(self) {
        amountToDownload += atd;
    }
    [self adjustProgressBar];
}
/**
 * Called on each chunk to adjust the position of the progress bar
 **/
- (void) addAmountDownloaded:(long long)ad {
    @synchronized(self) {
        amountDownloaded += ad;
    }
    [self adjustProgressBar];
}

@end
