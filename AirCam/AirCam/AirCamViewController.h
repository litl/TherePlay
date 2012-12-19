//
//  AirCamViewController.h
//  AirCam
//
//  Created by Andy Roth on 5/26/11.
//  Copyright 2011 Roozy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AirPlayaManager.h"
#import "AirPlayaDevice.h"

@interface AirCamViewController : UIViewController <AirPlayaManagerDelegate, AirPlayaDeviceDelegate>
{
    AirPlayaManager *manager;
	NSTimer *runTimer;
}

- (void)stop;

@end
