#import <Foundation/Foundation.h>
#import "RTBRuntimeHeader.h"
#import "RTBTypeDecoder2.h"

int main (int argc, const char * argv[]) {

    @autoreleasepool {
//        NSString *header = [RTBRuntimeHeader headerForClass:[NSString class] displayPropertiesDefaultValues:YES];
//        NSLog(@"-- %@", header);
        
        NSArray *a = [RTBTypeDecoder2 decodeTypes:@"^^d^I" flat:YES];
        NSLog(@"-- %@", a);
    }

    return 0;
}
