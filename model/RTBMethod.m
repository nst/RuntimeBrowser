//
//  RTBMethod.m
//  OCRuntime
//
//  Created by Nicolas Seriot on 06/05/15.
//  Copyright (c) 2015 Nicolas Seriot. All rights reserved.
//

#import "RTBMethod.h"
#import "RTBTypeDecoder.h"
#import "RTBRuntimeHeader.h"

@interface RTBMethod ()
@property (nonatomic) Method method;
@property (nonatomic) BOOL isClassMethod;
@end

@implementation RTBMethod

+ (instancetype)methodObjectWithMethod:(Method)method isClassMethod:(BOOL)isClassMethod {
    RTBMethod *m = [[RTBMethod alloc] init];
    m.method = method;
    m.isClassMethod = isClassMethod;
    return m;
}

- (NSString *)returnType {
    return nil;
}

- (NSArray *)argumentsTypes {
    
    unsigned int numberOfArguments = method_getNumberOfArguments(_method);
    
    NSMutableArray *ma = [NSMutableArray array];
    
    for(unsigned int i = 0; i < numberOfArguments; i++) {
        char *argType = method_copyArgumentType(_method, i);
        NSAssert(argType != NULL, @"");
        NSString *encodedType = [NSString stringWithCString:argType encoding:NSASCIIStringEncoding];
        free(argType);
        
        NSString *decodedType = [RTBTypeDecoder decodeType:encodedType flat:YES];
        [ma addObject:decodedType];
    }
    return ma;
}

- (NSString *)headerDescription {
    char* returnTypeCString = method_copyReturnType(_method);
    NSString *returnTypeEncoded = [NSString stringWithCString:returnTypeCString encoding:NSASCIIStringEncoding];
    free(returnTypeCString);
    NSString *returnType = [RTBTypeDecoder decodeType:returnTypeEncoded flat:YES];
    NSString *methodName = NSStringFromSelector(method_getName(_method));
    NSArray *argumentTypes = [self argumentsTypes];
    
    return [RTBRuntimeHeader descriptionForMethodName:methodName
                                           returnType:returnType
                                        argumentTypes:argumentTypes
                                        isClassMethod:_isClassMethod];
}

- (NSString *)selectorString {
    return NSStringFromSelector(method_getName(_method));
}

- (NSComparisonResult)compare:(RTBMethod *)otherMethod {
    return [[self selectorString] compare:[otherMethod selectorString]];
}

@end
