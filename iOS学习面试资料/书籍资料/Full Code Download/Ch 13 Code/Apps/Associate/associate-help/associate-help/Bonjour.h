//
//  Bonjour.h
//  associate-help
//
//  Created by Nathan Jones on 6/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HelpRequest.h"
#import "HelpResponse.h"

#define kNotificationResultSet              @"NotificationObject"
#define kPublishBonjourStartNotification    @"PublishStartNotification"
#define kPublishBonjourErrorNotification    @"PublishErrorNotification"
#define kPublishBonjourSuccessNotification  @"PublishSuccessNotification"
#define kStopBonjourSuccessNotification     @"StopSuccessNotification"
#define kHelpRequestedNotification          @"HelpRequestedNotification"

@interface Bonjour : NSObject <NSNetServiceDelegate, NSStreamDelegate>

+ (Bonjour*)sharedPublisher;

- (BOOL)publishServiceWithName:(NSString*)name;

- (void)stopService;

- (void)sendHelpResponse:(HelpResponse*)response;

@end