#import <Foundation/Foundation.h>
#import "ClassDisplay.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	ClassDisplay *cd = [ClassDisplay classDisplayWithClass:[NSString class]];
	
	NSString *header = [cd header];
	
	NSLog(@"-- %@", header);

    [pool drain];
    return 0;
}
