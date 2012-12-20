//  Based on AKAirplayManager by Andy Roth.

#import "AirPlayaDevice.h"
#import "AsyncSocket.h"

#pragma mark - AirPlayaManager

@protocol AirPlayaManagerDelegate;

@interface AirPlayaManager : NSObject

@property (nonatomic, assign) id <AirPlayaManagerDelegate> delegate;
@property (nonatomic) BOOL autoConnect; // Connects to the first found device automatically. Defaults to NO.
@property (nonatomic, retain) AirPlayaDevice *connectedDevice;
@property (nonatomic, readonly, retain) NSArray *devices; // array of AirPlayaDevice

- (void)findDevices; // Searches for Airplay devices on the same wifi network.
- (void)connectToDevice:(AirPlayaDevice *)device; // Connects to a found device.

@end

#pragma mark - AirPlayaManagerDelegate

@protocol AirPlayaManagerDelegate <NSObject>

@optional

// Use -connectToDevice: to connect to a specific device.
// Once connected, use AirPlayaManager methods to communicate over AirPlay.

- (void)manager:(AirPlayaManager *)manager didFindDevice:(AirPlayaDevice *)device;
- (void)manager:(AirPlayaManager *)manager didConnectToDevice:(AirPlayaDevice *)device;

@end