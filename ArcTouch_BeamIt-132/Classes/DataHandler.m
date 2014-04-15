/*
 
 File: DataHandler.h
 Abstract: Concentrates the management of the messages related to the application specific protocol. It retrieves the data to send and store from the DataProvider.
 This is and example of the protocol (4 first bytes = command):
 
 Peer A -> SENDFoo bar
 Peer B -> ACPT
 Peer A -> SIZE8
 Peer B -> ACKN
 Peer A -> Beam It!
 Peer B -> SUCS
 
 Refer to DataHandler.m for more details.
 
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

#import "DataHandler.h"
#import "SoundLibrary.h"
#import "Message.h"

#define PROCESSING_TAG 0
#define CONFIRMATION_RETRY_TAG 1
#define CONFIRMATION_RECEIVE_TAG 2

#define RECEIVED_ERROR_MESSAGE NSLocalizedString(@"RECEIVED_ERROR_ERROR", @"Received an error message")
#define PEER_CANCELLED_ERROR NSLocalizedString(@"PEER_CANCELLED_ERROR", @"Transfer cancelled")
#define RECEIVED_BUSY_ERROR NSLocalizedString(@"RECEIVED_BUSY_ERROR", @"Receiver is busy")
#define RECEIVE_VIEW_TITLE NSLocalizedString(@"RECEIVE_VIEW_TITLE", @"Dialog title when receiving data")
#define RECEIVE_VIEW_PROMPT NSLocalizedString(@"RECEIVE_VIEW_PROMPT", @"Dialog text when receiving data")
#define RECEPTION_ERROR NSLocalizedString(@"RECEPTION_ERROR", @"Error receiving data")
#define RETRY_VIEW_TITLE NSLocalizedString(@"RETRY_VIEW_TITLE", @"Transfer refused dialog title")
#define RETRY_VIEW_PROMPT NSLocalizedString(@"RETRY_VIEW_PROMPT", @"Transfer refused dialog text")
#define SUCCESS_VIEW_TITLE NSLocalizedString(@"SUCCESS_VIEW_TITLE", @"Transfer completed dialog title.")
#define SEND_SUCCESS_MESSAGE NSLocalizedString(@"SEND_SUCCESS_MESSAGE", @"Transfer completed dialog text.")
#define WAITING_FOR_ACCEPTANCE_PROCESS NSLocalizedString(@"WAITING_FOR_ACCEPTANCE_PROCESS", @"Waiting for acceptance")
#define SENDING_PROCESS NSLocalizedString(@"SENDING_PROCESS", @"Sending data dialog")
#define RECEIVING_PROCESS NSLocalizedString(@"RECEIVING_PROCESS", @"Receiving data dialog")
#define SENDING_PROCESS NSLocalizedString(@"SENDING_PROCESS", @"Sending data dialog")
#define CONNECTION_PROCESS NSLocalizedString(@"CONNECTION_PROCESS", @"Connecting dialog")
#define CONNECTION_ERROR NSLocalizedString(@"CONNECTION_ERROR", "Error when connecting to peer")
#define UNEXPECTED_COMMAND_ERROR NSLocalizedString(@"UNEXPECTED_COMMAND_ERROR", @"Received unexpected command")
#define ERROR_VIEW_TITLE NSLocalizedString(@"ERROR_VIEW_TITLE", @"Error dialog title")

@implementation DataHandler {
    NSObject<DataProvider> *_dataProvider;
    SessionManager *_sessionManager;
    
    DataHandlerState _currentState;
    Command _lastCommandReceived;
	Device *_currentPairedDevice;

	UIAlertView *_currentPopUpView;
	
	int _bytesToReceive;
}

#pragma mark - Initialization Methods

- (id)initWithDataProvider:(NSObject<DataProvider> *)provider sessionManager:(SessionManager *)sessionManager {
	self = [super init];
	
	if (self) {
        _dataProvider = provider;
        _sessionManager = sessionManager;
        _sessionManager.delegate = self;
        
		_currentState = DHSNone;
		_lastCommandReceived = notInitialized;
	}
	
	return self;
}


#pragma mark - Public Methods

- (void)sendToDevice:(Device *)device {
	_currentState = DHSSending;
	_currentPairedDevice = device;
	
	[_dataProvider prepareDataWithCompletion:^{
        [self dataPrepared];
    }];
}


#pragma mark SessionManagerDelagate Methods

- (void)receiveData:(NSData *)data fromDevice:(Device *)device {
	Message *message = [[Message alloc] initWithData:data];
    
	if (device) {
		switch (_currentState) {
			case DHSNone:
				_currentState = DHSReceiving;
				_currentPairedDevice = device;
				
				[self handleReceivingData:data];
				break;
			case DHSReceiving:
				if (![_currentPairedDevice isEqual:device] || (message.command == requestingPermissionToSend)) {
					[self sendBusyData:device];
				} else {
					[self handleReceivingData:data];
				}
				break;
			case DHSSending:
				if (![_currentPairedDevice isEqual:device] || (message.command == requestingPermissionToSend)) {
					[self sendBusyData:device];
				} else {
					[self handleSendingData:data];
				}
				break;
			default:
				break;
		}
	}
}


#pragma mark - Accessors Methods

- (void)updateLastCommandReceived:(Command)command {
	_lastCommandReceived = command;
}


#pragma mark - Communication Handlers

- (void)handleReceivingData:(NSData *)data {
    Message *message = [[Message alloc] initWithData:data];
	
    BOOL hasSpecificError = [self message:message checkForSpecificErrorsWithErrorCompletion:^(NSString *errorMessage) {
        [self throwError:errorMessage];
    }];
    
    if (!hasSpecificError) {
		if (_lastCommandReceived == notInitialized) {
			[self processRequestingPermissionCommandWithMessage:message];
		} else if (_lastCommandReceived == requestingPermissionToSend) {
            [self processInfoSizeCommandWithMessage:message];
		} else if (_lastCommandReceived == infoSize) {
			[self processContactInformationReceivedWithData:data];
		} else {
			[self processUnexpectedCommandError];
		}
	}
}

- (void)handleSendingData:(NSData *)data {
    Message *message = [[Message alloc] initWithData:data];
	
	BOOL hasSpecificError = [self message:message checkForSpecificErrorsWithErrorCompletion:^(NSString *errorMessage) {
        [self throwError:errorMessage];
    }];
    
    if (!hasSpecificError) {
        if (_lastCommandReceived == notInitialized) {
			[self prepareInfoSizeCommandWithMessage:message];
		} else if (_lastCommandReceived == acceptContact) {
			[self prepareContactInfoToSendWithMessage:message];
		} else if (_lastCommandReceived == acknowledge) {
			[self processConfirmationReceivedWithMessage:message];
		} else {
			[self processUnexpectedCommandError];
		}
	}
}

- (void)processUnexpectedCommandError {
    [self sendErrorData];
    [self throwUnexpectedCommandError];
}

- (void)processRequestingPermissionCommandWithMessage:(Message *)message {
    if (message.command != requestingPermissionToSend) {
        [self processUnexpectedCommandError];
    } else {
        [[SoundLibrary sharedInstance] playSound:requestSound];
        
        MessageCompletionBlock rejectBlock = ^{
            [self sendRejectData];
            [self cleanCurrentState];
            
        };
        
        MessageCompletionBlock acceptBlock = ^{
            [self sendAcceptData];
        };
        
        NSString *messageText = [NSString stringWithFormat:RECEIVE_VIEW_PROMPT, _currentPairedDevice.name, message.message];
        [self.delegate dataHandler:self
              shouldDisplayMessage:messageText
                         withTitle:RECEIVE_VIEW_TITLE
      leftOrCenterButtonCompletion:rejectBlock
             rightButtonCompletion:acceptBlock];
        
        [self updateLastCommandReceived:message.command];
    }
}

- (void)processInfoSizeCommandWithMessage:(Message *)message {
    if (message.command != infoSize) {
        [self processUnexpectedCommandError];
    } else {
        _bytesToReceive = [message.message intValue];
        [self sendAcknowledgeData];
        
        [self updateLastCommandReceived:message.command];
    }
}

- (void)processContactInformationReceivedWithData:(NSData *)data {
    if (_bytesToReceive == [data length]) {
        BOOL dataCanBeStored = [_dataProvider storeData:data withCompletion:^{
            [self cleanCurrentState];
        }];
        
        if (dataCanBeStored) {
            [self sendSuccessData];
            [self.delegate dataHandlerShouldDismissCurrentMessage:self];
            [[SoundLibrary sharedInstance] playSound:receivedSound];
        } else {
            [self sendErrorData];
            [self throwError:[NSString stringWithFormat:RECEPTION_ERROR, _currentPairedDevice.name]];
        }
        
    } else {
        [self sendErrorData];
        [self throwError:[NSString stringWithFormat:RECEPTION_ERROR, _currentPairedDevice.name]];
    }
}

- (void)prepareInfoSizeCommandWithMessage:(Message *)message {
    if (message.command == acceptContact) {
        [self sendSizeData];
        [self updateLastCommandReceived:message.command];
    } else if (message.command == rejectContact) {
        MessageCompletionBlock rejectBlock = ^{
            [self cleanCurrentState];
        };
        
        MessageCompletionBlock acceptBlock = ^{
            dispatch_async(dispatch_queue_create("send_data_queue", NULL), ^{
                [self sendRequestData];
            });
        };
        
        NSString *messageText = [NSString stringWithFormat:RETRY_VIEW_PROMPT, _currentPairedDevice.name, [_dataProvider getLabelOfDataToSend]];
        
        [self.delegate dataHandler:self
              shouldDisplayMessage:messageText
                         withTitle:RETRY_VIEW_TITLE
      leftOrCenterButtonCompletion:rejectBlock
             rightButtonCompletion:acceptBlock];
    } else {
        [self processUnexpectedCommandError];
    }
}

- (void)prepareContactInfoToSendWithMessage:(Message *)message {
    if (message.command != acknowledge) {
        [self processUnexpectedCommandError];
    } else {
        [self sendRealData];
        [self updateLastCommandReceived:message.command];
    }
}

- (void)processConfirmationReceivedWithMessage:(Message *)message {
    if (message.command != success) {
        [self processUnexpectedCommandError];
    } else {
        [[SoundLibrary sharedInstance] playSound:sendSound];
        [self showMessageWithTitle:SUCCESS_VIEW_TITLE  message:[NSString stringWithFormat:SEND_SUCCESS_MESSAGE, [_dataProvider getLabelOfDataToSend], _currentPairedDevice.name]];
        [self cleanCurrentState];
    }
}


#pragma mark - Communication "Send" Methods

- (void)sendBusyData:(Device *)device {
	[device sendData:[self dataFromString:BEAM_IT_I_AM_BUSY] error:nil];
}

- (void)sendCancelData {
	[_currentPairedDevice sendData:[self dataFromString:BEAM_IT_CANCEL] error:nil];
}

- (void)sendErrorData {
	[_currentPairedDevice sendData:[self dataFromString:BEAM_IT_ERROR] error:nil];
}

- (void)sendRequestData {
	[self showProcess:[NSString stringWithFormat:WAITING_FOR_ACCEPTANCE_PROCESS, _currentPairedDevice.name]];
	NSString *strToSend = [NSString stringWithFormat:@"%@%@", BEAM_IT_REQUESTING_PERMISSION_TO_SEND, [_dataProvider getLabelOfDataToSend]];
	[_currentPairedDevice sendData:[self dataFromString:strToSend] error:nil];
}

- (void)sendSizeData {
	[self showProcess:SENDING_PROCESS];
	NSString *strToSend = [NSString stringWithFormat:@"%@%d", BEAM_IT_INFO_SIZE, [[_dataProvider getDataToSend] length]];
	[_currentPairedDevice sendData:[self dataFromString:strToSend] error:nil];
}

- (void)sendAcceptData {
	[_currentPairedDevice sendData:[self dataFromString:BEAM_IT_ACCEPT_CONTACT] error:nil];
}

- (void)sendRejectData {
	[_currentPairedDevice sendData:[self dataFromString:BEAM_IT_REJECT_CONTACT] error:nil];
}

- (void)sendAcknowledgeData {
	[self showProcess:RECEIVING_PROCESS];
	[_currentPairedDevice sendData:[self dataFromString:BEAM_IT_ACKNOWLEDGE] error:nil];
}

- (void)sendSuccessData {
	[_currentPairedDevice sendData:[self dataFromString:BEAM_IT_SUCCESS] error:nil];
}

- (void)sendRealData {
	[self showProcess:SENDING_PROCESS];
	[_currentPairedDevice sendData:[_dataProvider getDataToSend] error:nil];
}


#pragma mark - State Handler Methods

- (void)dataPrepared {
	[self showProcess:CONNECTION_PROCESS];
	
	if (![_currentPairedDevice isConnected]) {
        _currentPairedDevice.delegate = self;
		[_currentPairedDevice connect];
    }
	else {
		[self deviceConnected];
    }
}

- (void)deviceConnected {
	[self sendRequestData];
}


#pragma mark - Communication State UIAlertView Methods

- (void)deviceConnectionFailed {
	[self throwError:[NSString stringWithFormat:CONNECTION_ERROR, _currentPairedDevice.name]];
}

- (void)throwUnexpectedCommandError {
	[self throwError:[NSString stringWithFormat:UNEXPECTED_COMMAND_ERROR, _currentPairedDevice.name]];
}

- (void)showMessageWithTitle:(NSString *)title message:(NSString *)msg {
    [self.delegate dataHandler:self
          shouldDisplayMessage:msg
                     withTitle:title
  leftOrCenterButtonCompletion:nil
         rightButtonCompletion:nil];
}

- (void)throwError:(NSString *)message {
    [[SoundLibrary sharedInstance] playSound:errorSound];
	[self showMessageWithTitle:ERROR_VIEW_TITLE message:message];
	[self cleanCurrentState];
}

- (void)showProcess:(NSString *)message {
    MessageCompletionBlock cancelBlock = ^{
        if ([_currentPairedDevice isConnected]) {
            [self sendCancelData];
        }
        
        [self cleanCurrentState];
    };
    
    [self.delegate dataHandler:self
          shouldDisplayMessage:@"\n"
                     withTitle:message
  leftOrCenterButtonCompletion:cancelBlock
         rightButtonCompletion:nil];
}


#pragma mark - Util Methods

- (void)cleanCurrentState {
	_currentState = DHSNone;
	
	if (_currentPairedDevice) {
        _currentPairedDevice.delegate = nil;
		_currentPairedDevice = nil;
	}
	
	_lastCommandReceived = notInitialized;
	_bytesToReceive = 0;
}

- (NSData *)dataFromString:(NSString *)str {
	return [str dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)message:(Message *)message checkForSpecificErrorsWithErrorCompletion:(void (^)(NSString *))errorCompletion {
    BOOL hasError = YES;
    
    if (message.command == error) {
        errorCompletion([NSString stringWithFormat:RECEIVED_ERROR_MESSAGE, _currentPairedDevice.name]);
	} else if (message.command == cancel) {
        errorCompletion([NSString stringWithFormat:PEER_CANCELLED_ERROR, _currentPairedDevice.name]);
	} else if (message.command == iAmBusy) {
        errorCompletion([NSString stringWithFormat:RECEIVED_BUSY_ERROR, _currentPairedDevice.name]);
    } else {
        hasError = NO;
    }
    
    return hasError;
}


#pragma mark - DeviceStateDelegate Methods

- (void)connectionStablishedWithDevice:(Device *)device {
    [self deviceConnected];
}

- (void)connectionNotStablishedWithDevice:(Device *)device {
    [self deviceConnectionFailed];
}

@end
