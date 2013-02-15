//  Based on code from AirplayKit by Andy Roth.

#import "AirPresentViewController.h"
#import "APManager.h"

@implementation AirPresentViewController

- (IBAction)handleStartStopButtonTouchUpInside
{
    [[APManager sharedManager] startStop];
}

@end
