//
//  YouTubeVideoCell.h
//  CommandDispatchDemo
//
//  Created by Jack Cox on 9/22/11.
//  
//

#import <UIKit/UIKit.h>

@interface YouTubeVideoCell : UITableViewCell {
    UILabel                     *titleLabel;            // the title cell
    UILabel                     *descriptionLabel;      // the description label
    UIImageView                 *image;                 // the thumbnail image
    NSString                    *imageUrl;              // the url of the image
    UIActivityIndicatorView     *spinner;               // the loading spinner
}
@property (nonatomic, retain) IBOutlet UILabel                      *titleLabel;
@property (nonatomic, retain) IBOutlet UILabel                      *descriptionLabel;
@property (nonatomic, retain) IBOutlet UIImageView                  *image;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView      *spinner;
@property (nonatomic, retain) NSString                              *imageUrl;

/**
 Start the process of loading the image
 **/
- (void) startImageLoad;
@end
