// Based on AKDevice by Andy Roth.

#import <UIKit/UIKit.h>
#import "AsyncSocket.h"

#pragma mark - AirPlayaDevice

@protocol AirPlayaDeviceDelegate;

@interface AirPlayaDevice : NSObject <AsyncSocketDelegate>

@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, retain) NSString *hostname;
@property (nonatomic) UInt16 port;
@property (nonatomic, assign) id <AirPlayaDeviceDelegate> delegate;
@property (nonatomic) BOOL connected; // Set to YES when the device is connected.
@property (nonatomic, retain) AsyncSocket *socket; // The socket used to transmit data. Only use for completely custom actions.
@property (nonatomic) CGFloat imageQuality; // JPEG image quality for sending images. Defaults to 0.8;

- (void)sendRawData:(NSData *)data;
- (void)sendRawMessage:(NSString *)message; // Sends a raw HTTP string over Airplay.
- (void)sendContentURL:(NSString *)url;
- (void)sendImage:(UIImage *)image;
- (void)sendImage:(UIImage *)image forceReady:(BOOL)ready;
- (void)sendStop;
- (void)sendReverse;

@end

#pragma mark - AirPlayaDeviceDelegate

@protocol AirPlayaDeviceDelegate <NSObject>

@optional

- (void)device:(AirPlayaDevice *)device didSendBackMessage:(NSString *)message;

@end



