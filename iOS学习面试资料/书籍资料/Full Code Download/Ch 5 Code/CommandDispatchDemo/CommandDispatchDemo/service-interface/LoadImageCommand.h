//
//  LoadImageCommand.h
//  CommandDispatchDemo
//
//  Created by Jack Cox on 9/22/11.
//  
//

#import "BaseCommand.h"

@interface LoadImageCommand : BaseCommand {
    NSString *imageUrl;
}

@property (nonatomic, retain) NSString *imageUrl;
@end
