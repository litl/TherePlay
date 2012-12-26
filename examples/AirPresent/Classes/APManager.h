//  Based on code from AirplayKit by Andy Roth.

@interface APManager : NSObject

+ (APManager *) sharedManager;

- (void)start;
- (void)stop;

@end

