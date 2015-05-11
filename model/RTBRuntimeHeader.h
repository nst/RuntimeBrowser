//
//  RTBTypeParser.h
//  runtime_cli
//
//  Created by Nicolas Seriot on 02/04/15.
//
//

#import <Foundation/Foundation.h>
#import "RTBProtocol.h"

#if (! TARGET_OS_IPHONE)
#import <objc/objc-runtime.h>
#else
#import <objc/runtime.h>
#import <objc/message.h>
#endif

@interface RTBRuntimeHeader : NSObject

+ (NSArray *)sortedMethodsForClass:(Class)aClass isClassMethod:(BOOL)isClassMethod;

+ (NSString *)decodedTypeForEncodedString:(NSString *)s;

+ (NSArray *)sortedPropertiesDictionariesForClass:(Class)aClass
                   displayPropertiesDefaultValues:(BOOL)displayPropertiesDefaultValues;

+ (NSString *)descriptionForPropertyWithName:(NSString *)name
                                  attributes:(NSString *)attributes
              displayPropertiesDefaultValues:(BOOL)displayPropertiesDefaultValues;

+ (NSString *)headerForClass:(Class)aClass displayPropertiesDefaultValues:(BOOL)displayPropertiesDefaultValues;

+ (NSString *)headerForProtocol:(RTBProtocol *)protocol;

+ (NSString *)descriptionForMethodName:(NSString *)methodName
                            returnType:(NSString *)returnType
                         argumentTypes:(NSArray *)argumentsTypes
                      newlineAfterArgs:(BOOL)newlineAfterArgs
                         isClassMethod:(BOOL)isClassMethod;

+ (NSString *)descriptionForProtocol:(Protocol *)protocol
                            selector:(SEL)selector
                    isRequiredMethod:(BOOL)isRequiredMethod
                    isInstanceMethod:(BOOL)isInstanceMethod;

@end
