//
//  ChatDetail.h
//  LanManager
//
//  Created by FSU17_FX-RD on 4/14/14.
//  Copyright (c) 2014 FSU17_FX-RD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
@interface ChatDetail : NSObject
@property (nonatomic,strong) NSString * content;
@property (nonatomic,weak) MCPeerID *peerID;
@end
