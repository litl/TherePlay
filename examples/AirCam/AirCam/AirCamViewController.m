//  Based on code from AirplayKit by Andy Roth.

#import "AirCamViewController.h"
#import "CameraImageHelper.h"
#import "DKToast.h"

@implementation AirCamViewController

- (void)viewDidLoad
{
	// Start the camera preview
	[CameraImageHelper startRunning];
	self.view = [CameraImageHelper previewWithBounds:self.view.bounds];

	// Listen for Airplay devices
	manager = [[TherePlayManager alloc] init];
    manager.autoConnect = YES;
	manager.delegate = self;
	[manager start];
}

- (void)dealloc
{
	[runTimer invalidate];
	[runTimer release];
	[manager release];
	[CameraImageHelper stopRunning];
	[super dealloc];
}

#pragma mark - AirplayManagerDelegate

- (void)therePlayManager:(TherePlayManager *)aManager didConnectToDevice:(TherePlayDevice *)device
{
	[DKToast showToast:@"Connected. Sending camera over Airplay." duration:DKToastDurationLong];

	manager.connectedDevice.imageQuality = 0;

	// Start a timer to send the images
	runTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1
                                                 target:self
                                               selector:@selector(sendImage)
                                               userInfo:nil
                                                repeats:YES] retain];
}

#pragma mark -Timer

- (void)sendImage
{
	[manager.connectedDevice sendImage:[CameraImageHelper image] forceReady:YES];
}

- (void)stop
{
	[runTimer invalidate];
	[manager.connectedDevice sendStop];
}

@end
