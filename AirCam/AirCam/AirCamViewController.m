//
//  AirCamViewController.m
//  AirCam
//
//  Created by Andy Roth on 5/26/11.
//  Copyright 2011 Roozy. All rights reserved.
//

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
	[manager findDevices];
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

- (void)manager:(TherePlayManager *)aManager didConnectToDevice:(TherePlayDevice *)device
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
