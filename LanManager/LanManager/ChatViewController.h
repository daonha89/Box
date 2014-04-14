//
//  ChatViewController.h
//  LanManager
//
//  Created by FSU17_FX-RD on 4/14/14.
//  Copyright (c) 2014 FSU17_FX-RD. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
@interface ChatViewController : UIViewController
@property (nonatomic,strong) MCPeerID *peerID;
@end
