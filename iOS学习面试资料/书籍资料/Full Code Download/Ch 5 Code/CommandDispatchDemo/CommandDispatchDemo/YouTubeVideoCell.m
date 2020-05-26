//
//  YouTubeVideoCell.m
//  CommandDispatchDemo
//
//  Cell to hold a little information about a Youtube video
//
//  Created by Jack Cox on 9/22/11.
//  
//

#import "YouTubeVideoCell.h"
#import "LoadImageCommand.h"

@implementation YouTubeVideoCell

@synthesize titleLabel;
@synthesize descriptionLabel;
@synthesize image;
@synthesize imageUrl;
@synthesize spinner;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}
/**
 Start the process of loading the image via the command queue
 **/
- (void) startImageLoad {
    LoadImageCommand *cmd = [[LoadImageCommand alloc] init];
    cmd.imageUrl = imageUrl;
    cmd.completionNotificationName = imageUrl; // set the name to something unique
    [cmd listenForMyCompletion:self selector:@selector(didReceiveImage:)];
    [cmd enqueueOperation];
    [cmd release];
}
/**
 Called by the command when the image is received
 **/
- (void) didReceiveImage:(NSNotification *)notif {
    LoadImageCommand *cmd = notif.object;
    
    dispatch_async(dispatch_get_main_queue(), ^{ // make sure it all happens on the main thread
        
        if (cmd.status == kSuccess) {
            image.image = [cmd.results objectForKey:@"image"];
            [spinner stopAnimating];
            [cmd stopListeningForMyCompletion:self];
        } else if ((cmd.status != kSuccess)) {
            image.image = [UIImage imageNamed:@"filenotfound"];
            [cmd stopListeningForMyCompletion:self];
            [spinner stopAnimating];
        }
        
    });
}

- (void)dealloc {
    [titleLabel release];
    [descriptionLabel release];
    [imageUrl release];
    [image release];
    [spinner release];
    [super dealloc];
}

@end
