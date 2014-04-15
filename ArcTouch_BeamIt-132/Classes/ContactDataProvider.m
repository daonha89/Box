/*
 
 File: ContactDataProvider.m
 Abstract: Implementation of the DataProvider specifically for beaming contacts.
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

#import "ContactDataProvider.h"

#define CONTACTS_ACCESS_NOT_AUTHORIZED_ERROR_MESSAGE NSLocalizedString(@"alertview.contacts.access.error", @"Error message")
#define CONTACTS_ACCESS_NOT_AUTHORIZED_ERROR_OK_BUTTON NSLocalizedString(@"alertview.buttons.ok", @"Ok Button")

@implementation ContactDataProvider

- (id)initWithMainViewController:(BeamItViewController *)viewController {
	self = [super init];
	
	if (self) {
		mainViewController = viewController;
	}
	
	return self;
}

- (void)prepareDataWithCompletion:(DataProviderCompletionBlock)completion {
    _dataProviderCompletionBlock = completion;
	
#ifdef MY_CONTACT_ONLY
	[self sendMyContact];
#else 
	// The use may choose between send its own contact or any other contact from the address book
	UIActionSheet *contactTypeActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self 
														  cancelButtonTitle:@"Cancel" 
													 destructiveButtonTitle:nil 
														  otherButtonTitles:@"My Contact", @"Another Contact", nil];
	[contactTypeActionSheet showInView:mainViewController.view];
	[contactTypeActionSheet release];
#endif
	
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		[self sendMyContact];
	} else if (buttonIndex == 1) {
		// Displays the AddressBook picker dialog that allows the user to select a contact
		ABPeoplePickerNavigationController *peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
		peoplePicker.peoplePickerDelegate = self;
        [mainViewController presentViewController:peoplePicker animated:YES completion:nil];
	}
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
	if ([mainViewController getMyContactID] == 0) {
		UIControl *firstButtom = [[actionSheet subviews] objectAtIndex:0];
		firstButtom.enabled = NO;
	}
}

- (void)sendMyContact {
    [mainViewController dismissViewControllerAnimated:YES completion:nil];
	
    if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized) {
        [[[UIAlertView alloc] initWithTitle:nil message:CONTACTS_ACCESS_NOT_AUTHORIZED_ERROR_MESSAGE delegate:self cancelButtonTitle:CONTACTS_ACCESS_NOT_AUTHORIZED_ERROR_OK_BUTTON otherButtonTitles: nil] show];
        
    } else {
        CFErrorRef *error;
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);
        
        if (addressBook) {
            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if (granted) {
                        ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, [mainViewController getMyContactID]);
                        [self sendContact:person];
                        CFRelease(addressBook);
                    }
                });
            });
        }
    }
}

- (void)sendContact:(ABRecordRef)person {
	// Serializes the contact
	contactData = [ABRecordSerializer personToData:person];
	
	// Returns serialized contact and name to the DataHandler
	contactLabel = (NSString*)CFBridgingRelease(ABRecordCopyCompositeName(person));
	if (_dataProviderCompletionBlock) {
        _dataProviderCompletionBlock();
        _dataProviderCompletionBlock = nil;
    }
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
    [mainViewController dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    
    [mainViewController dismissViewControllerAnimated:YES completion:nil];
	[self sendContact:person];
	
    return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker 
	  shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier{
    return NO;
}

- (NSString *)getLabelOfDataToSend {
	return contactLabel;
}

- (NSData *)getDataToSend {
	return contactData;
}

- (BOOL)storeData:(NSData *)data withCompletion:(DataProviderCompletionBlock)completion {
	// Deserializes data received and create a new contact
	ABRecordRef newPerson = [ABRecordSerializer createPersonFromData:data];
	
	if(newPerson != NULL) {
        [self runBlockInMainQueueIfNecessary:^{
            _dataProviderCompletionBlock = completion;
            
            ABUnknownPersonViewController *addPersonViewController = [[ABUnknownPersonViewController alloc] init];
            addPersonViewController.unknownPersonViewDelegate = self;
            addPersonViewController.displayedPerson = newPerson;
            addPersonViewController.allowsActions = NO;
            addPersonViewController.allowsAddingToAddressBook = YES;
            
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:addPersonViewController];
            addPersonViewController.navigationItem.title = @"Contact received";
            UIBarButtonItem *cancelButton =  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self action:@selector(cancelContact:)];
            addPersonViewController.navigationItem.leftBarButtonItem = cancelButton;
            [mainViewController presentViewController:navController animated:YES completion:nil];
            
            CFRelease(newPerson);
        }];
		
		return YES;
	} else {
		return NO;
	}
}

- (void)cancelContact:(id)sender {
    [mainViewController dismissViewControllerAnimated:YES completion:nil];
    _dataProviderCompletionBlock();
}

- (void)unknownPersonViewController:(ABUnknownPersonViewController *)unknownPersonView didResolveToPerson:(ABRecordRef)person {
    [mainViewController dismissViewControllerAnimated:YES completion:nil];
    _dataProviderCompletionBlock();
}

#pragma mark - Util Methods

- (void)runBlockInMainQueueIfNecessary:(void (^)(void))block {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}


@end
