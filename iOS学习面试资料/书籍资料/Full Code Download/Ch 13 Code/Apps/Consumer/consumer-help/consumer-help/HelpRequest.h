//
//  HelpRequest.h
//  associate-help
//
//  Created by Nathan Jones on 7/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HelpRequest : NSObject <NSCoding>

@property(nonatomic,strong) NSString *question;
@property(nonatomic,strong) NSString *location;

@end