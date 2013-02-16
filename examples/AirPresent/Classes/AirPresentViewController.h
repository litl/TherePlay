//  Based on code from AirplayKit by Andy Roth.

#import <UIKit/UIKit.h>

@interface AirPresentViewController : UIViewController

@property (nonatomic, retain) IBOutlet UIButton *startStopButton;

- (IBAction)handleStartStopButtonTouchUpInside;
- (IBAction)handleUseNamedDeviceButtonTouchUpInside;

@end

