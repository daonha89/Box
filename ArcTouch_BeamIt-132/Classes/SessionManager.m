
/*
 
 File: SessionManager.m
 Abstract: Delegate for the session and sends notifications when it changes.
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

#import "SessionManager.h"

#define BEAM_IT_SERVICE_TYPE @"beamit-service"


@implementation SessionManager {
    MCPeerID *_myDevicePeerId;
    DevicesManager *_devicesManager;
}

#pragma mark - Initialization Methods

- (id)init {
	self = [super init];
	
	if (self) {
		_devicesManager = [[DevicesManager alloc] init];
        
        _myDevicePeerId = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
        
        _session = [[MCSession alloc] initWithPeer:_myDevicePeerId securityIdentity:nil encryptionPreference:MCEncryptionNone];
        _session.delegate = self;
        
        _serviceAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:_myDevicePeerId
                                                               discoveryInfo:nil
                                                                 serviceType:BEAM_IT_SERVICE_TYPE];
        _serviceAdvertiser.delegate = self;
        
        _nearbyServiceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:_myDevicePeerId
                                                           serviceType:BEAM_IT_SERVICE_TYPE];
        _nearbyServiceBrowser.delegate = self;        
	}
	
	return self;
}


#pragma mark - Public Methods

- (void)start {
    [_serviceAdvertiser startAdvertisingPeer];
    [_nearbyServiceBrowser startBrowsingForPeers];
}

- (void)stop {
    [_serviceAdvertiser stopAdvertisingPeer];
    [_nearbyServiceBrowser stopBrowsingForPeers];
}

- (NSArray *)devicesAvailable {
    return _devicesManager.sortedDevices;
}


#pragma mark Device's List Control Methods

- (void)addDevice:(MCPeerID *)peerId {
    if ([self isRemotePeer:peerId]) {
        Device *device = [_devicesManager deviceWithID:peerId];
        if (!device) {
            device = [[Device alloc] initWithSession:_session browserService:_nearbyServiceBrowser peer:peerId];
            [_devicesManager addDevice:device];
        }
    }
}

- (void)removeDevice:(MCPeerID *)peerId {
    if ([self isRemotePeer:peerId]) {
        Device *device = [_devicesManager deviceWithID:peerId];
        [_devicesManager removeDevice:device];
    }
}

- (NSDictionary *)getDeviceInfo:(Device *)device {
	return [NSDictionary dictionaryWithObject:device forKey:DEVICE_KEY];
}

- (BOOL)isRemotePeer:(MCPeerID *)peerId {
    return ![_session.myPeerID isEqual:peerId];
}

#pragma mark - MCSessionDelegate Methods

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    Device *currentDevice = [_devicesManager deviceWithID:peerID];
    
	switch (state) {
		case MCSessionStateConnected:
            if (currentDevice) {
				[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DEVICE_CONNECTED object:nil userInfo:[self getDeviceInfo:currentDevice]];
			}
			break;
		case MCSessionStateConnecting:
            if (!currentDevice) {
				[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DEVICE_AVAILABLE object:nil userInfo:[self getDeviceInfo:currentDevice]];
			}
			break;
		case MCSessionStateNotConnected:
			break;
	}
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    Device *device = [_devicesManager deviceWithID:peerID];
    [self.delegate receiveData:data fromDevice:device];
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
}


#pragma mark - MCNearbyServiceAdvertiserDelegate Methods

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData*)context invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler {

    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_queue_create("invitation_handler_queue", NULL), ^(void){
        invitationHandler(YES, _session);
    });
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
}


#pragma mark - MCNearbyServiceBrowserDelegate Methods

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
    [self addDevice:peerID];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DEVICE_AVAILABLE object:nil userInfo:nil];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    [self removeDevice:peerID];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DEVICE_AVAILABLE object:nil userInfo:nil];
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error {
}

@end
