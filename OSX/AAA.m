//
//  AAA.m
//  runtime_cli
//
//  Created by Nicolas Seriot on 03/04/15.
//
//

#import "AAA.h"

@implementation AAA

+ (NSRange)myClassMethod {
    return NSMakeRange(0, 0);
}

- (void)a {
    NSLog(@"--");
}

- (void)b:(NSString *)s {
    NSLog(@"--");
}

- (void)c:(id)s :(id)s2 {
    NSLog(@"--");
}

@end
