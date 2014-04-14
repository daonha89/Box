//
//  UserDefault.h
//  LanManager
//
//  Created by FSU17_FX-RD on 4/14/14.
//  Copyright (c) 2014 FSU17_FX-RD. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserDefault : NSUserDefaults
- (void)objectWithKey:(NSString *)strKey value:(id)value;
- (id)resultObject:(NSString *)strKey;
@end
