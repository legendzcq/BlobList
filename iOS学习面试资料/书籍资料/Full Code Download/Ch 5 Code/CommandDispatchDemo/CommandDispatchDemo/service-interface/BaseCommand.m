//
//  BaseCommand.m

//
//  Created by Jack Cox on 7/12/11.
//

#import "BaseCommand.h"
#import "XMLReader.h"

#import "CommandDispatchDemoAppDelegate.h"

@implementation BaseCommand
@synthesize results;
@synthesize status;
@synthesize reason;
@synthesize completionNotificationName;
@synthesize token;
@synthesize requestTimeoutInterval;

- (id)init
{
    self = [super init];
    if (self) {
        completionNotificationName = @"operationCompletion";
        status = kInProcess;
        // set the default network timeout
        self.requestTimeoutInterval = [NSNumber numberWithInt:30];
    }
    
    return self;
}

- (void) dealloc {

    [results release];
    [completionNotificationName release];
    [reason release];
    [token release];
    [requestTimeoutInterval release];
    [super dealloc];
}


/**
 Provide the notification name for any login needed notification
 **/
+ (NSString *)getLoginNotificationName  {
    return @"loginRequired";
}
/**
 provide the notification name for any network error
 **/
+ (NSString *)getNetworkErrorNotificationname {
    return @"networkError";
}

/**
 Add the listener as an observer of the completion of the command
 **/
- (void) listenForMyCompletion:(id)listener selector:(SEL)selector {
    
    // Check to see that the listener does respond to the selector. It is easier to find selector typo's if it is checked here rather than when the notification fires
    if ([listener respondsToSelector:selector]) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        // make sure the listener only gets 1 notification
        [nc removeObserver:listener name:self.completionNotificationName object:nil];
        // Add the object as a listener
        [nc addObserver:listener selector:selector name:self.completionNotificationName object:nil];
    } else {
        NSLog(@"Warning:  not registering completion listener because it does not support the specified selector");
    }
}

/**
 Removes the listener as listening for command completion for this command
 **/
- (void) stopListeningForMyCompletion:(id)listener {
    [[NSNotificationCenter defaultCenter] removeObserver:listener name:self.completionNotificationName object:nil];
}
/**
 Send a completion notification with the command object and the results in the userInfo property of the notification
 **/
- (void) sendCompletionNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:self.completionNotificationName object:self userInfo:nil];
}
/**
 Send a completion notification with a failure status.  The notification includes a copy of the command and the results, if any
 **/
- (void) sendCompletionFailureNotification {
    self.status = kFailure;
    BaseCommand *copy = [self copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:self.completionNotificationName object:copy userInfo:nil];

}
/**
 Send a notification that a network error occured
 **/
- (void) sendNetworkErrorNotification {
    BaseCommand *copy = [self copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:[BaseCommand getNetworkErrorNotificationname] object:copy userInfo:nil];

}
/**
 Send a notification that a login is needed
 **/
- (void) sendLoginNeededNotification {
    BaseCommand *copy = [self copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:[BaseCommand getLoginNotificationName] object:copy userInfo:nil];

}
/**
 Stub main for the NSOperation command.
 **/
- (void)main {
    NSLog(@"Starting operation");
}

/**
 Called by sub-classes to create the request object and to initialize it with the proper timeout values
 **/
- (NSMutableURLRequest *) createRequestObject:(NSURL *)url {
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:url
																 cachePolicy:NSURLCacheStorageAllowed
															 timeoutInterval:[self.requestTimeoutInterval doubleValue]] autorelease];
    return request;
    
}

/**
 Tests the response status and the error code to see if the call was successful.  If unsuccessful, this method, or the methods it calls create an error notification
 **/
- (BOOL)wasCallSuccessful:(NSHTTPURLResponse *)response 
                    error:(NSError *)error {
    return (([self isNoError:error]) && [self isHttpReponseCodeOK:response]);
}


/**
 Checks the response code to see if things were successful.  Only a 200 status is a successful call.
 **/
- (BOOL)isHttpReponseCodeOK:(NSHTTPURLResponse *)response {
    NSLog(@"response.statusCode=%i",[response statusCode] );//403=forbidden (bad token), 500=server error (such as DB), 200=OK
    if ([response statusCode] != 200) {
        switch ([response statusCode]) {
            case 403:
            case 0 : // Youtube returns a 0 if the call is not authenticated
                [self sendLoginNeededNotification];
                break;
            default:
                // error status other than 200.
                self.reason = [NSString stringWithFormat:@"Http Status: %d", [response statusCode]];
                [self sendNetworkErrorNotification];
                break;
        }
        return NO;
    } else {
        return YES;
    }
}
/**
 Check the NSError object returned to see if it indicates an error
 **/
- (BOOL)isNoError:(NSError *)error  {
    if (error) {
        NSLog(@"command error:\n%@",error);
        self.status = kFailure;
        self.reason = [error description];
        [self sendNetworkErrorNotification];
        return NO;
    }
    return YES;
}

/**
 Take the return data, parse it as XML and send a completion notification
 **/
- (void)buildDictionaryAndSendCompletionNotif:(NSData *)myData {
    NSError *theError = nil;

    NSDictionary * dictionary = [XMLReader dictionaryForXMLData:myData error:&theError];
    
    if (theError == nil) {
        self.status = kSuccess;
        self.results = dictionary;
    } else {
        self.status = kFailure;
    }

    [self sendCompletionNotification];
}

/**
 Add the Google specific header to the HTTP request with the authorization information
 **/
- (void)signRequest:(NSMutableURLRequest *)request {
    if (self.token != nil) {
        [request addValue:[NSString stringWithFormat:@"GoogleLogin auth=%@", self.token] 
        forHTTPHeaderField:@"Authorization"];
    }
}

/**
 Send a synchronous request, starting the activity spinner on the status bar
 **/
- (NSData *)sendSynchronousRequest:(NSMutableURLRequest *)request response_p:(NSHTTPURLResponse **)response_p error:(NSError **)error_p {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSData* myData = [NSURLConnection sendSynchronousRequest:request returningResponse:&(*response_p) error:&(*error_p)];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    return myData;
}

/**
 Returns true if the request has an auth token
 **/
- (BOOL)isUserLoggedIn {
    if (self.token == nil) {
        [self sendLoginNeededNotification];
        return NO;
    }
    return YES;
}

#pragma mark   NSCopying protocol

/**
 Copy the Command object so that it can be resubmitted if necessary
 **/
- (id)copyWithZone:(NSZone *)zone {
    BaseCommand *newOp = [[[[self class] allocWithZone:zone] init] autorelease];
    newOp.token = token;
    newOp.reason = reason;
    newOp.results = results;
    newOp.status = status;
    return newOp;
}

/**
 Add to command to an operation queue.  Another way to do this is to have the queue be a static member of the BaseCommand method and create it on the first call
 **/
- (void) enqueueOperation {
    CommandDispatchDemoAppDelegate *delegate = (CommandDispatchDemoAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [delegate.opQueue addOperation:self];
    
    return;
}

@end
