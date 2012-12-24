//
//  AirCamViewController.h
//  AirCam
//
//  Created by Andy Roth on 5/26/11.
//  Copyright 2011 Roozy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TherePlayManager.h"
#import "TherePlayDevice.h"

@interface AirCamViewController : UIViewController <TherePlayManagerDelegate, TherePlayDeviceDelegate>
{
    TherePlayManager *manager;
	NSTimer *runTimer;
}

- (void)stop;

@end
