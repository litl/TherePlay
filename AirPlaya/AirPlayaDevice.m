// Based on AKDevice by Andy Roth.

#import "AirPlayaDevice.h"

@interface AirPlayaDevice () {
@private
    BOOL okToSend;
    NSString *queuedMessage;
}
@end

@implementation AirPlayaDevice

#pragma mark - lifecycle

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
    }

    return self;
}

- (void)dealloc
{
	[self sendStop];
	[_socket release];
    [_service release];
	[_hostname release];

	[super dealloc];
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