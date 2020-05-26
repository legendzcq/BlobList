//
//  HelpRequest.m
//  associate-help
//
//  Created by Nathan Jones on 7/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "HelpRequest.h"

@implementation HelpRequest

@synthesize question, location;

#pragma mark - NSCoding
- (void)encodeWithCoder:(NSCoder*)aCoder {
    [aCoder encodeObject:self.question forKey:@"question"];
    [aCoder encodeObject:self.location forKey:@"location"];
}

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super init];
    self.question = [aDecoder decodeObjectForKey:@"question"];
    self.location = [aDecoder decodeObjectForKey:@"location"];
    return self;
}

@end