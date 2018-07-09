//
//  RTBMethod.m
//  OCRuntime
//
//  Created by Nicolas Seriot on 06/05/15.
//  Copyright (c) 2015 Nicolas Seriot. All rights reserved.
//

#import "RTBMethod.h"
#import "RTBRuntimeHeader.h"
#include "dlfcn.h"

#if USE_NEW_DECODER
#import "RTBTypeDecoder2.h"
@compatibility_alias RTBTypeDecoder RTBTypeDecoder2;
#else
#import "RTBTypeDecoder.h"
#endif

@interface RTBMethod ()
@property (nonatomic) Method method;
@property (nonatomic) BOOL isClassMethod;

@property (nonatomic, strong) NSNumber *cachedHasArguments;
@property (nonatomic, strong) NSArray *cachedArgumentsTypesDecoded;
@property (nonatomic, strong) NSDictionary *cachedDyldInfoDictionary;
@end

@implementation RTBMethod

+ (instancetype)methodObjectWithMethod:(Method)method isClassMethod:(BOOL)isClassMethod {
    RTBMethod *m = [[RTBMethod alloc] init];
    m.method = method;
    m.isClassMethod = isClassMethod;
    return m;
}

- (NSString *)description {
    NSString *superDescription = [super description];
    
    return [NSString stringWithFormat:@"%@ %@", superDescription, [self selectorString]];
}

- (Method)method {
    return _method;
}

- (NSDictionary *)dyldInfo {
    
    IMP imp = method_getImplementation(_method);

    Dl_info info;
    int rc = dladdr(imp, &info);
    
    if (!rc)  {
        return nil;
    }
    
//    printf("-- function %s\n", info.dli_sname);
//    printf("-- program %s\n", info.dli_fname);
//    printf("-- fbase %p\n", info.dli_fbase);
//    printf("-- saddr %p\n", info.dli_saddr);
    
    NSString *filePath = [NSString stringWithFormat:@"%s", info.dli_fname];
    
#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
    NSString *symbolName = @""; // info.dli_sname is unreliable on the device, most of time "<redacted>"
#else
    NSString *symbolName = [NSString stringWithFormat:@"%s", info.dli_sname];
#endif
    
    NSString *categoryName = nil;
    
    NSUInteger startIndex = [symbolName rangeOfString:@"("].location;
    NSUInteger stopIndex = [symbolName rangeOfString:@")"].location;
    if(startIndex != NSNotFound && stopIndex != NSNotFound && startIndex < stopIndex) {
        categoryName = [symbolName substringWithRange:NSMakeRange(startIndex+1, (stopIndex - startIndex)-1)];
    }
    
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:2];
    if(filePath) md[@"filePath"] = filePath;
    if(symbolName) md[@"symbolName"] = symbolName;
    if(categoryName) md[@"categoryName"] = categoryName;
    return md;
}

- (NSString *)categoryName {
    if(_cachedDyldInfoDictionary == nil) {
        self.cachedDyldInfoDictionary = [self dyldInfo];
    }
    return _cachedDyldInfoDictionary[@"categoryName"];
}

- (NSString *)symbolName {
    if(_cachedDyldInfoDictionary == nil) {
        self.cachedDyldInfoDictionary = [self dyldInfo];
    }
    return _cachedDyldInfoDictionary[@"symbolName"];
}

- (NSString *)filePath {
    if(_cachedDyldInfoDictionary == nil) {
        self.cachedDyldInfoDictionary = [self dyldInfo];
    }
    return _cachedDyldInfoDictionary[@"filePath"];
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
        /*
        NSString *methodName = [NSString stringWithCString:method_getName(_method) encoding:NSUTF8StringEncoding];
        NSLog(@"-- methodName: %@", methodName);
        
        if([self.filePath isEqualToString:@"/System/Library/PrivateFrameworks/CoreKnowledge.framework/CoreKnowledge"]) {
            NSArray *blacklistCoreKnowledgeSelectors = @[@"identifier", @"sql", @"writeBatch"];
            if([blacklistCoreKnowledgeSelectors containsObject:methodName]) {
                return _cachedArgumentsTypesDecoded;
            }
        }
        */
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
    if(returnTypeCString == NULL) return @"";
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
    
    if(self.isClassMethod && otherMethod.isClassMethod == NO) return NSOrderedAscending;
    if(self.isClassMethod == NO && otherMethod.isClassMethod) return NSOrderedDescending;
    
    return [[self selectorString] compare:[otherMethod selectorString]];
}

@end
