//
//  GetFeed.m
//  CommandDispatchDemo
//
//  Created by Jack Cox on 9/10/11.
//  
//

#import "GetFeed.h"


@implementation GetFeed

- (id)init
{
    self = [super init];
    if (self) {
         completionNotificationName = @"feedReceived";
    }
    
    return self;
}
/**
 Gets the feed of the user's videos from Youtube.
 See: http://code.google.com/apis/youtube/2.0/developers_guide_protocol_understanding_video_feeds.html
 
 **/
- (void)main {
    pool = [[NSAutoreleasePool alloc] init];
    NSLog(@"Starting getFeed operation");


    // Check to see if the user is logged in
    if ([self isUserLoggedIn]) { // on do this if the user is logged in
        // Build the request
        NSString *urlStr=@"https://gdata.youtube.com/feeds/api/users/default/uploads";
        NSLog(@"urlStr=%@",urlStr);
        NSMutableURLRequest *request = [ self createRequestObject:[NSURL URLWithString:urlStr]];
        // Sign the request with the user's auth token
        [self signRequest:request];
        
        // Send the request
        NSHTTPURLResponse *response=nil;
        NSError *error=nil;
        NSData *myData  = [self sendSynchronousRequest:request response_p: &response error:&error];
        
        // Check to see if the request was successful
        if ([super wasCallSuccessful:response error:error]) {
            [self buildDictionaryAndSendCompletionNotif: myData];
        }
    }
    [pool drain];
}



@end
