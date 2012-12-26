//  Based on code from AirplayKit by Andy Roth.

#import "AirPresentAppDelegate.h"
#import "AirPresentViewController.h"
#import "APManager.h"

@implementation AirPresentAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[APManager sharedManager] start];

    // Add the view controller's view to the window and display.
    [self.window addSubview:_viewController.view];
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)dealloc {
    [_viewController release];
    [_window release];

    [super dealloc];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [[APManager sharedManager] stop];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[APManager sharedManager] start];
}


- (void)applicationWillTerminate:(UIApplication *)application {
    [[APManager sharedManager] stop];
}


@end
