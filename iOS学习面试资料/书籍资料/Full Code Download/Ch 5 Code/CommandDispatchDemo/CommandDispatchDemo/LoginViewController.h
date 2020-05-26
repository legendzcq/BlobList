//
//  LoginViewController.h
//
//  Created by Jack Cox on 8/5/11.
//  
//

#import <UIKit/UIKit.h>
#import "InterstitialViewController.h"

@class BaseCommand;

@interface LoginViewController : InterstitialViewController <UITextFieldDelegate> {
    UITextField                 *userField;     // user name field
    UITextField                 *pwdField;      // password field
    UILabel                     *errorField;    // label to display error messages
    UIActivityIndicatorView     *spinner;       // activity spinner
    
}
@property (retain, nonatomic) IBOutlet  UIActivityIndicatorView     *spinner;
@property (retain, nonatomic) IBOutlet  UITextField                 *userField;
@property (retain, nonatomic) IBOutlet  UITextField                 *pwdField;  
@property (retain, nonatomic) IBOutlet  UILabel                     *errorField;
/**
 Action for the login button
 **/
- (IBAction) doLogin:(id)sender;
@end
