//
//  InterstitialViewController.m
//  
//
//  Created by Jack Cox on 8/10/11.
//  
//

#import "InterstitialViewController.h"

@implementation InterstitialViewController

@synthesize triggeringCommands;
@synthesize displayed;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        triggeringCommands = [[NSMutableArray alloc] init];
    }
    return self;
}
/**
 Add a command to the list of triggering commands
 **/
- (void) addTriggeringCommand:(BaseCommand *)cmd {
    @synchronized(triggeringCommands) {
        [triggeringCommands addObject:cmd];
    }
}
/**
 Perform a selector on every command, then clear the list of triggering commands
 **/
- (void)performSelectorAndClear:(SEL)selector {
    @synchronized(triggeringCommands) {
        [triggeringCommands makeObjectsPerformSelector:selector];
        [triggeringCommands removeAllObjects];
    }
    
}

@end
