//
//  NetworkErrorViewController.h
//
//  Created by Jack Cox on 8/8/11.
//  
//

#import <UIKit/UIKit.h>

@class BaseCommand;

#import "InterstitialViewController.h"

@interface NetworkErrorViewController : InterstitialViewController {
    BOOL retryFlag;
}

/**
 sent from the retry button on the view
 **/
- (IBAction)retry:(id)sender;
/** 
 send from the abort button on the view
 **/
- (IBAction)abort:(id)sender;

@end
