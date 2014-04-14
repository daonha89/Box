//
//  Daos.m
//  LanManager
//
//  Created by FSU17_FX-RD on 4/14/14.
//  Copyright (c) 2014 FSU17_FX-RD. All rights reserved.
//

#import "Daos.h"
#import "FMDatabase.h"
#define kDefaultDBName @"chatTB.sqlite"
@implementation Daos
static Daos * _sharedDBManager;

+ (Daos *) defaultDBManager {
	if (!_sharedDBManager) {
		_sharedDBManager = [[Daos alloc] init];
	}
	return _sharedDBManager;
}
- (id) init {
    self = [super init];
    if (self) {
        int state = [self initializeDBWithName:kDefaultDBName];
        if (state == -1) {
            NSLog(@"no");
        } else {
            NSLog(@"ok");
        }
    }
    return self;
}
- (int) initializeDBWithName : (NSString *) name {
    if (!name) {
		return -1;
	}
    NSString * docp = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
	_name = [docp stringByAppendingString:[NSString stringWithFormat:@"/%@",name]];
	NSFileManager * fileManager = [NSFileManager defaultManager];
    BOOL exist = [fileManager fileExistsAtPath:_name];
    [self connect];
    if (!exist) {
        return 0;
    } else {
        return 1;
	}
    
}
- (void) connect {
	if (!_dataBase) {
		_dataBase = [[FMDatabase alloc] initWithPath:_name];
	}
	if (![_dataBase open]) {
		NSLog(@"Not open");
	}
}
- (void) close {
	[_dataBase close];
    _sharedDBManager = nil;
}

@end
