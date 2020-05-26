//
//  FeedLoader.m
//  VideoDownloader
//
//  Created by Jack Cox on 4/5/12.
//   
//

#import "FeedLoader.h"
#import "XMLReader.h"

@implementation FeedLoader


static NSOperationQueue *queue;

/**
 * This method walks the dictionary of the RSS XML and returns the list of items in the feed
 *
 **/
- (NSArray *)getEntriesArray:(NSDictionary *)dictionary {
    NSArray *entries = [[[dictionary objectForKey:@"rss"] objectForKey:@"channel"] objectForKey:@"item"];
    
    // insure that the method always returns an array
    if (![entries isKindOfClass:[NSArray class]]) {
        
        entries = [NSArray arrayWithObject:entries];
    }
    return entries;
}

/**
 * Performs a synchronous HTTP request and returns the list of items from the RSS feed.
 * It will block the thread on which it is running until the entire feed is retrieved and parsed.
 *
 **/
- (NSArray *) doSyncRequest:(NSString *)urlString {
    // make the NSURL object from the string
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Create the request object with a 30 second timeout and a cache policy to always retrieve the
    // feed regardless of cachability.
    NSURLRequest *request = 
       [NSURLRequest requestWithURL:url 
                        cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData 
                    timeoutInterval:30.0];
    
    // Send the request and wait for a response
    NSHTTPURLResponse   *response;
    NSError             *error;
    NSData *data = [NSURLConnection sendSynchronousRequest:request 
                                         returningResponse:&response 
                                                     error:&error];
    // check for an error
    if (error != nil) {
        NSLog(@"Error on load = %@", [error localizedDescription]);
        return nil;
    }
    
    // check the HTTP status
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            return nil;
        }
        NSLog(@"Headers: %@", [httpResponse allHeaderFields]);
    }
    
    // Parse the data returned into an NSDictionary
    NSDictionary *dictionary = 
        [XMLReader dictionaryForXMLData:data 
                                  error:&error];
    // Dump the dictionary to the log file
    NSLog(@"feed = %@", dictionary);
    
    NSArray *entries =[self getEntriesArray:dictionary];
    
    // return the list if items from the feed.
    return entries;

}

/**
 * Perform a queued request to retrieve the data.  When the request is complete the method 
 * will call the delegate's setVideos: method to pass back the list of items from the RSS feed.
 *
 **/
- (void) doQueuedRequest:(NSString *)urlString  delegate:(id)delegate {
    // make the NSURL object
    NSURL *url = [NSURL URLWithString:urlString];
    
    // create the request object with a no cache policy and a 30 second timeout.
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30.0];
    
    // If the queue doesn't exist, create one.
    if (queue == nil) {
        queue = [[NSOperationQueue alloc] init];
    }
    
    // send the request and specify the code to execute when the request completes or fails.
    [NSURLConnection sendAsynchronousRequest:request 
                                       queue:queue 
                           completionHandler:^(NSURLResponse *response, 
                                               NSData *data, 
                                               NSError *error) {
                               
            if (error != nil) {
               NSLog(@"Error on load = %@", [error localizedDescription]);
            } else {
                
                // check the HTTP status
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    if (httpResponse.statusCode != 200) {
                        return;
                    }
                    NSLog(@"Headers: %@", [httpResponse allHeaderFields]);
                }
                               
                // parse the results and make a dictionary
                NSDictionary *dictionary = 
                   [XMLReader dictionaryForXMLData:data 
                                             error:&error];
                NSLog(@"feed = %@", dictionary);

                // get the dictionary entries.
                NSArray *entries =[self getEntriesArray:dictionary];

                // call the delegate
                if ([delegate respondsToSelector:@selector(setVideos:)]) {
                    [delegate performSelectorOnMainThread:@selector(setVideos:) 
                                               withObject:entries 
                                            waitUntilDone:YES];
                }
            }
    }];
}



@end
