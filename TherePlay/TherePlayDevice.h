// Based on AKDevice by Andy Roth.

#import <UIKit/UIKit.h>

#pragma mark - TherePlayDevice

/*
 TherePlayDevice is a wrapper to NSNetService which manages a connection to
 the service and various other bits of state. -isEqual:/hash maps directly to
 the underlying NSNetService, for NSSet/NSDictionary good citizenship, etc.
 */

@protocol TherePlayDeviceDelegate;
@class AsyncSocket;

@interface TherePlayDevice : NSObject

@property (nonatomic, readonly, retain) NSNetService *service;
@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, retain) NSString *hostname;
@property (nonatomic) UInt16 port;

// Apple TV allows one of two mutually exclusive styles of authentication, password or onscreen code.
// Per my spelunking and reading of TUAP, these both dump into the same digest auth scheme.
// These two BOOLs should tell you what you need to know.
//
// TODO: right now, TherePlay does not support connections to an auth-protected AirPlay service.
// TODO: if you turn on auth on, e.g. a connected AppleTV, you should be disconnected.
//
@property (nonatomic, readonly) BOOL requiresAuthentication;
@property (nonatomic, readonly) BOOL requiresOnscreenCode;

@property (nonatomic, assign) id <TherePlayDeviceDelegate> delegate;
@property (nonatomic) BOOL connected; // Set to YES when the device is connected.
@property (nonatomic, retain) AsyncSocket *socket; // The socket used to transmit data. Only use for completely custom actions.
@property (nonatomic) CGFloat imageQuality; // JPEG image quality for sending images. Defaults to 0.8;

- (instancetype)initWithResolvedService:(NSNetService *)service;
- (void)loadTXTRecord;

- (void)sendRawData:(NSData *)data;
- (void)sendRawMessage:(NSString *)message; // Sends a raw HTTP string over Airplay.
- (void)sendContentURL:(NSString *)url;
- (void)sendImage:(UIImage *)image;
- (void)sendImage:(UIImage *)image forceReady:(BOOL)ready;
- (void)sendStop;
- (void)sendReverse;

@end

#pragma mark - TherePlayDeviceDelegate

@protocol TherePlayDeviceDelegate <NSObject>

@optional

- (void)device:(TherePlayDevice *)device didSendBackMessage:(NSString *)message;

@end



