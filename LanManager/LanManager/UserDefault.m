//
//  UserDefault.m
//  LanManager
//
//  Created by FSU17_FX-RD on 4/14/14.
//  Copyright (c) 2014 FSU17_FX-RD. All rights reserved.
//

#import "UserDefault.h"

@implementation UserDefault
- (void)objectWithKey:(NSString *)strKey value:(id)value {
    [self setObject:value forKey:strKey];
    [self synchronize];
}
- (id)resultObject:(NSString *)strKey {
    id object = [self objectForKey:strKey];
    return object;
}
@end
