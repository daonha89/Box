//
//  ChatViewController.m
//  LanManager
//
//  Created by FSU17_FX-RD on 4/14/14.
//  Copyright (c) 2014 FSU17_FX-RD. All rights reserved.
//

#import "ChatViewController.h"
#import "UIBubbleTableView.h"
#import "UIBubbleTableViewDataSource.h"
#import "NSBubbleData.h"
#import "AppDelegate.h"
@interface ChatViewController ()
{
     IBOutlet UIView *textInputView;
    IBOutlet UIBubbleTableView *bubbleTable;
    IBOutlet UITextField *_textField;
     NSMutableArray *bubbleData;
}
@property (nonatomic, strong) AppDelegate *appDelegate;
@end

@implementation ChatViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _textField.delegate = self;
    bubbleData = [NSMutableArray new];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveDataWithNotification:)
                                                 name:@"MCDidReceiveDataNotification"
                                               object:nil];
    bubbleTable.bubbleDataSource = self;
    bubbleTable.snapInterval = 120;
    bubbleTable.showAvatars = YES;
    bubbleTable.typingBubble = NSBubbleTypingTypeNobody;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - UIBubbleTableViewDataSource implementation

- (NSInteger)rowsForBubbleTable:(UIBubbleTableView *)tableView
{
    return [bubbleData count];
}

- (NSBubbleData *)bubbleTableView:(UIBubbleTableView *)tableView dataForRow:(NSInteger)row
{
    return [bubbleData objectAtIndex:row];
}

#pragma mark - Keyboard events

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    [UIView animateWithDuration:0.2f animations:^{
        
        CGRect frame = textInputView.frame;
        frame.origin.y -= kbSize.height;
        textInputView.frame = frame;
        
        frame = bubbleTable.frame;
        frame.size.height -= kbSize.height;
        bubbleTable.frame = frame;
        [bubbleTable scrollBubbleViewToBottomAnimated:YES];
        [bubbleTable reloadData];

    }];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    [UIView animateWithDuration:0.2f animations:^{
        
        CGRect frame = textInputView.frame;
        frame.origin.y += kbSize.height;
        textInputView.frame = frame;
        
        frame = bubbleTable.frame;
        frame.size.height += kbSize.height;
        bubbleTable.frame = frame;
        [bubbleTable scrollBubbleViewToBottomAnimated:YES];
        [bubbleTable reloadData];

    }];
}
#pragma mark - Actions

- (IBAction)sayPressed:(id)sender
{
    bubbleTable.typingBubble = NSBubbleTypingTypeNobody;
    [self sendMyMessage];
    _textField.text = @"";
    [_textField resignFirstResponder];
}
-(void)sendMyMessage{
    NSData *dataToSend = [_textField.text dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *allPeers = _appDelegate.mcManager.session.connectedPeers;
    NSError *error;
    
    [_appDelegate.mcManager.session sendData:dataToSend
                                     toPeers:allPeers
                                    withMode:MCSessionSendDataReliable
                                       error:&error];
    
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    }
    NSBubbleData *sayBubble = [NSBubbleData dataWithText:_textField.text date:[NSDate dateWithTimeIntervalSinceNow:0] type:BubbleTypeMine];
    [bubbleData addObject:sayBubble];
    [bubbleTable scrollBubbleViewToBottomAnimated:YES];
    [bubbleTable reloadData];
}

#pragma UitextField Delegate 
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [_textField resignFirstResponder];
    return YES;
}
#pragma Notification

-(void)didReceiveDataWithNotification:(NSNotification *)notification {
    
    MCPeerID *peerID = [[notification userInfo] objectForKey:@"peerID"];
    NSString *peerDisplayName = peerID.displayName;
    
    NSData *receivedData = [[notification userInfo] objectForKey:@"data"];
    NSString *receivedText = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    NSBubbleData *sayBubble = [NSBubbleData dataWithText:[NSString stringWithFormat:@"%@ wrote:\n%@\n\n", peerDisplayName, receivedText] date:[NSDate dateWithTimeIntervalSinceNow:0] type:BubbleTypeMine];
    [bubbleData addObject:sayBubble];
    [bubbleTable scrollBubbleViewToBottomAnimated:YES];
    [bubbleTable reloadData];
    
}
@end
