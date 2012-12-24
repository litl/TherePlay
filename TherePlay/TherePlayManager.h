//  Based on AKAirplayManager by Andy Roth.

#import "TherePlayDevice.h"
#import "AsyncSocket.h"

#pragma mark - TherePlayManager

@protocol TherePlayManagerDelegate;

@interface TherePlayManager : NSObject

@property (nonatomic, assign) id <TherePlayManagerDelegate> delegate;
@property (nonatomic) BOOL autoConnect; // Connects to the first found device automatically. Defaults to NO.
@property (nonatomic, retain) TherePlayDevice *connectedDevice;
@property (nonatomic, readonly, retain) NSArray *devices; // array of TherePlayDevice

- (void)findDevices; // Searches for Airplay devices on the same wifi network.
- (void)connectToDevice:(TherePlayDevice *)device; // Connects to a found device.

@end

#pragma mark - TherePlayManagerDelegate

@protocol TherePlayManagerDelegate <NSObject>

@optional

// Use -connectToDevice: to connect to a specific device.
// Once connected, use TherePlayManager methods to communicate over AirPlay.

- (void)manager:(TherePlayManager *)manager didFindDevice:(TherePlayDevice *)device;
- (void)manager:(TherePlayManager *)manager didConnectToDevice:(TherePlayDevice *)device;

@end