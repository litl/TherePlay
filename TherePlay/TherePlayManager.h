//  Based on AKAirplayManager by Andy Roth.

// For purposes of using AirPlay services, wraps NSNetServiceBrowser with a hopefully easier-to-use interface.

#import "TherePlayDevice.h"

#pragma mark - TherePlayManager

@protocol TherePlayManagerDelegate;

@interface TherePlayManager : NSObject

@property (nonatomic, readonly, retain) NSArray *devices; // array of TherePlayDevice
@property (nonatomic, retain) TherePlayDevice *connectedDevice;
@property (nonatomic, assign) id <TherePlayManagerDelegate> delegate;
@property (nonatomic, readonly) BOOL isActive;
@property (nonatomic) BOOL autoConnect; // Connects to the first found device automatically. Defaults to NO.

- (void)activate; // starts searching for Airplay devices on the same wifi network
- (void)deactivate;
- (void)connectToDevice:(TherePlayDevice *)device; // Connects to a found device.
- (void)disconnectFromDevice:(TherePlayDevice *)device;
- (void)attemptConnectionToDeviceWithName:(NSString *)name running:(void(^)(BOOL success))blockToRun;
- (void)runAfterCompletedUpdate:(void (^)(TherePlayManager *manager))block;

@end

#pragma mark - TherePlayManagerDelegate

@protocol TherePlayManagerDelegate <NSObject>

@optional

- (void)therePlayManager:(TherePlayManager *)manager didFindDevice:(TherePlayDevice *)device;
- (void)therePlayManager:(TherePlayManager *)manager didConnectToDevice:(TherePlayDevice *)device;
- (void)therePlayManager:(TherePlayManager *)manager didDisconnectFromDevice:(TherePlayDevice *)device;
- (void)therePlayManagerWillUpdateDevices:(TherePlayManager *)manager;
- (void)therePlayManagerDidUpdateDevices:(TherePlayManager *)manager;

@end