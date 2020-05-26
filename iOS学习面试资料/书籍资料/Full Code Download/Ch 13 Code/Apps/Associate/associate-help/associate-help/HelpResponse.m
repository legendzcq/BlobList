//
//  HelpResponse.m
//  associate-help
//
//  Created by Nathan Jones on 7/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

//#import "HelpResponse.h"

@interface HelpResponse : NSObject <NSCoding>

@property(nonatomic,assign) BOOL    response;

@end

@implementation HelpResponse

@synthesize response;

#pragma mark - NSCoding
- (void)encodeWithCoder:(NSCoder*)aCoder {
    [aCoder encodeBool:self.response forKey:@"response"];
}

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super init];
    self.response = [aDecoder decodeBoolForKey:@"response"];
    return self;
}

@end