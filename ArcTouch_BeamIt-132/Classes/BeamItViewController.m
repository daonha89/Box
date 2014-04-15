/*
 
 File: BeamItViewController.m
 Abstract: Main View Controller. Responsible for updating the screen when the devices list changes.
							     Also responsible for properly handling the selecion of an item in the list.
 Version: 2.0
 
 Disclaimer: IMPORTANT:  This ArcTouch software is supplied to you by 
 ArcTouch Inc. ("ArcTouch") in consideration of your agreement to the 
 following terms, and your use, installation, modification or redistribution 
 of this ArcTouch software constitutes acceptance of these terms.  
 If you do not agree with these terms, please do not use, install, 
 modify or redistribute this ArcTouch software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, ArcTouch grants you a personal, non-exclusive
 license, under ArcTouch's copyrights in this original ArcTouch software (the
 "ArcTouch Software"), to use, reproduce, modify and redistribute the ArcTouch
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the ArcTouch Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the ArcTouch Software.
 Neither the name, trademarks, service marks or logos of ArcTouch Inc. may
 be used to endorse or promote products derived from the ArcTouch Software
 without specific prior written permission from ArcTouch.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by ArcTouch herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the ArcTouch Software may be incorporated.
 
 The ArcTouch Software is provided by ArcTouch on an "AS IS" basis.  ARCTOUCH
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE ARCTOUCH SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL ARCTOUCH BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE ARCTOUCH SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF ARCTOUCH HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 ArcTouch Inc. All Rights Reserved.
 */

#import "BeamItViewController.h"
#import "ContactDataProvider.h"
#import "Device.h"
#import "DeviceCell.h"

#define MY_CONTACT_ID_PROP @"MY_CONTACT_ID"
#define AVAILABLE_SOUND_FILE_NAME "available"
#define UNAVAILABLE_SOUND_FILE_NAME "unavailable"

#define ALERTVIEW_BUTTONS_OK NSLocalizedString(@"alertview.buttons.ok", @"Ok Button")
#define ALERTVIEW_BUTTONS_YES NSLocalizedString(@"alertview.buttons.yes", @"yes")
#define ALERTVIEW_BUTTONS_NO NSLocalizedString(@"alertview.buttons.no", @"no")
#define ALERTVIEW_BUTTONS_CANCEL NSLocalizedString(@"alertview.buttons.cancel", @"cancel")

#define PROGRESS_ALERT_VIEW_TAG 0
#define PROMPT_ALERT_VIEW_TAG 1
#define INFORMATION_ALERT_VIEW_TAG 2


@interface BeamItViewController () <ABPeoplePickerNavigationControllerDelegate>

- (IBAction)configureMyContact:(id)sender;

@end

@implementation BeamItViewController {
    UIAlertView *_alertViewCommunicationState;

    MessageCompletionBlock _leftOrCenterButtonCompletion;
    MessageCompletionBlock _rightButtonCompletion;
}

@synthesize devicesTable;
@synthesize noDevicesLabel;
@synthesize backgroundImageHighlighted;
@synthesize myContactLabel;
@synthesize myDeviceNameLabel;

#pragma mark - UIViewController Life Cycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
	_sessionManager = [[SessionManager alloc] init];

    _dataHandler = [[DataHandler alloc] initWithDataProvider:[self createSpecificDataProvider] sessionManager:_sessionManager];
    _dataHandler.delegate = self;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceAvailable:) name:NOTIFICATION_DEVICE_AVAILABLE object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceUnavailable:) name:NOTIFICATION_DEVICE_UNAVAILABLE object:nil];
	
	[_sessionManager start];

	[self loadSounds];
	
	myContactID = [self getMyContactID];
	if (myContactID != 0) {
		[self refreshMyContactButton];
	} else {
		myContactMustBeDefined = YES;
	}
	
	devicesTable.separatorColor = [UIColor grayColor];
	
	myDeviceNameLabel.text = [[UIDevice currentDevice] name];
	
	backgroundImageHighlighted.alpha = 0.6;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:5];
    [UIView setAnimationRepeatCount:9999999];
	[UIView setAnimationRepeatAutoreverses:YES];
    backgroundImageHighlighted.alpha = 0;
    [UIView commitAnimations];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
	if (myContactMustBeDefined) {
		[self showDefineContactDialog];
		[self configureMyContact:nil];
		myContactMustBeDefined = NO;
	}
}

- (void)showDefineContactDialog {
	UIAlertView *confirmationView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CHOOSE_CONTACT_TITLE", @"Defining my contact dialog title.")
															   message:NSLocalizedString(@"CHOOSE_CONTACT_PROMPT", @"Defining my contact dialog text.")
															  delegate:nil
													 cancelButtonTitle:NSLocalizedString(@"CHOOSE_CONTACT_OK_BTN", @"Defining my contact dialog button.")
													 otherButtonTitles:nil];
	
	[confirmationView show];
}

- (void)loadSounds {
	CFBundleRef mainBundle = CFBundleGetMainBundle();
	
	CFURLRef availableURL = CFBundleCopyResourceURL(mainBundle, CFSTR(AVAILABLE_SOUND_FILE_NAME), CFSTR("aiff"), NULL);
	CFURLRef unavailableURL = CFBundleCopyResourceURL(mainBundle, CFSTR(UNAVAILABLE_SOUND_FILE_NAME), CFSTR("aiff"), NULL);
	
	AudioServicesCreateSystemSoundID(availableURL, &availableSound);
	AudioServicesCreateSystemSoundID(unavailableURL, &unavailableSound);
	
	CFRelease(availableURL);
	CFRelease(unavailableURL);
}

- (NSObject<DataProvider> *)createSpecificDataProvider {
	return [[ContactDataProvider alloc] initWithMainViewController:self];
}

- (void)deviceAvailable:(NSNotification *)notification {
	[devicesTable reloadData];
	[self updateTableVisibility];
	AudioServicesPlaySystemSound(availableSound);
}

- (void)deviceUnavailable:(NSNotification *)notification {
	[devicesTable reloadData];
	[self updateTableVisibility];
	AudioServicesPlaySystemSound(unavailableSound);
}

- (void)updateTableVisibility {
	noDevicesLabel.hidden = _sessionManager.devicesAvailable.count > 0;
	devicesTable.hidden = _sessionManager.devicesAvailable.count == 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _sessionManager.devicesAvailable.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"DeviceCell";
    
    DeviceCell *cell = (DeviceCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[DeviceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
	
	Device *device = ((Device *) [_sessionManager.devicesAvailable objectAtIndex:indexPath.row]);
	cell.device = device;
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	DeviceCell *cell = (DeviceCell *) [tableView cellForRowAtIndexPath:indexPath];
	Device *device = cell.device;
	
	[_dataHandler sendToDevice:device];
	
	[devicesTable deselectRowAtIndexPath:indexPath animated:YES];
}

- (ABRecordID)getMyContactID {
	NSString *loadedContactID = [[NSUserDefaults standardUserDefaults] objectForKey:MY_CONTACT_ID_PROP];
	if (loadedContactID)
		return [loadedContactID intValue];
	else
		return 0;
}

- (void)saveMyContactID:(ABRecordID)recordID {
	[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%d", recordID] forKey:MY_CONTACT_ID_PROP];
}

- (void)refreshMyContactButton {
	if (myContactID != 0) {
        
        if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized) {
            [self resetMyContactInformation];
        } else {
            CFErrorRef *error;
            ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);
            
            if (addressBook) {
                ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        if (granted) {
                            ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, myContactID);
                            if (person != NULL) {
                                NSString *personName = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty));
                                myContactLabel.text = personName;
                            } else {
                                [self resetMyContactInformation];
                            }
                            CFRelease(addressBook);
                        }
                    });
                });
            }
        }
	}
}

- (void)resetMyContactInformation {
    myContactID = 0;
    [self saveMyContactID:myContactID];
    myContactMustBeDefined = YES;
}

- (IBAction)configureMyContact:(id)sender {
	ABPeoplePickerNavigationController *peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
	peoplePicker.peoplePickerDelegate = self;
	peoplePicker.navigationBar.topItem.title = NSLocalizedString(@"CHOOSE_CONTACT_TITLE", @"Defining my contact title.");
    [self presentViewController:peoplePicker animated:YES completion:nil];
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
	[self showDefineContactDialog];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker 
	  shouldContinueAfterSelectingPerson:(ABRecordRef)person {
		
	myContactID = ABRecordGetRecordID(person);
	[self refreshMyContactButton];
	[self saveMyContactID:myContactID];
	
    [self dismissViewControllerAnimated:YES completion:nil];
	
    return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker 
	  shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier{
    return NO;
}


#pragma mark - DataHandlerStatusMessageDelegate <NSObject>

- (void)dataHandlerShouldDismissCurrentMessage:(DataHandler *)dataHandler {
    [self runBlockInMainQueue:^{
        if (_alertViewCommunicationState) {
            _leftOrCenterButtonCompletion = nil;
            _rightButtonCompletion = nil;
            
            _alertViewCommunicationState.delegate = nil;
            
            [_alertViewCommunicationState dismissWithClickedButtonIndex:0 animated:NO];
            _alertViewCommunicationState = nil;
        }
    }];
}

- (void)dataHandler:(DataHandler *)dataHandler shouldDisplayMessage:(NSString *)message withTitle:(NSString *)title leftOrCenterButtonCompletion:(MessageCompletionBlock)leftOrCenterButtonCompletion rightButtonCompletion:(MessageCompletionBlock)rightButtonCompletion {
    
    [self runBlockInMainQueue:^{
        [self dataHandlerShouldDismissCurrentMessage:dataHandler];
        
        _leftOrCenterButtonCompletion = leftOrCenterButtonCompletion;
        _rightButtonCompletion = rightButtonCompletion;
        
        int alertViewTag;
        
        NSString *cancelButtonTitle;
        NSString *otherButtonTitle = nil;
        
        if (leftOrCenterButtonCompletion && rightButtonCompletion) {
            alertViewTag = PROMPT_ALERT_VIEW_TAG;
            cancelButtonTitle = ALERTVIEW_BUTTONS_NO;
            otherButtonTitle = ALERTVIEW_BUTTONS_YES;
        } else if (leftOrCenterButtonCompletion) {
            alertViewTag = PROGRESS_ALERT_VIEW_TAG;
            cancelButtonTitle = ALERTVIEW_BUTTONS_CANCEL;
        } else {
            alertViewTag = INFORMATION_ALERT_VIEW_TAG;
            cancelButtonTitle = ALERTVIEW_BUTTONS_OK;
        }
        
        _alertViewCommunicationState = [[UIAlertView alloc] initWithTitle:title
                                                                  message:message
                                                                 delegate:self
                                                        cancelButtonTitle:cancelButtonTitle
                                                        otherButtonTitles:otherButtonTitle, nil];
        
        
        _alertViewCommunicationState.tag = alertViewTag;
        _alertViewCommunicationState.delegate = self;
        [_alertViewCommunicationState show];
    }];
}


#pragma mark - UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (alertView.tag) {
        case PROMPT_ALERT_VIEW_TAG:
            if (buttonIndex == 0) {
                [self executeBlockSafely:_leftOrCenterButtonCompletion];
            } else {
                [self executeBlockSafely:_rightButtonCompletion];
            }
            break;
        case PROGRESS_ALERT_VIEW_TAG:
            [self executeBlockSafely:_leftOrCenterButtonCompletion];
            break;
        case INFORMATION_ALERT_VIEW_TAG:
            [self executeBlockSafely:_rightButtonCompletion];
            break;
    }
}


#pragma mark - Utils Methods

- (void)runBlockInMainQueue:(void (^)(void))block {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

- (void)executeBlockSafely:(void (^)(void))block {
    if (block) {
        block();
    }
}


#pragma mark - Memory Management Methods

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_sessionManager stop];
    [_sessionManager.session disconnect];
}

@end
