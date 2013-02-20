//  Based on code from AirplayKit by Andy Roth.

#import "APManager.h"
#import "TherePlayManager.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark - APManager

@interface APManager () <TherePlayManagerDelegate>
{
	TherePlayManager *airplay;
	NSTimer *runTimer;
}

@end

@implementation APManager

static APManager *instance;

+ (APManager *)sharedManager
{
	if (!instance) {
		instance = [[APManager alloc] init];
	}

	return instance;
}

#pragma mark - public methods

- (void)start
{
	if (!airplay) {
		airplay = [[TherePlayManager alloc] init];
        airplay.autoConnect = YES;
		airplay.delegate = self;
	}

	if (!airplay.connectedDevice) {
		[airplay activate];
	} else {
		[self therePlayManager:airplay didConnectToDevice:airplay.connectedDevice];
	}
}

- (void)stop
{
    [airplay deactivate];

	if (runTimer) {
		[runTimer invalidate];
		runTimer = nil;
	}
}

- (void)startStop
{
    if (runTimer) {
        [self stop];
    } else {
        [self start];
    }
}

- (void)reconnectUsingDeviceNameWithBlock:(void (^)(BOOL))block
{
    if (airplay.connectedDevice) {
        [airplay attemptConnectionToDeviceWithName:airplay.connectedDevice.displayName running:block];
    } else if (block) {
        block(NO);
    }
}

#pragma mark - private methods

- (void)sendScreen
{
	UIWindow *window = [UIApplication sharedApplication].keyWindow;
	if (!window) window = [UIApplication sharedApplication].windows[0];

    // get image of window
    UIGraphicsBeginImageContext(window.bounds.size);
	[window.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	[airplay.connectedDevice sendImage:image];
}

#pragma mark -
#pragma mark TherePlayManagerDelegate

- (void)therePlayManager:(TherePlayManager *)manager didConnectToDevice:(TherePlayDevice *)device
{
	// Start a timer to send the images
	runTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                target:self
                                              selector:@selector(sendScreen)
                                              userInfo:nil
                                               repeats:YES];
    [runTimer retain];
}

- (void)therePlayManager:(TherePlayManager *)manager didDisconnectFromDevice:(TherePlayDevice *)device
{
    [runTimer invalidate];
    runTimer = nil;
}

@end

