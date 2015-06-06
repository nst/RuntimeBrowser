//
//  AAA.m
//  OCRuntime
//
//  Created by Nicolas Seriot on 07/05/15.
//  Copyright (c) 2015 Nicolas Seriot. All rights reserved.
//

#import "AAA.h"

@implementation AAA

+ (NSString *)myClassMethod {
    return @"x";
}

- (NSString *)a:(NSString *)argA b:(NSString *)argB {
    return [NSString stringWithFormat:@"%@-%@", argA, argB];
}

- (MyCStruct)sayHello {
    
    MyCStruct s;
    
    return s;
}

@end
