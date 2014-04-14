//
//  Daos.h
//  LanManager
//
//  Created by FSU17_FX-RD on 4/14/14.
//  Copyright (c) 2014 FSU17_FX-RD. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "FMDatabaseAdditions.h"
@class FMDatabase;
@interface Daos : NSObject
{
     NSString * _name;
}
@property (nonatomic, readonly) FMDatabase * dataBase;
+(Daos *) defaultDBManager;
- (void) close;
@end
