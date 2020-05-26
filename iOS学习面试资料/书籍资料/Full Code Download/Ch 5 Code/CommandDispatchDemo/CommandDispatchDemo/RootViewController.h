//
//  RootViewController.h
//  CommandDispatchDemo
//
//  Created by Jack Cox on 9/10/11.
//  
//

#import <UIKit/UIKit.h>

@interface RootViewController : UITableViewController {
    NSDictionary    *feed;
    
}
@property (nonatomic, retain)  NSDictionary    *feed;

- (void)requestVideoFeed;
- (IBAction)refresh:(id)sender;

@end
