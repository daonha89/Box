//
//  ChatDB.m
//  LanManager
//
//  Created by FSU17_FX-RD on 4/14/14.
//  Copyright (c) 2014 FSU17_FX-RD. All rights reserved.
//

#import "ChatDB.h"
#import "FMDatabase.h"

#define kUserTableName @"chat"
static NSString * const SQL_INSERT_OR_REPLACE
= @"INSERT OR REPLACE INTO chat (key, value) VALUES (?, ?);";

@implementation ChatDB
- (id) init {
    self = [super init];
    if (self) {
        _db = [Daos defaultDBManager].dataBase;
    }
    return self;
}
- (void) createDataBase {
    FMResultSet * set = [_db executeQuery:[NSString stringWithFormat:@"select count(*) from sqlite_master where type ='table' and name = '%@'",kUserTableName]];
    
    [set next];
    
    NSInteger count = [set intForColumnIndex:0];
    
    BOOL existTable = !!count;
    
    if (existTable) {
    } else {
        NSString * sql = @"CREATE TABLE chat (idMail int IDENTITY(1,1) PRIMARY KEY, key TEXT NOT NULL, value TEXT NOT NULL)";
        BOOL res = [_db executeUpdate:sql];
        if (!res) {
        } else {
        }
    }
}
- (BOOL)insertOrUpdate:(ChatDetail *)dicInfo  {
   BOOL isSave =  [_db executeUpdate:SQL_INSERT_OR_REPLACE,dicInfo.peerID,dicInfo.content];
    return isSave;
}
- (NSMutableArray* )getListchat {
    NSMutableArray *listSMS = [[NSMutableArray alloc] init];
    FMResultSet *s = [_db executeQuery:@"SELECT * FROM chat"];
    while ([s next]) {
        ChatDetail *getSMS = [[ChatDetail alloc] init];
        getSMS.peerID = [s stringForColumn:@"key"];
        getSMS.content = [s stringForColumn:@"value"];
        [listSMS addObject:getSMS];
    }
    return listSMS;

}
@end
