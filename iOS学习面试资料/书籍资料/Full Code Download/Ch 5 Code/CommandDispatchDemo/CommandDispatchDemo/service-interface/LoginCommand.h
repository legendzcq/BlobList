//
//  LoginCommand.h
//
//  Created by Jack Cox on 8/5/11.
//  
//

#import "BaseCommand.h"

@interface LoginCommand : BaseCommand {
    NSString *user;
    NSString *pwd;
}

@property (retain, nonatomic) NSString * user;
@property (retain, nonatomic) NSString * pwd;
@end
