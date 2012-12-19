//  Based on AKAirplayManager by Andy Roth.

#import "AirPlayaManager.h"

@interface AirPlayaManager () <NSNetServiceBrowserDelegate, NSNetServiceDelegate> {
@private
	AirPlayaDevice *tempDevice;
	NSMutableArray *foundServices;
}

@property (nonatomic, retain) NSNetServiceBrowser *serviceBrowser;

@end

@implementation AirPlayaManager

#pragma mark - lifecycle

- (id)init
{
	if ((self = [super init])) {
		self.autoConnect = NO;
		foundServices = [[NSMutableArray alloc] init];
	}

	return self;
}

- (void)dealloc
{
    [_serviceBrowser stop];
    [_serviceBrowser release];
	[_connectedDevice release];
	[foundServices removeAllObjects];
	[foundServices release];

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

	if (!tempDevice) {
		tempDevice = [device retain];

		AsyncSocket *socket = [[AsyncSocket alloc] initWithDelegate:self];
		[socket connectToHost:device.hostname onPort:device.port error:NULL];
	}
}

#pragma mark - NetServiceBrowserDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser
           didFindService:(NSNetService *)netService
               moreComing:(BOOL)moreComing
{
	NSLog(@"Found service");
	[netService setDelegate:self];
	[netService resolveWithTimeout:20.0];
	[foundServices addObject:netService];

	if (!moreComing) {
		[_serviceBrowser stop];
        self.serviceBrowser = nil;
	}
}

#pragma mark - NetServiceDelegate

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
	NSLog(@"Resolved service: %@:%d", sender.hostName, sender.port);

	AirPlayaDevice *device = [[AirPlayaDevice alloc] init];
	device.hostname = sender.hostName;
	device.port = sender.port;

	if (_delegate && [_delegate respondsToSelector:@selector(manager:didFindDevice:)]) {
		[_delegate manager:self didFindDevice:[device autorelease]];
	}

	if (_autoConnect && !_connectedDevice) {
		[self connectToDevice:device];
	}
}

#pragma mark - AsyncSocketDelegate

- (void)onSocket:(AsyncSocket *)socket didConnectToHost:(NSString *)host port:(UInt16)port
{
	NSLog(@"Connected to device.");

	AirPlayaDevice *device = tempDevice;
	device.socket = socket;
	device.connected = YES;

	self.connectedDevice = device;
	[device release];
	tempDevice = nil;

	if (_delegate && [_delegate respondsToSelector:@selector(manager:didConnectToDevice:)]) {
		[self.connectedDevice sendReverse];
		[_delegate manager:self didConnectToDevice:self.connectedDevice];
	}
}

@end
