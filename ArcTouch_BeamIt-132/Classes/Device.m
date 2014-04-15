/*
 
 File: Device.m
 Abstract: Represents a phisical device.
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

#import "Device.h"
#import "SessionManager.h"

#define CONNECTION_TIMEOUT 30

@interface Device() {
	MCSession *_session;
    MCNearbyServiceBrowser *_serviceBrowser;
}
@end

@implementation Device

- (id)initWithSession:(MCSession *)openSession browserService:(MCNearbyServiceBrowser *)serviceBrowser peer:(MCPeerID *)peer {
	self = [super init];
	if (self) {
		_session = openSession;
        _serviceBrowser = serviceBrowser;
		_peerID = peer;
	}
	return self;
}

- (BOOL)isEqual:(id)object {
	return object && ([object isKindOfClass:[Device class]]) && ([((Device *) object).peerID isEqual:_peerID]);
}

- (void)connect {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerConnectionSuccessfull:) name:NOTIFICATION_DEVICE_CONNECTED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerConnectionFailed:) name:NOTIFICATION_DEVICE_CONNECTION_FAILED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerConnectionFailed:) name:NOTIFICATION_DEVICE_UNAVAILABLE object:nil];

    [_serviceBrowser invitePeer:_peerID toSession:_session withContext:nil timeout:CONNECTION_TIMEOUT];    
}

- (void)triggerConnectionSuccessfull:(NSNotification *)notification {
	Device *device = [notification.userInfo objectForKey:DEVICE_KEY];
	
	if ([self isEqual:device] && _delegate) {
        [_delegate connectionStablishedWithDevice:self];
        _delegate = nil;
	}
}

- (void)triggerConnectionFailed:(NSNotification *)notification {
	Device *device = [notification.userInfo objectForKey:DEVICE_KEY];
	
	if ([self isEqual:device] && _delegate) {
        [_delegate connectionNotStablishedWithDevice:self];
        _delegate = nil;
	}
}

- (void)cancelConnection {
    [_session cancelConnectPeer:_peerID];
}

- (BOOL)isConnected {
    return [_session.connectedPeers containsObject:_peerID];
}

- (BOOL)sendData:(NSData *)data error:(NSError **)error {
    return [_session sendData:data toPeers:[NSArray arrayWithObject:_peerID] withMode:MCSessionSendDataReliable error:error];
}


#pragma mark - Accessor Methods Overriden

- (NSString *)name {
    return _peerID.displayName;
}


#pragma mark - Memory Management Methods

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
