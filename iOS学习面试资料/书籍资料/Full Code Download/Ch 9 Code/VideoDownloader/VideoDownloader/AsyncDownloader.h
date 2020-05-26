//
//  AsyncDownloader.h
//  VideoDownloader
//
//  Created by Jack Cox on 4/7/12.
//   
//

#import <Foundation/Foundation.h>

#define kDownloadComplete   @"downloadComplete"

@class DownloadProgressView;

@interface AsyncDownloader : NSObject <NSURLConnectionDelegate> {
    // The number of bytes that need to be downloaded
    long long   downloadSize;
    // the total amount downloaded thus far
    long long   totalDownloaded;
}
// A reference to the progress view to show the user how things are progressing
@property (assign) DownloadProgressView *progressView;
// The target MP4 file
@property (strong) NSString *targetFile;
// The original URL to download.  Due to redirects the actual content may come from another URL
@property (strong) NSString *srcURL;
// The open file to which the content is written
@property (strong) NSFileHandle *outputHandle;
// The name of the temp file to which the content is streamed. This file is moved to the target file when
// the download is complete
@property (strong) NSString *tempFile;
@property (strong) NSURLConnection *conn;

// instructs the class to start the download.
- (void) start;
@end
