#import <Foundation/Foundation.h>
#import "ClassDisplayDeprecated.h"

int main (int argc, const char * argv[]) {

    @autoreleasepool {
        ClassDisplayDeprecated *cd = [ClassDisplayDeprecated classDisplayWithClass:[NSString class]];
        
        NSString *header = [cd header];
        
        NSLog(@"-- %@", header);
    }

    return 0;
}
