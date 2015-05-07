//
//  RTBTypeParser.h
//  runtime_cli
//
//  Created by Nicolas Seriot on 02/04/15.
//
//

#import <Foundation/Foundation.h>

#if (! TARGET_OS_IPHONE)
#import <objc/objc-runtime.h>
#else
#import <objc/runtime.h>
#import <objc/message.h>
#endif

@interface RTBRuntimeHeader : NSObject

+ (NSArray *)sortedMethodsForClass:(Class)aClass isClassMethod:(BOOL)isClassMethod;
+ (NSArray *)sortedMethodsForClass:(Class)aClass isClassMethod:(BOOL)isClassMethod includeSuperclasses:(BOOL)includeSuperclasses;

+ (NSString *)decodedTypeForEncodedString:(NSString *)s;

+ (NSArray *)sortedProtocolsForClass:(Class)aClass;

+ (NSArray *)sortedPropertiesDictionariesForClass:(Class)aClass
                   displayPropertiesDefaultValues:(BOOL)displayPropertiesDefaultValues;

+ (NSArray *)sortedIvarDictionariesForClass:(Class)aClass;

+ (NSString *)descriptionForPropertyWithName:(NSString *)name
                                  attributes:(NSString *)attributes
              displayPropertiesDefaultValues:(BOOL)displayPropertiesDefaultValues;

+ (NSString *)headerForClass:(Class)aClass
displayPropertiesDefaultValues:(BOOL)displayPropertiesDefaultValues;

+ (NSString *)headerForProtocolName:(NSString *)protocolName;

+ (NSSet *)ivarSetForClass:(Class)aClass; // for search

+ (NSArray *)sortedProtocolsAdoptedByProtocol:(NSString *)protocol;
+ (NSArray *)sortedMethodsInProtocol:(NSString *)protocol required:(BOOL)required instanceMethods:(BOOL)instanceMethods;

+ (NSString *)descriptionForMethodName:(NSString *)methodName
                            returnType:(NSString *)returnType
                         argumentTypes:(NSArray *)argumentsTypes
                         isClassMethod:(BOOL)isClassMethod;

@end
