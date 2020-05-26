//
//  HelpResponse.m
//  associate-help
//
//  Created by Nathan Jones on 7/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "HelpResponse.h"

@implementation HelpResponse

@synthesize response;

- (void)encodeWithCoder:(NSCoder*)aCoder {
    [aCoder encodeBool:self.response forKey:@"response"];
}

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super init];
    self.response = [aDecoder decodeBoolForKey:@"response"];
    return self;
}

@end