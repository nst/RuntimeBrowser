#import <Foundation/Foundation.h>
#import "RTBRuntimeHeader.h"

int main (int argc, const char * argv[]) {

    @autoreleasepool {
        NSString *header = [RTBRuntimeHeader headerForClass:[NSString class] displayPropertiesDefaultValues:YES];
        
        NSLog(@"-- %@", header);
    }

    return 0;
}
