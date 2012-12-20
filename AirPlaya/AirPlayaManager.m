//  Based on AKAirplayManager by Andy Roth.

#import "AirPlayaManager.h"

@interface AirPlayaManager () <NSNetServiceBrowserDelegate, NSNetServiceDelegate> {
@private
    NSMutableArray *devices;
    NSMutableSet *unresolvedServices;
}

@property (nonatomic, retain) NSNetServiceBrowser *serviceBrowser;
@property (nonatomic, retain) AirPlayaDevice *connectingDevice; // non-nil only during connection

@end

@implementation AirPlayaManager

#pragma mark - lifecycle

- (id)init
{
	if ((self = [super init])) {
		self.autoConnect = NO;
		devices = [[NSMutableArray alloc] init];
        unresolvedServices = [[NSMutableSet alloc] init];
	}

	return self;
}

- (void)dealloc
{
    [_serviceBrowser stop];
    [_serviceBrowser release];
	[_connectedDevice release];
    [devices release];
	[unresolvedServices release];

	[super dealloc];
}

#pragma mark - Public Methods

- (void)findDevices
{
	NSLog(@"Finding Airport devices.");

	_serviceBrowser = [[NSNetServiceBrowser alloc] init];
	[_serviceBrowser setDelegate:self];
	[_serviceBrowser searchForServicesOfType:@"_airplay._tcp" inDomain:@""];
}

- (void)connectToDevice:(AirPlayaDevice *)device
{
	NSLog(@"Connecting to device : %@:%d", device.hostname, device.port);

    // TODO: disconnect from connected device

    if (_connectingDevice) {
        NSLog(@"Attempted to connect to device %@ while another connection in progress", device);
        return;
    }

    // TODO all kinds of possible error states in here

    self.connectingDevice = device;
    device.socket = [[[AsyncSocket alloc] initWithDelegate:self] autorelease];
    [device.socket connectToHost:device.hostname onPort:device.port error:NULL];
}

- (NSArray *)devices
{
    return [NSArray arrayWithArray:devices];
}

#pragma mark - NetServiceBrowserDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser
           didFindService:(NSNetService *)netService
               moreComing:(BOOL)moreComing
{
	NSLog(@"Found service");
	[netService setDelegate:self];
	[netService resolveWithTimeout:20.0];
	[unresolvedServices addObject:netService];

	if (!moreComing) {
		[_serviceBrowser stop];
        self.serviceBrowser = nil;
	}
}

#pragma mark - NetServiceDelegate

- (void)netServiceDidResolveAddress:(NSNetService *)service
{
	NSLog(@"Resolved service: %@:%d", service.hostName, service.port);

	AirPlayaDevice *device = [[[AirPlayaDevice alloc] initWithResolvedService:service] autorelease];
    [unresolvedServices removeObject:service];
    [devices addObject:device];

	if (_delegate && [_delegate respondsToSelector:@selector(manager:didFindDevice:)]) {
		[_delegate manager:self didFindDevice:device];
	}

	if (_autoConnect && !_connectedDevice) {
		[self connectToDevice:device];
	}
}

#pragma mark - AsyncSocketDelegate

- (void)onSocket:(AsyncSocket *)socket didConnectToHost:(NSString *)host port:(UInt16)port
{
    if (![[_connectingDevice socket] isEqual:socket]) {
        NSLog(@"Ignoring %s from socket %@; socket does not match _connecting device %@", __PRETTY_FUNCTION__, socket,
              _connectingDevice);

        return;
    }

    _connectingDevice.connected = YES;
    self.connectedDevice = _connectingDevice;
    self.connectingDevice = nil;

	if (_delegate && [_delegate respondsToSelector:@selector(manager:didConnectToDevice:)]) {
		[self.connectedDevice sendReverse];
		[_delegate manager:self didConnectToDevice:self.connectedDevice];
	}
}

@end
