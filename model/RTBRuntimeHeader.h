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

+ (NSArray *)sortedMethodDictionariesForClass:(Class)aClass isClassMethod:(BOOL)isClassMethod;
+ (NSString *)descriptionForMethod:(Method)method isClassMethod:(BOOL)isClassMethod;

+ (NSString *)decodedTypeForEncodedString:(NSString *)s;

+ (NSArray *)sortedPropertiesDictionariesForClass:(Class)aClass;

+ (NSArray *)sortedIvarDictionariesForClass:(Class)aClass;

+ (NSString *)descriptionForPropertyWithName:(NSString *)name attributes:(NSString *)attributes;

+ (NSString *)headerForClass:(Class)aClass;

+ (NSSet *)ivarSetForClass:(Class)aClass; // for search

@end
