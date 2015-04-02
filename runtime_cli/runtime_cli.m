#import <Foundation/Foundation.h>
#import "ClassDisplay.h"

int main (int argc, const char * argv[]) {

    @autoreleasepool {
        ClassDisplay *cd = [ClassDisplay classDisplayWithClass:[NSString class]];
        
        NSString *header = [cd header];
        
        NSLog(@"-- %@", header);
    }

    return 0;
}
