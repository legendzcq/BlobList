//
//  BonjourBrowser.m
//  consumer-help
//
//  Created by Nathan Jones on 6/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BonjourBrowser.h"
#import "Utils.h"

@interface BonjourBrowser () {
    NSNetServiceBrowser *browser;
    NSMutableArray      *services;
    
    NSInputStream       *inputStream;
    NSOutputStream      *outputStream;
    NSMutableData       *receiveData;
    NSMutableData       *sendData;
    NSNumber            *bytesRead;
    NSNumber            *bytesWritten;
}

@end

@implementation BonjourBrowser

static BonjourBrowser *_instance = nil;

#pragma mark - Lifecycle
+ (BonjourBrowser*)sharedBrowser {
    
    if (_instance == nil) {
        _instance = [[self alloc] init];
    }
    
    return _instance;
}

- (id)init {
    self = [super init];
    
    if (self != nil) {
        // depending on your configuration, you could optionally create the service browser here
        services = [[NSMutableArray alloc] init];
    }
    
    return self;
}

#pragma mark - Methods
- (void)browseForHelp {
    if (browser == nil) {
        browser = [[NSNetServiceBrowser alloc] init];
    }
    
    browser.delegate = self;
    [browser searchForServicesOfType:@"_associateHelp._tcp." 
                            inDomain:@""];
    
    [Utils postNotifification:kBrowseStartNotification];
}

- (NSArray*)availableServices {
    return (NSArray*)services;
}

- (void)connectToService:(NSNetService*)service {
    // set the services delegate so the
    // app gets the resolve callbacks
    service.delegate = self;
    [service resolveWithTimeout:5.0];
    
    // inform the front-end
    [Utils postNotifification:kConnectStartNotification];
    
    // halt browsing since the app 
    // is connecting to a service
    [browser stop];
}

- (void)sendHelpRequest:(HelpRequest*)request {
    
    if (sendData == nil) {
        sendData = [[NSMutableData alloc] init];
    }
    
    // convert the request to NSData (using NSKeyedArchiver/NSCoding)
    NSData *requestData = [NSKeyedArchiver 
                           archivedDataWithRootObject:request];
    
    [sendData appendData:requestData];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] 
                            forMode:NSDefaultRunLoopMode];
}

#pragma mark - NSNetServiceBrowserDelegate
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
           didFindService:(NSNetService *)aNetService 
               moreComing:(BOOL)moreComing {
    
    if (![services containsObject:aNetService]) {
        [services addObject:aNetService];
    }

    if (moreComing == NO) {
        [Utils postNotifification:kBrowseSuccessNotification];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
             didNotSearch:(NSDictionary *)errorDict {
    // alert the user and stop the browser
    [Utils postNotifification:kBrowseErrorNotification];
    [browser stop];
}

- (void)netServiceBrowserDidStopSearch:
        (NSNetServiceBrowser *)aNetServiceBrowser {
    
    // clears browser and delegate
    // a new browser will be created
    // if search is initiated again
    browser = nil;
    [Utils postNotifification:kSearchStoppedNotification];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
         didRemoveService:(NSNetService *)aNetService 
               moreComing:(BOOL)moreComing {

    [services removeObject:aNetService];
    if (moreComing == NO) {
        [Utils postNotifification:kServiceRemovedNotification];
    }
}

#pragma mark - NSNetServiceDelegate
- (void)netService:(NSNetService *)sender 
     didNotResolve:(NSDictionary *)errorDict {
    [Utils postNotifification:kConnectErrorNotification];
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender {    
    NSInputStream *tmpIS;
    NSOutputStream *tmpOS;
    BOOL error = NO;
    
    // this application requires both streams
    // if we don't get them both, that poses
    // a problem
    if (![sender getInputStream:&tmpIS outputStream:&tmpOS]) {
        error = YES;
    }
    
    // Input Stream
    if (tmpIS != NULL ) {
        inputStream = tmpIS;
        inputStream.delegate = self;
        [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] 
                               forMode:NSDefaultRunLoopMode];
        if (inputStream.streamStatus == NSStreamStatusNotOpen) {
            [inputStream open];
        }
        
    } else {
        error = YES;
    }
    
    // Output Stream
    if (tmpOS != NULL ) {
        outputStream = tmpOS;
        outputStream.delegate = self;
        //output stream is scheduled in runloop when it is needed
        if (outputStream.streamStatus == NSStreamStatusNotOpen) {
            [outputStream open];
        }
        
    } else {
        error = YES;
    }
    
    if (error == NO) {
        [Utils postNotifification:kConnectSuccessNotification];
    } else {
        [Utils postNotifification:kConnectErrorNotification];
    }
}

#pragma mark - NSStreamDelegate
- (void)stream:(NSStream *)aStream 
   handleEvent:(NSStreamEvent)eventCode {
    
    switch (eventCode) {
        case NSStreamEventHasSpaceAvailable: {
            if (aStream == outputStream) {
                if ([sendData length] > 0) {
                    uint8_t *readBytes = 
                        (uint8_t *)[sendData mutableBytes];
                    
                    // keep track of pointer position
                    readBytes += [bytesWritten intValue];
                    int data_len = [sendData length];
                    
                    unsigned int len = 
                        ((data_len - [bytesWritten intValue] >= 1024) ?
                         1024 : (data_len-[bytesWritten intValue]));
                    
                    uint8_t buffer[len];
                    (void)memcpy(buffer, readBytes, len);
                    len = [(NSOutputStream*)aStream 
                                write:(const uint8_t *)buffer 
                            maxLength:len];
                    
                    bytesWritten = 
                        [NSNumber 
                         numberWithInt:([bytesWritten intValue]+len)];
                    
                    if ([sendData length] == [bytesWritten intValue]) {
                        sendData = nil;
                        [outputStream 
                            removeFromRunLoop:[NSRunLoop currentRunLoop] 
                                      forMode:NSDefaultRunLoopMode];
                    }
                    
                    if ([bytesWritten intValue] == -1) {
                        NSLog(@"Error writing data.");
                    }
                }
            }
            break;
        }
        case NSStreamEventOpenCompleted:
            // you could optionally set a BOOL here
            // indicating that the different streams
            // are ready to read or write
            break;
        case NSStreamEventHasBytesAvailable:
            if (aStream == inputStream) {
                if (receiveData == nil) {
                    receiveData = [[NSMutableData alloc] init];
                }
                uint8_t buffer[1024];
                unsigned int len = 0;
                len = [(NSInputStream *)aStream read:buffer 
                                           maxLength:1024];
                
                if(len) {
                    [receiveData appendBytes:(const void *)buffer
                                      length:len];
                    
                    bytesRead = [NSNumber 
                                 numberWithInt:([bytesRead intValue]+len)];
                    
                    if (![inputStream hasBytesAvailable]) {
                        
                        // you could optionally keep the 'transaction'
                        // state stored so that you could determine
                        // which object you are expecting.
                        HelpResponse *response;
                        @try {
                            response = 
                                [NSKeyedUnarchiver 
                                 unarchiveObjectWithData:receiveData];
                            
                            NSDictionary *info = 
                                [NSDictionary 
                                 dictionaryWithObject:response 
                                 forKey:kNotificationResultSet];
                            
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:kHelpResponseNotification
                             object:nil
                             userInfo:info];
                            
                        }
                        @catch (NSException *exception) {
                            NSLog(@"Exception unarchiving data.");
                            NSLog(@"Possible missing / corrupt data.");
                        }
                        @finally {
                            // clean up
                            receiveData = nil;
                            bytesRead = nil;
                        }
                        
                    }
                } else {
                    NSLog(@"No data found in buffer.");
                }
            }
            break;
            
        case NSStreamEventEndEncountered: {
            NSLog(@"End of stream reached");
            [aStream close];
            [aStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        }
            break;
            
        case NSStreamEventErrorOccurred:
            if (aStream == inputStream) {
                NSLog(@"Input stream error: %@", [aStream streamError]);
            } else {
                NSLog(@"Output stream error: %@", [aStream streamError]);
            }
            break;
            
        default:
            break;
    }
}

@end