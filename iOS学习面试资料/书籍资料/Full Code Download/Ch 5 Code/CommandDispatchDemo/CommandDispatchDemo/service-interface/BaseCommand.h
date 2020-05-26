//
//  BaseCommand.h
//
//  Created by Jack Cox on 7/12/11.
//  
//

#import <Foundation/Foundation.h>

#define kInProcess  0
#define kFailure   -1
#define kSuccess    1

@interface BaseCommand : NSOperation <NSCopying> {

    NSDictionary    *results;
    NSInteger       status;
    NSString        *reason;
    NSString        *completionNotificationName;
    NSString        *token;
    NSNumber        *requestTimeoutInterval;
    NSAutoreleasePool   *pool;
}

@property(nonatomic, retain)    NSDictionary    *results;
@property(nonatomic, retain)    NSString        *completionNotificationName;
@property(nonatomic)            NSInteger       status;
@property(nonatomic, retain)    NSString        *reason;
@property(nonatomic, retain)    NSString        *token;
@property(nonatomic, retain)    NSNumber        *requestTimeoutInterval;

/**
 Returns the default login needed notificationname
 **/
+ (NSString *)getLoginNotificationName;
/**
 Returns the default error notification name
 **/
+ (NSString *)getNetworkErrorNotificationname;


/**
 Registers the listener object as a listener for the completion of the operation.  When the notification is sent the listener's
 selector is called
 **/
- (void) listenForMyCompletion:(id)listener selector:(SEL)selector;
/**
 Remove the listener from observing for notifications for this command
 **/
- (void) stopListeningForMyCompletion:(id)listener;
/**
 Send the completion notification and response data on behalf of the operation
 **/
- (void) sendCompletionNotification;
/**
 Send a notification to listeners that the call failed.
 **/
- (void) sendCompletionFailureNotification;
/**
 Send the completion notificaiton with an error status on behalf of the operation
 **/
- (void) sendNetworkErrorNotification;

/**
 Send the login needed notification on behalf ot the operation
 **/
- (void) sendLoginNeededNotification;

/**
    Create a request object with timeout for the specified URL
 **/
- (NSMutableURLRequest *) createRequestObject:(NSURL *)url;

/**
    Returns true if the status code in the response is 200, otherwise it generates a completion notfication with an error status
 **/
- (BOOL) isHttpReponseCodeOK: (NSHTTPURLResponse*) response;

/**
    Returns true if no error occurred in the call.  Errors are typically caused by malformed URLs
    if an error occured a completion notification is sent with an error status
**/
- (BOOL) isNoError: (NSError*) error ;


/**
 Combines isHttpResponseCodeOk and isNoError into one convenience call
 **/
- (BOOL)wasCallSuccessful:(NSHTTPURLResponse *)response error:(NSError *)error ;

/**
 Handles the boilerplate operations when data is returned from the remote call.   Calls the completion handler with a good status code
 **/
- (void)buildDictionaryAndSendCompletionNotif:(NSData *)myData;

/**
 Turns sends the request, wrapped in calls to turn on the network busy spinner
 **/
- (NSData*) sendSynchronousRequest: (NSMutableURLRequest*) request response_p: (NSHTTPURLResponse**) response_p error: (NSError**) error_p ;
/**
 If login is needed this method send the login needed notification and returns false. Otherwise it returns true
 **/
- (BOOL) isUserLoggedIn;

/**
 Add the receiver to the queue of operations
 **/
- (void) enqueueOperation;
/**
 Add the correct authentication header to the operation
 **/
- (void) signRequest:(NSMutableURLRequest *)request;

@end
