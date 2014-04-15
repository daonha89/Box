/*
 
 File: SoundLibrary.h
 Abstract: Creates a singleton object that handles all sounds in the app.
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

#import "SoundLibrary.h"
#import "AudioToolbox/AudioToolbox.h"

#define ERROR_SOUND_FILE_NAME "error"
#define RECEIVED_SOUND_FILE_NAME "received"
#define REQUEST_SOUND_FILE_NAME "request"
#define SEND_SOUND_FILE_NAME "sent"

@implementation SoundLibrary {
    SystemSoundID _errorSound;
	SystemSoundID _receivedSound;
	SystemSoundID _requestSound;
	SystemSoundID _sendSound;
}

static SoundLibrary *_sharedInstance;

#pragma mark - Singleton Initialization

+ (SoundLibrary *)sharedInstance {
	@synchronized([SoundLibrary class]){
        if (!_sharedInstance) {
            _sharedInstance = [[SoundLibrary alloc] init];
            [_sharedInstance loadSounds];
        }
        
        return _sharedInstance;
    }
}


#pragma mark - Initialization Methods

- (void)loadSounds {
    CFBundleRef mainBundle = CFBundleGetMainBundle();
	
	CFURLRef errorURL = CFBundleCopyResourceURL(mainBundle, CFSTR(ERROR_SOUND_FILE_NAME), CFSTR("aiff"), NULL);
	CFURLRef receivedURL = CFBundleCopyResourceURL(mainBundle, CFSTR(RECEIVED_SOUND_FILE_NAME), CFSTR("aiff"), NULL);
	CFURLRef requestURL = CFBundleCopyResourceURL(mainBundle, CFSTR(REQUEST_SOUND_FILE_NAME), CFSTR("aiff"), NULL);
	CFURLRef sendURL = CFBundleCopyResourceURL(mainBundle, CFSTR(SEND_SOUND_FILE_NAME), CFSTR("aiff"), NULL);
	
	AudioServicesCreateSystemSoundID(errorURL, &_errorSound);
	AudioServicesCreateSystemSoundID(receivedURL, &_receivedSound);
	AudioServicesCreateSystemSoundID(requestURL, &_requestSound);
	AudioServicesCreateSystemSoundID(sendURL, &_sendSound);
	
	CFRelease(errorURL);
	CFRelease(receivedURL);
	CFRelease(requestURL);
	CFRelease(sendURL);
}


#pragma mark - Public Methods

- (void)playSound:(Sound)sound {
    switch (sound) {
        case errorSound:
            AudioServicesPlaySystemSound(_errorSound);
            break;
        case receivedSound:
            AudioServicesPlaySystemSound(_receivedSound);
            break;
        case requestSound:
            AudioServicesPlaySystemSound(_requestSound);
            break;
        case sendSound:
            AudioServicesPlaySystemSound(_sendSound);
            break;
    }    
}


@end
