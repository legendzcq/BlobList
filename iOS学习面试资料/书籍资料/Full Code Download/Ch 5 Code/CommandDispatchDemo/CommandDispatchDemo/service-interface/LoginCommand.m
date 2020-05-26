//
//  LoginCommand.m
//
//  The LoginCommand is a bit different from the other commands in that it doesn't check for login status and it doesn't throw a login exception if it failes.
//
//  Created by Jack Cox on 8/5/11.
//  
//

#import "LoginCommand.h"
#import "XMLReader.h"

@implementation LoginCommand
@synthesize user, pwd;
- (id)init
{
    self = [super init];
    if (self) {
        // Set the notification name, overriding that in BaseCommand
        completionNotificationName = @"loginAttemptComplete";
    }
    
    return self;
}
- (void) dealloc {
    [user release];
    [pwd release];
    [super dealloc];
    
}

/**
 Executed with the NSOperationQueue starts the execution of the command
 See http://code.google.com/apis/youtube/2.0/developers_guide_protocol_clientlogin.html for details on the request
 
 **/
- (void)main {
    pool = [[NSAutoreleasePool alloc] init];
    // Build the POST request object
    NSString *urlStr=@"https://www.google.com/accounts/ClientLogin";
    NSMutableURLRequest *request = [ self createRequestObject:[NSURL URLWithString:urlStr]];
    [request setHTTPMethod:@"POST"];
    [request addValue:@" application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    NSString *body = [NSString stringWithFormat:@"Email=%@&Passwd=%@&service=youtube&source=CD-Demo", self.user, self.pwd];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    // send the response
    NSHTTPURLResponse *response=nil;
    NSError *error=nil;
    NSData *myData  = [self sendSynchronousRequest:request response_p: &response error:&error];
    
    // Check the return
    if ((!error) && ([response statusCode] == 200)) {
        // if it looks like the authentication request succeeded
        NSString *responseString = [[NSString alloc] initWithData:myData encoding:NSUTF8StringEncoding];
        NSLog(@"responseString=%@",responseString);
        
        // Pull out the specific Auth part of the response body
        NSArray *objects = [responseString componentsSeparatedByString:@"\n"];
        NSString *authToken = nil;
        for(NSString *o in objects) {
            if ([o hasPrefix:@"Auth="]) {
                NSArray *parts = [o componentsSeparatedByString:@"="];
                authToken = [parts objectAtIndex:1];
            }
        }
        
        NSDictionary * dictionary = [NSDictionary dictionaryWithObjectsAndKeys:authToken,@"authToken", nil];
        self.status = kSuccess;
        self.results = dictionary;
        
        [self sendCompletionNotification];
        
        [responseString release];
        
    } else if ((error)) {
        // if some network error occurred
        [self sendNetworkErrorNotification];
    } else {
        // if things utterly failed.  This will go back to the login listener which will report the error and continue asking for login
        self.status = kFailure;
        [self sendCompletionNotification];
    }
    [pool drain];
}
/**
 Copy the attributes unique to the LoginCommand
 **/
- (id) copyWithZone:(NSZone *)zone {
    LoginCommand *newOp = [super copyWithZone:zone];
    newOp.user = user;
    newOp.pwd = pwd;
    return newOp;
}

@end
