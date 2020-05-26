//
//  Bonjour.m
//  associate-help
//
//  Created by Nathan Jones on 6/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Bonjour.h"
#import "Utils.h"
#import <netinet/in.h>
#import <sys/socket.h>

@interface Bonjour() {
    NSNetService    *service;
    NSInputStream   *inputStream;
    NSOutputStream  *outputStream;
    
    NSMutableData   *receiveData;
    NSMutableData   *sendData;
    
    NSNumber        *bytesRead;
    NSNumber        *bytesWritten;
    
    uint16_t        port;
    CFSocketRef     ipv4socket;
    CFSocketRef     ipv6socket;
}

- (BOOL)setupListeningSocket;

- (void)stopListening;

- (void)handleNewConnectionWithInputStream:(NSInputStream*)istr 
                              outputStream:(NSOutputStream*)ostr;
@end

static void ListeningSocketCallback(CFSocketRef s,
                                    CFSocketCallBackType type,
                                    CFDataRef address,
                                    const void *data, 
                                    void *info);

@implementation Bonjour

static Bonjour *_instance = nil;

#pragma mark - Lifecycle
+ (Bonjour*)sharedPublisher {
    
    if (_instance == nil) {
        _instance = [[self alloc] init];
    }
    
    return _instance;
}

- (id)init {
    self = [super init];
    
    if (self != nil) {
        // depending on your configuration
        // you could optionally create the service here
    }
    
    return self;
}

#pragma mark - Methods
- (BOOL)publishServiceWithName:(NSString*)name {
    
    // setup the listening socket for connection attempts
    // and determine a port on which to advertise the service
    if (![self setupListeningSocket]) {
        return NO;
    }
    
    // create the service for publishing
    // this type should be registered - iana.org
    service = [[NSNetService alloc] 
                    initWithDomain:@"" 
                              type:@"_associateHelp._tcp." 
                              name:name
                              port:port];
    
    if (service == nil) {
        return NO;
    }
    
    service.delegate = self;
    
    // Publish service
    [Utils postNotifification:kPublishBonjourStartNotification];
    [service publish];
    
    return YES;
}

- (void)stopService {
    [service stop];
}

- (void)sendHelpResponse:(HelpResponse*)response {
    if (sendData == nil) {
        sendData = [[NSMutableData alloc] init];
    }
    NSData *responseData = 
        [NSKeyedArchiver archivedDataWithRootObject:response];
    
    [sendData appendData:responseData];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] 
                            forMode:NSDefaultRunLoopMode];
    
    // associate is going to help customer
    // stop the service so they aren't discoverable
    // while with the customer
    if (response.response == YES) {        
        [self stopService];
    }
}

#pragma mark - NSNetServiceDelegate
- (void)netServiceDidPublish:(NSNetService *)sender {
    [Utils postNotifification:kPublishBonjourSuccessNotification];
}

- (void)netService:(NSNetService *)sender 
     didNotPublish:(NSDictionary *)errorDict {
    // typically you would pass along the errorDict
    // object or some form of error messaging
    [Utils postNotifification:kPublishBonjourErrorNotification];
}

- (void)netServiceDidStop:(NSNetService *)sender {
    // reset port so a new one is assigned
    port = 0;
    CFRelease(ipv4socket);
    CFRelease(ipv6socket);
    
    [Utils postNotifification:kStopBonjourSuccessNotification];
}

#pragma mark - NSStreamDelegate
- (void)stream:(NSStream *)aStream 
   handleEvent:(NSStreamEvent)eventCode {
    
    switch (eventCode) {
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
                        HelpRequest *request;
                        @try {
                            request = 
                            [NSKeyedUnarchiver        
                             unarchiveObjectWithData:receiveData];
                            
                            NSDictionary *info = 
                            [NSDictionary 
                             dictionaryWithObject:request              
                             forKey:kNotificationResultSet];
                            
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:
                             kHelpRequestedNotification
                             object:nil
                             userInfo:info];
                            
                        }
                        @catch (NSException *exception) {
                            NSString *msg = 
                            @"Exception while unarchiving request data.";
                            NSLog(@"%@", msg);
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
        
        case NSStreamEventHasSpaceAvailable: {
            if (aStream == outputStream) {
                // send data if there is some pending
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
            if (aStream == inputStream) {
                NSLog(@"Input Stream Opened");
            } else {
                NSLog(@"Output Stream Opened");
            }
            break;
            
        case NSStreamEventEndEncountered: {
            [aStream close];
            [aStream removeFromRunLoop:[NSRunLoop currentRunLoop] 
                               forMode:NSDefaultRunLoopMode];
            break;
        }
        
        case NSStreamEventErrorOccurred:
            if (aStream == inputStream) {
                NSLog(@"Input error: %@", [aStream streamError]);
            } else {
                NSLog(@"Output error: %@", [aStream streamError]);
            }
            break;
            
        default:
            if (aStream == inputStream) {
                NSLog(@"Input default error: %@", [aStream streamError]);
            } else {
                NSLog(@"Output default error: %@", [aStream streamError]);
            }
            break;
    }
}

#pragma mark - Private Methods
- (BOOL)setupListeningSocket {
    // adapted from: Cocoa Echo application on developer portal. example is available at
    // https://developer.apple.com/library/mac/#samplecode/CocoaEcho/Introduction/Intro.html#//apple_ref/doc/uid/DTS10003603-Intro-DontLinkElementID_2
    CFSocketContext socketCtxt = {0, (__bridge void*)self, NULL, NULL, NULL};
    ipv4socket = CFSocketCreate(kCFAllocatorDefault, 
                                PF_INET, 
                                SOCK_STREAM, 
                                IPPROTO_TCP, 
                                kCFSocketAcceptCallBack, 
                                (CFSocketCallBack)&BonjourServerAcceptCallBack, 
                                &socketCtxt);
    
    ipv6socket = CFSocketCreate(kCFAllocatorDefault, 
                                PF_INET6, 
                                SOCK_STREAM, 
                                IPPROTO_TCP, 
                                kCFSocketAcceptCallBack, 
                                (CFSocketCallBack)&BonjourServerAcceptCallBack, 
                                &socketCtxt);
    
    if (ipv4socket == NULL || ipv6socket == NULL) {
        if (ipv4socket) CFRelease(ipv4socket);
        if (ipv6socket) CFRelease(ipv6socket);
        ipv4socket = NULL;
        ipv6socket = NULL;
        return NO;
    }
    
    int yes = 1;
    setsockopt(CFSocketGetNative(ipv4socket), 
               SOL_SOCKET, 
               SO_REUSEADDR, 
               (void *)&yes, 
               sizeof(yes));
    
    setsockopt(CFSocketGetNative(ipv6socket), 
               SOL_SOCKET, 
               SO_REUSEADDR, 
               (void *)&yes, 
               sizeof(yes));
    
    // set up the IPv4 address
    // if port is 0, causes the kernel to choose a port
    struct sockaddr_in addr4;
    memset(&addr4, 0, sizeof(addr4));
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    addr4.sin_port = htons(port);
    addr4.sin_addr.s_addr = htonl(INADDR_ANY);
    NSData *address4 = [NSData dataWithBytes:&addr4 length:sizeof(addr4)];
    
    if (kCFSocketSuccess != CFSocketSetAddress(ipv4socket, 
                                               (__bridge CFDataRef)address4)) {
        
        NSLog(@"Error setting ipv4 socket address");
        if (ipv4socket) CFRelease(ipv4socket);
        if (ipv6socket) CFRelease(ipv6socket);
        ipv4socket = NULL;
        ipv6socket = NULL;
        return NO;
    }
    
    if (port == 0) {
        // get the port number, port will be used for IPv6 address and service
        NSData *addr = (__bridge NSData *)CFSocketCopyAddress(ipv4socket);
        memcpy(&addr4, [addr bytes], [addr length]);
        port = ntohs(addr4.sin_port);
    }
    
    // set up the IPv6 address
    struct sockaddr_in6 addr6;
    memset(&addr6, 0, sizeof(addr6));
    addr6.sin6_len = sizeof(addr6);
    addr6.sin6_family = AF_INET6;
    addr6.sin6_port = htons(port);
    memcpy(&(addr6.sin6_addr), &in6addr_any, sizeof(addr6.sin6_addr));
    NSData *address6 = [NSData dataWithBytes:&addr6 length:sizeof(addr6)];
    
    if (kCFSocketSuccess != CFSocketSetAddress(ipv6socket, 
                                               (__bridge CFDataRef)address6)) {
        
        NSLog(@"Error setting ipv6 socket address");
        if (ipv4socket) CFRelease(ipv4socket);
        if (ipv6socket) CFRelease(ipv6socket);
        ipv4socket = NULL;
        ipv6socket = NULL;
        return NO;
    }
    
    // set up sources and add sockets to run loop
    CFRunLoopRef cfrl = CFRunLoopGetCurrent();
    CFRunLoopSourceRef src4 = CFSocketCreateRunLoopSource(kCFAllocatorDefault,
                                                          ipv4socket,
                                                          0);
    
    CFRunLoopAddSource(cfrl, src4, kCFRunLoopCommonModes);
    CFRelease(src4);
    
    CFRunLoopSourceRef src6 = CFSocketCreateRunLoopSource(kCFAllocatorDefault,
                                                          ipv6socket,
                                                          0);
    
    CFRunLoopAddSource(cfrl, src6, kCFRunLoopCommonModes);
    CFRelease(src6);
    return YES;
}

- (void)stopListening {
    // stop listening
    CFSocketInvalidate(ipv4socket);
    CFRelease(ipv4socket);
    
    CFSocketInvalidate(ipv6socket);
    CFRelease(ipv6socket);
}

- (void)handleNewConnectionWithInputStream:(NSInputStream*)istr 
                              outputStream:(NSOutputStream*)ostr {
    inputStream = istr;
    outputStream = ostr;
    
    inputStream.delegate = self;
    outputStream.delegate = self;
    
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] 
                           forMode:NSDefaultRunLoopMode];
    // output stream is scheduled in the runloop when it is needed

    
    if (inputStream.streamStatus == NSStreamStatusNotOpen) {
        [inputStream open];
    }
    
    if (outputStream.streamStatus == NSStreamStatusNotOpen) {
        [outputStream open];
    }
    
}

static void BonjourServerAcceptCallBack (CFSocketRef socket, 
                                         CFSocketCallBackType type, 
                                         CFDataRef address, 
                                         const void *data, 
                                         void *info) {
    
    Bonjour *server = (__bridge Bonjour*)info;
    if (type == kCFSocketAcceptCallBack) { 
        // AcceptCallBack: data is pointer to a CFSocketNativeHandle
        CFSocketNativeHandle socketHandle 
            = *(CFSocketNativeHandle *)data;

        CFReadStreamRef readStream = NULL;
        CFWriteStreamRef writeStream = NULL;
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, 
                                     socketHandle, 
                                     &readStream, 
                                     &writeStream);
        
        if (readStream && writeStream) {
            CFReadStreamSetProperty
                (readStream, 
                 kCFStreamPropertyShouldCloseNativeSocket, 
                 kCFBooleanTrue);
            
            CFWriteStreamSetProperty
                (writeStream, 
                 kCFStreamPropertyShouldCloseNativeSocket, 
                 kCFBooleanTrue);
            
            NSInputStream *is = (__bridge NSInputStream*)readStream;
            NSOutputStream *os = (__bridge NSOutputStream*)writeStream;
            [server handleNewConnectionWithInputStream:is
                                          outputStream:os];
            
        } else {
            // encountered failure
            // no need for socket anymore
            close(socketHandle);
        }
        
        // clean up
        if (readStream) {
            CFRelease(readStream);
        }
        
        if (writeStream) {
            CFRelease(writeStream);
        }
        
    }
}
@end