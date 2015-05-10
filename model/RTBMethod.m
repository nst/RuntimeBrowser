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

@property (nonatomic, strong) NSNumber *cachedHasArguments;
@property (nonatomic, strong) NSArray *cachedArgumentsTypesDecoded;
@end

@implementation RTBMethod

+ (instancetype)methodObjectWithMethod:(Method)method isClassMethod:(BOOL)isClassMethod {
    RTBMethod *m = [[RTBMethod alloc] init];
    m.method = method;
    m.isClassMethod = isClassMethod;
    return m;
}

- (BOOL)hasArguments {
    if(_cachedHasArguments == nil) {
        self.cachedHasArguments = [NSNumber numberWithBool:[[self argumentsTypesDecoded] count] > 2]; // id, SEL, ...
    }
    return [_cachedHasArguments boolValue];
}

- (NSString *)returnTypeEncoded {
    static int BUFFER_SIZE = 255;
    
    char* buffer = malloc(BUFFER_SIZE * sizeof(char));
    method_getReturnType(_method, buffer, BUFFER_SIZE);
    NSString *s = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
    free(buffer);
    return s;
}

- (NSString *)returnTypeDecoded {
    NSString *s = [self returnTypeEncoded];
    return [RTBTypeDecoder decodeType:s flat:YES];
}

- (NSArray *)argumentsTypesDecoded {
    
    if(_cachedArgumentsTypesDecoded == nil) {
    
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
        self.cachedArgumentsTypesDecoded = ma;
    }
    
    return _cachedArgumentsTypesDecoded;
}

- (NSString *)headerDescriptionWithNewlineAfterArgs:(BOOL)newlineAfterArgs {
    char* returnTypeCString = method_copyReturnType(_method);
    NSString *returnTypeEncoded = [NSString stringWithCString:returnTypeCString encoding:NSASCIIStringEncoding];
    free(returnTypeCString);
    NSString *returnType = [RTBTypeDecoder decodeType:returnTypeEncoded flat:YES];
    NSString *methodName = NSStringFromSelector(method_getName(_method));
    NSArray *argumentTypes = [self argumentsTypesDecoded];
    
    return [RTBRuntimeHeader descriptionForMethodName:methodName
                                           returnType:returnType
                                        argumentTypes:argumentTypes
                                     newlineAfterArgs:newlineAfterArgs
                                        isClassMethod:_isClassMethod];
}

- (NSString *)selectorString {
    return NSStringFromSelector(method_getName(_method));
}

- (SEL)selector {
    return method_getName(_method);
}

- (NSComparisonResult)compare:(RTBMethod *)otherMethod {
    return [[self selectorString] compare:[otherMethod selectorString]];
}

@end
