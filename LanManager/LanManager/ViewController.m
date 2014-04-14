//
//  ViewController.m
//  LanManager
//
//  Created by FSU17_FX-RD on 4/11/14.
//  Copyright (c) 2014 FSU17_FX-RD. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "UserDefault.h"
#import "ChatViewController.h"
@interface ViewController ()
{
    MCPeerID *p_peerId;
}
@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) NSMutableArray *arrConnectedDevices;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"List Device";
    
    [self visibility];
    UserDefault  *user = [UserDefault new];
    NSMutableArray * array = [user resultObject:@"arrayDevice"];
    if (array.count > 0) {
        _arrConnectedDevices = [NSMutableArray arrayWithArray:array];
    }
    else {
         _arrConnectedDevices = [[NSMutableArray alloc] init];
    }
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)visibility {
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [[_appDelegate mcManager] setupPeerAndSessionWithDisplayName:[UIDevice currentDevice].name];
    [_appDelegate.mcManager advertiseSelf:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peerDidChangeStateWithNotification:)
                                                 name:@"MCDidChangeStateNotification"
                                               object:nil];

}
- ( IBAction)addDevice:(id)sender {
    [self browse];
}
- (void)browse {
    [[_appDelegate mcManager] setupMCBrowser];
    [[[_appDelegate mcManager] browser] setDelegate:self];
    [self presentViewController:[[_appDelegate mcManager] browser] animated:YES completion:nil];

}
#pragma Notification Peer
-(void)peerDidChangeStateWithNotification:(NSNotification *)notification {
   p_peerId = [[notification userInfo] objectForKey:@"peerID"];
    NSString *peerDisplayName = p_peerId.displayName;
    MCSessionState state = [[[notification userInfo] objectForKey:@"state"] intValue];
    
    if (state != MCSessionStateConnecting) {
        if (state == MCSessionStateConnected) {
            [_arrConnectedDevices addObject:peerDisplayName];
        }
        else if (state == MCSessionStateNotConnected){
            if ([_arrConnectedDevices count] > 0) {
                int indexOfPeer = [_arrConnectedDevices indexOfObject:peerDisplayName];
                [_arrConnectedDevices removeObjectAtIndex:indexOfPeer];
            }
        }
        [ self.tbvDevice reloadData];
        // save array device
        UserDefault  *user = [UserDefault new];
        [user objectWithKey:@"arrayDevice" value:_arrConnectedDevices];
        BOOL peersExist = ([[_appDelegate.mcManager.session connectedPeers] count] == 0);
    }

}
#pragma mark - UITableView Delegate and Datasource method implementation

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [_arrConnectedDevices count];
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellIdentifier"];
    }
    cell.textLabel.text = [_arrConnectedDevices objectAtIndex:indexPath.row];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"chat" sender:Nil];
}
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([sender isEqualToString:@"chat"]) {
        ChatViewController *chat = (ChatViewController *)segue.destinationViewController;
        chat.peerID = p_peerId;
        
    }
}
#pragma mark - MCBrowserViewControllerDelegate method implementation

-(void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController{
    [_appDelegate.mcManager.browser dismissViewControllerAnimated:YES completion:nil];
}


-(void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController{
    [_appDelegate.mcManager.browser dismissViewControllerAnimated:YES completion:nil];
}

@end
