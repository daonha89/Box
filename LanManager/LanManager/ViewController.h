//
//  ViewController.h
//  LanManager
//
//  Created by FSU17_FX-RD on 4/11/14.
//  Copyright (c) 2014 FSU17_FX-RD. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (nonatomic,strong) IBOutlet UITableView *tbvDevice;
- ( IBAction)addDevice:(id)sender;
@end
