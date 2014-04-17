//
//  ChatDB.h
//  LanManager
//
//  Created by FSU17_FX-RD on 4/14/14.
//  Copyright (c) 2014 FSU17_FX-RD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Daos.h"
#import "ChatDetail.h"
@class FMDatabase;
@interface ChatDB : NSObject
{
    FMDatabase * _db;
}
- (void) createDataBase;
- (BOOL)insertOrUpdate:(ChatDetail *)dicInfo;
- (NSMutableArray* )getListchat;
- (NSMutableArray * )listChat:(MCPeerID*)peerId;
@end
