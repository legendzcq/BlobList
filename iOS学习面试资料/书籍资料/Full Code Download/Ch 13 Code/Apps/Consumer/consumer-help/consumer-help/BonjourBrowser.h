//
//  BonjourBrowser.h
//  consumer-help
//
//  Created by Nathan Jones on 6/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HelpRequest.h"
#import "HelpResponse.h"

#define kNotificationResultSet      @"NotificationObject"

#define kBrowseStartNotification    @"BonjourBrowseStartNotification"
#define kBrowseErrorNotification    @"BonjourBrowseErrorNotification"
#define kBrowseSuccessNotification  @"BonjourBrowseSuccessNotification"

#define kConnectStartNotification   @"BonjourConnectStartNotification"
#define kConnectErrorNotification   @"BonjourConnectErrorNotification"
#define kConnectSuccessNotification @"BonjourConnectSuccessNotification"

#define kServiceRemovedNotification @"BonjourServiceRemovedNotification"
#define kSearchStoppedNotification  @"BonjourSearchStoppedNotification"

#define kHelpRequestedNotification  @"HelpRequestedNotification"
#define kHelpResponseNotification   @"HelpResponseNotification"

@interface BonjourBrowser : NSObject <NSNetServiceDelegate, 
                                      NSNetServiceBrowserDelegate, 
                                      NSStreamDelegate>

+ (BonjourBrowser*)sharedBrowser;

- (void)browseForHelp;

- (NSArray*)availableServices;

- (void)connectToService:(NSNetService*)service;

- (void)sendHelpRequest:(HelpRequest*)request;

@end