//
//  AsyncDownloader.m
//  VideoDownloader
//
//  Created by Jack Cox on 4/7/12.
//   
//

#import "AsyncDownloader.h"
#import "DownloadProgressView.h"

@implementation AsyncDownloader

@synthesize targetFile;
@synthesize srcURL;
@synthesize outputHandle;
@synthesize tempFile;
@synthesize progressView;
@synthesize conn;

- (void) start {
    NSLog(@"Starting to download %@", srcURL);
    
    // create the URL
    NSURL *url = [NSURL URLWithString:srcURL];
    
    // Create the request
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // create the connection with the target request and this class as the delegate
    self.conn = 
         [NSURLConnection connectionWithRequest:request 
                                       delegate:self];
    
    // start the connection
    [self.conn start];
}

/**
 * Creates a UUID to use as the temporary file name during the download
 */
- (NSString *)createUUID
{
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    NSString *uuid = [NSString stringWithString:(__bridge NSString *)
                      uuidStringRef];
    CFRelease(uuidStringRef);
    return uuid;
}
#pragma mark NSURLConnectionDelegate methods
/**
 * This delegate method is called when the NSURLConnection gets a 300 series response that indicates
 * that the request needs to be redirected.  It is implemented here to display any redirects that might
 * occur. This method is optional.  If omitted the client will follow all redirects.
 **/
- (NSURLRequest *)connection:(NSURLConnection *)connection 
             willSendRequest:(NSURLRequest *)request 
            redirectResponse:(NSURLResponse *)redirectResponse {
    
    // Dump debugging information
    NSLog(@"Redirect request for %@ redirecting to %@", srcURL, request.URL);
    NSLog(@"All headers = %@", 
          [(NSHTTPURLResponse*) redirectResponse allHeaderFields]);
    
    // Follow the redirect
    return request;
}

/**
 * This delegate method is called when the NSURLConnection connects to the server.  It contains the 
 * NSURLResponse object with the headers returned by the server.  This method may be called multiple times.
 * Therefore, it is important to reset the data on each call.  Do not assume that it is the first call
 * of this method.
 **/
- (void) connection:(NSURLConnection *)connection 
 didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"Received response from request to url %@", srcURL);
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSLog(@"All headers = %@", [httpResponse allHeaderFields]);
    
    if (httpResponse.statusCode != 200) {// something went wrong, abort the whole thing
        // reset the download counts
        if (downloadSize != 0L) {
            [progressView addAmountToDownload:-downloadSize];
            [progressView addAmountDownloaded:-totalDownloaded];
        }
        [connection cancel];
        return;
    }
    
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // If we have a temp file already, close it and delete it
    if (self.tempFile != nil) {
        [self.outputHandle closeFile];
        
        NSError *error;
        [fm removeItemAtPath:self.tempFile error:&error];
    }

    // remove any pre-existing target file
    NSError *error;
    [fm removeItemAtPath:targetFile error:&error];
    
    // get the temporary directory name and make a temp file name
    NSString *tempDir = NSTemporaryDirectory();
    self.tempFile = [tempDir stringByAppendingPathComponent:[self createUUID]];
    NSLog(@"Writing content to %@", self.tempFile);
    
    // create and open the temporary file
    [fm createFileAtPath:self.tempFile contents:nil attributes:nil];
    self.outputHandle = [NSFileHandle fileHandleForWritingAtPath:self.tempFile];
    
    // prime the download progress view
    NSString *contentLengthString = [[httpResponse allHeaderFields] objectForKey:@"Content-length"];
    // reset the download counts
    if (downloadSize != 0L) {
        [progressView addAmountToDownload:-downloadSize];
        [progressView addAmountDownloaded:-totalDownloaded];
    }
    downloadSize = [contentLengthString longLongValue];
    totalDownloaded = 0L;
    
    [progressView addAmountToDownload:downloadSize];
}
/**
 * This delegate method is called for each chunk of data received from the server.  The chunk size
 * is dependent on the network type and the server configuration.  
 */
- (void)connection:(NSURLConnection *)connection 
    didReceiveData:(NSData *)data {
    // figure out how many bytes in this chunk
    totalDownloaded+=[data length];
    
    // Uncomment if you want a packet by packet log of the bytes received.  
    NSLog(@"Received %lld of %lld (%f%%) bytes of data for URL %@", 
          totalDownloaded, 
          downloadSize, 
          ((double)totalDownloaded/(double)downloadSize)*100.0,
          srcURL);
    
    // inform the progress view that data is downloaded
    [progressView addAmountDownloaded:[data length]];
    
    // save the bytes received
    [self.outputHandle writeData:data];
}

/**
 * This delegate methodis called if the connection cannot be established to the server.  
 * The error object will have a description of the error
 **/
- (void)connection:(NSURLConnection *)connection 
  didFailWithError:(NSError *)error {
    NSLog(@"Load failed with error %@", 
          [error localizedDescription]);
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // If we have a temp file already, close it and delete it
    if (self.tempFile != nil) {
        [self.outputHandle closeFile];
        
        NSError *error;
        [fm removeItemAtPath:self.tempFile error:&error];
    }
    
    // reset the progress view
    if (downloadSize != 0L) {
        [progressView addAmountToDownload:-downloadSize];
        [progressView addAmountDownloaded:-totalDownloaded];
    }
}

/**
 * This delegate method is called when the data load is complete.  The delegate will be released 
 * following this call
 **/
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // close the file
    [self.outputHandle closeFile];
    
    // Move the file to the target location
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    [fm moveItemAtPath:self.tempFile 
                toPath:self.targetFile 
                 error:&error];
    
    // Notify any concerned classes that the download is complete
    [[NSNotificationCenter defaultCenter] 
     postNotificationName:kDownloadComplete 
     object:nil 
     userInfo:nil];
}
@end
