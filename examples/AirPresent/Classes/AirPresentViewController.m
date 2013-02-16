//  Based on code from AirplayKit by Andy Roth.

#import "AirPresentViewController.h"
#import "APManager.h"

@implementation AirPresentViewController

- (IBAction)handleStartStopButtonTouchUpInside
{
    [[APManager sharedManager] startStop];
}

- (void)handleUseNamedDeviceButtonTouchUpInside
{
    [[APManager sharedManager] reconnectUsingDeviceNameWithBlock:^(BOOL success) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:success ? @"success" : @"failure"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }];
}

@end
