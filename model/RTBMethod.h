//
//  RTBMethod.h
//  OCRuntime
//
//  Created by Nicolas Seriot on 06/05/15.
//  Copyright (c) 2015 Nicolas Seriot. All rights reserved.
//

// TODO: create RTBMethod to provide selector, description, return type and argument types

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface RTBMethod : NSObject

+ (instancetype)methodObjectWithMethod:(Method)method isClassMethod:(BOOL)isClassMethod;

- (NSString *)headerDescriptionWithNewlineAfterArgs:(BOOL)newlineAfterArgs;

- (NSString *)returnTypeEncoded;
- (NSString *)returnTypeDecoded;
- (NSArray *)argumentsTypesDecoded;
- (NSString *)selectorString;
- (SEL)selector;
- (BOOL)hasArguments;

- (NSString *)filePath;
- (NSString *)symbolName;
- (NSString *)categoryName;

- (Method)method;

@end
