//
//  LoadImageCommand.m
//  CommandDispatchDemo
//
//  Created by Jack Cox on 9/22/11.
//  
//

#import "LoadImageCommand.h"

@implementation LoadImageCommand
@synthesize imageUrl;
- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}
- (void) dealloc {
    [imageUrl release];
    [super dealloc];
}

/**
 Retrieve an image from the internet and send a notification when that image is retrieved
 **/
- (void)main {
    pool = [[NSAutoreleasePool alloc] init];
    NSLog(@"Starting LoadImage operation %@", self.imageUrl);
    
    NSError *error = nil;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl] options:0 error:&error];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if ([self isNoError:error]) {
        UIImage *image = [UIImage imageWithData:data];
        if (image == nil) {
            self.status = kFailure;
            self.reason = @"Invalid image format";
            [self sendNetworkErrorNotification];
            [pool drain];
            return;
        }
        self.results = [NSDictionary dictionaryWithObjectsAndKeys:image, @"image", nil];
        self.status = kSuccess;
        [self sendCompletionNotification];
    }
    [pool drain];
    return;
    
}
- (id) copyWithZone:(NSZone *)zone {
    LoadImageCommand *newOp = [super copyWithZone:zone];
    newOp.imageUrl = imageUrl;
    return newOp;
}
@end
