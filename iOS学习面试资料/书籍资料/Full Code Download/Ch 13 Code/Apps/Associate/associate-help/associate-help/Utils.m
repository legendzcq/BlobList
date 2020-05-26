//
//  Utils.m
//  associate-help
//
//  Created by Nathan Jones on 6/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Utils.h"

@implementation Utils

+ (void)postNotifification:(NSString*)notificationName {
    // post the notification to the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName
                                                            object:nil
                                                          userInfo:nil];
    });
}

@end