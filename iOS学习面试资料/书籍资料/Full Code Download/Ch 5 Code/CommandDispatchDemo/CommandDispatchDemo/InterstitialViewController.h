//
//  InterstitialViewController.h
//  
//  Base class for login and error listeners.  Handles the collection of failed commands
//
//  Created by Jack Cox on 8/10/11.

//

#import <UIKit/UIKit.h>

@class BaseCommand;

@interface InterstitialViewController : UIViewController {
    NSMutableArray  *triggeringCommands;    // the commands that triggered this view controller
    BOOL            diplayed;               // If true then the view is displayed
}

@property (retain, nonatomic)NSMutableArray  *triggeringCommands;
@property (assign, nonatomic)BOOL            displayed;
- (void) addTriggeringCommand:(BaseCommand *)cmd;
- (void)performSelectorAndClear:(SEL)selector ;

@end
