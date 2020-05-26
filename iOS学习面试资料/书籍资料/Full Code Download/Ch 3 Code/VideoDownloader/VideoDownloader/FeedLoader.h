//
//  FeedLoader.h
//  VideoDownloader
//
//  Created by Jack Cox on 4/5/12.
//   
//

#import <Foundation/Foundation.h>


@interface FeedLoader : NSObject


// Do a synchronous request, loading the specified URL string
- (NSArray *) doSyncRequest:(NSString *)urlString;

// Perform a queued request.  When the request is complete this method
// will call the delegate objects setVideos: method with an array of items
//
- (void) doQueuedRequest:(NSString *)urlString delegate:(id)delegate; 

@end
