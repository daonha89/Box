//
//  AppDelegate.h
//  LanManager
//
//  Created by FSU17_FX-RD on 4/11/14.
//  Copyright (c) 2014 FSU17_FX-RD. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCManager.h"
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) MCManager *mcManager;
@end
