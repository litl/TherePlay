// Based on AKDevice by Andy Roth.

#import "TherePlayDevice.h"
#import "AsyncSocket.h"

// +[NSNetService dictionaryFromTXTRecordData:] leaves the dict values as UTF8 NSData's,
// rather than NSString's (It's a TXT record, right?). This goes that extra step.
NSDictionary *DictionaryOfStringsFromTXTRecordData(NSData *TXTRecordData)
{
    NSMutableDictionary *newDict = [[[NSNetService dictionaryFromTXTRecordData:TXTRecordData] mutableCopy] autorelease];

    [newDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *val = [NSString stringWithUTF8String:[(NSData *)obj bytes]];
        newDict[key] = val;
    }];

    return [NSDictionary dictionaryWithDictionary:newDict];
}

// This was obtained by somebody else's rev-eng hoodoo, as per http://nto.github.io/AirPlay.html
typedef struct {
    unsigned int video:1;
    unsigned int photo:1;
    unsigned int videoFairPlay:1;
    unsigned int videoVolumeControl:1;   // 4
    unsigned int videoHTTPLiveStreams:1;
    unsigned int slideshow:1;
    unsigned int unknown1:1;
    unsigned int mirroring:1;            // 8
    unsigned int screenRotate:1;
    unsigned int audio:1;
    unsigned int unknown2:1;
    unsigned int audioRedundant:1;       // 12
    unsigned int FPSAPv2pt5_AES_GCM:1;
    unsigned int photoCaching:1;
} AirPlayFeatures;

AirPlayFeatures AirPlayFeaturesFromNSString(NSString *hexString)
{
    // allows you to set a bit field by assigning the number
    union {
        unsigned int number;
        AirPlayFeatures features;
    } converter;

    NSScanner* scanner = [NSScanner scannerWithString:hexString];
    [scanner scanHexInt:&(converter.number)];

    return converter.features;
}

#pragma mark - TherePlayDevice

@interface TherePlayDevice ()  <AsyncSocketDelegate> {
@private
    BOOL okToSend;
    NSString *queuedMessage;
    NSDictionary *TXTRecordDict; // keys & values are all NSString's; cf. DictionaryOfStringsFromTXTRecordData()
    AirPlayFeatures features;
}

@end

@implementation TherePlayDevice

#pragma mark - lifecycle & NSObject

- (id)init
{
	if ((self = [super init])) {
		_connected = NO;
		_imageQuality = 0.8;
	}

	return self;
}

- (id)initWithResolvedService:(NSNetService *)service
{
    if ((self = [self init])) {
        _service = [service retain];
        _hostname = [service.hostName retain];
        _port = service.port;

        [self loadTXTRecord];
    }

    return self;
}

- (void)dealloc
{
	[self sendStop];
    _socket.delegate = nil;
	[_socket release];
    [_service release];
	[_hostname release];
    [TXTRecordDict release];

	[super dealloc];
}

// -isEqual:/hash map directly to the underlying NSNetService, for NSSet/NSDictionary good citizenship, etc.

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }

    return [_service isEqual:((TherePlayDevice *)object).service];
}

- (NSUInteger)hash
{
    return _service.hash;
}

- (NSString *)description
{
    NSMutableString *s = [[[[super description] stringByReplacingOccurrencesOfString:@">" withString:@""] mutableCopy]
                          autorelease];
    [s appendFormat:@", %@,\n%@>", _service, TXTRecordDict
     ];
    return s;
}

#pragma mark - Public Methods

- (NSString *)displayName
{
	NSString *name = [_hostname stringByReplacingOccurrencesOfString:@"-" withString:@" "];
    return [name stringByReplacingOccurrencesOfString:@".local." withString:@""];
}

- (void)sendRawData:(NSData *)data
{
	self.socket.delegate = self;
	[self.socket writeData:data withTimeout:20 tag:1];
	[self.socket readDataWithTimeout:20.0 tag:1];
}

- (void)sendRawMessage:(NSString *)message
{
	if (!okToSend) {
		queuedMessage = [message retain];
	}

	[self sendRawData:[message dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)sendContentURL:(NSString *)url
{
	NSString *body = [[NSString alloc] initWithFormat:@"Content-Location: %@\r\n"
														"Start-Position: 0\r\n\r\n", url];
	int length = [body length];

	NSString *message = [[NSString alloc] initWithFormat:@"POST /play HTTP/1.1\r\n"
															 "Content-Length: %d\r\n"
															 "User-Agent: MediaControl/1.0\r\n\r\n%@", length, body];

	[self sendRawMessage:message];

	[body release];
	[message release];
}

- (void)sendImage:(UIImage *)image forceReady:(BOOL)ready
{
	if (ready) okToSend = YES;
	[self sendImage:image];
}

- (void)sendImage:(UIImage *)image
{
	if (okToSend) {
		okToSend = NO;

		NSData *imageData = UIImageJPEGRepresentation(image, _imageQuality);
		int length = [imageData length];
		NSString *message = [[NSString alloc] initWithFormat:@"PUT /photo HTTP/1.1\r\n"
							 "Content-Length: %d\r\n"
							 "User-Agent: MediaControl/1.0\r\n\r\n", length];
		NSMutableData *messageData = [[NSMutableData alloc] initWithData:[message dataUsingEncoding:NSUTF8StringEncoding]];
		[messageData appendData:imageData];

		// Send the raw data
		[self sendRawData:messageData];

		[messageData release];
		[message release];
	}
}

- (void)sendStop
{
	NSString *message = @"POST /stop HTTP/1.1\r\n"
	"User-Agent: MediaControl/1.0\r\n\r\n";
	[self sendRawMessage:message];
}

- (void)sendReverse
{
	NSString *message = @"POST /reverse HTTP/1.1\r\n"
	"Upgrade: PTTH/1.0\r\n"
	"Connection: Upgrade\r\n"
	"X-Apple-Purpose: event\r\n"
	"Content-Length: 0\r\n"
	"User-Agent: MediaControl/1.0\r\n\r\n";

	[self sendRawData:[message dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)loadTXTRecord
{
    TXTRecordDict = [DictionaryOfStringsFromTXTRecordData([_service TXTRecordData]) retain];
    features = AirPlayFeaturesFromNSString(TXTRecordDict[@"features"]);
    BOOL requiresPassword = [TXTRecordDict[@"pw"] isEqualToString:@"1"];
    _requiresOnscreenCode = [TXTRecordDict[@"pin"] isEqualToString:@"1"];
    _requiresAuthentication = _requiresOnscreenCode || requiresPassword;
}

#pragma mark - AsyncSocketDelegate

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	if ([_delegate respondsToSelector:@selector(device:didSendBackMessage:)]) {
		NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		[_delegate device:self didSendBackMessage:[message autorelease]];
	}

	okToSend = YES;

	if (queuedMessage) {
		[self sendRawData:[queuedMessage dataUsingEncoding:NSUTF8StringEncoding]];
		[queuedMessage release];
		queuedMessage = nil;
	}
}

@end