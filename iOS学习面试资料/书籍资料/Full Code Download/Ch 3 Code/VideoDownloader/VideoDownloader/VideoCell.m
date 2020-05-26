//
//  VideoCell.m
//  CommandDispatchDemo
//
//  Cell to hold a little information about a Youtube video
//
//  Created by Jack Cox on 9/22/11.
//  
//

#import "VideoCell.h"


@implementation VideoCell

@synthesize titleLabel;
@synthesize descriptionLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

@end
