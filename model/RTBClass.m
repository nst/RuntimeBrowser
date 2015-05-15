/*
 
 ClassStub.m created by eepstein on Sat 16-Mar-2002
 
 Author: Ezra Epstein (eepstein@prajna.com)
 
 Copyright (c) 2002 by Prajna IT Consulting.
 http://www.prajna.com
 
 ========================================================================
 
 THIS PROGRAM AND THIS CODE COME WITH ABSOLUTELY NO WARRANTY.
 THIS CODE HAS BEEN PROVIDED "AS IS" AND THE RESPONSIBILITY
 FOR ITS OPERATIONS IS 100% YOURS.
 
 ========================================================================
 This file is part of RuntimeBrowser.
 
 RuntimeBrowser is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 RuntimeBrowser is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with RuntimeBrowser (in a file called "COPYING.txt"); if not,
 write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 Boston, MA  02111-1307  USA
 
 */

#import "RTBClass.h"
#import "RTBRuntimeHeader.h"
#import "RTBTypeDecoder.h"
#import "RTBMethod.h"

#if (! TARGET_OS_IPHONE)
#import <objc/objc-runtime.h>
#else
#import <objc/runtime.h>
#import <objc/message.h>
#endif

@interface RTBClass()
@property (nonatomic, retain) NSString *classObjectName;
@property (nonatomic, retain) NSMutableArray *subclassesStubs;
@property (nonatomic, retain) NSString *imagePath;
@property (nonatomic) BOOL shouldSortSubclasses;
@property (nonatomic) BOOL subclassesAreSorted;
@property (nonatomic, retain) NSSet *cachedMethodsNamePartsLowercase;
- (RTBClass *)initWithClass:(Class)klass;
@end

@implementation RTBClass

@synthesize classObjectName;
@synthesize imagePath;
@synthesize subclassesStubs;

+ (RTBClass *)classStubWithClass:(Class)klass {
    return [[RTBClass alloc] initWithClass:klass];
}

+ (void)thisClassIsPartOfTheRuntimeBrowser {
    /*" So the user knows when browsing this class in the RuntimeBrowser.
     We put this method last so it shows up first. "*/
}

- (BOOL)writeAtPath:(NSString *)path {
    
    NSURL *pathURL = [NSURL fileURLWithPath:path];
    
    Class klass = NSClassFromString(classObjectName);
    NSString *header = [RTBRuntimeHeader headerForClass:klass displayPropertiesDefaultValues:YES];
    
    NSError *error = nil;
    BOOL success = [header writeToURL:pathURL atomically:NO encoding:NSUTF8StringEncoding error:&error];
    if(success == NO) {
        NSLog(@"-- %@", error);
    }
    
    return success;
}

- (NSMutableSet *)iVarNames {
    Class klass = NSClassFromString(classObjectName);
    
    NSMutableSet *ms = [NSMutableSet set];
    
    unsigned int ivarListCount;
    Ivar *ivarList = class_copyIvarList(klass, &ivarListCount);
    
    if (ivarList != NULL && (ivarListCount>0)) {
        NSUInteger i;
        for (i = 0; i < ivarListCount; ++i ) {
            Ivar rtIvar = ivarList[i];
            const char* ivarName = ivar_getName(rtIvar);
            if(ivarName) [ms addObject:[[NSString stringWithCString:ivarName encoding:NSUTF8StringEncoding] lowercaseString]];
        }
    }
    
    free(ivarList);
    
    return ms;
}

+ (NSSet *)methodsNamePartsLowercaseForClass:(Class)klass {
    NSMutableSet *ms = [NSMutableSet set];
    
    unsigned int methodListCount;
    Method *methodList = class_copyMethodList(klass, &methodListCount);
    
    NSUInteger i;
    for (i = 0; i < methodListCount; i++) {
        Method currMethod = (methodList[i]);
        NSString *mName = [NSString stringWithCString:sel_getName(method_getName(currMethod)) encoding:NSASCIIStringEncoding];
        NSString *mNameLowercase = [mName lowercaseString];
        NSArray *mNameLowercaseParts = [mNameLowercase componentsSeparatedByString:@":"];
        [ms addObjectsFromArray:mNameLowercaseParts];
    }
    
    free(methodList);
    
    return ms;
}

- (NSSet *)methodsNamePartsLowercase {
    
    if(_cachedMethodsNamePartsLowercase == nil) {
        
        Class klass = NSClassFromString(classObjectName);
        Class metaClass = objc_getMetaClass(class_getName(klass));
        
        NSMutableSet *ms = [NSMutableSet set];
        
        [ms addObjectsFromArray:[[[self class] methodsNamePartsLowercaseForClass:klass] allObjects]];
        [ms addObjectsFromArray:[[[self class] methodsNamePartsLowercaseForClass:metaClass] allObjects]];
        
        [ms removeObject:@""];
        
        self.cachedMethodsNamePartsLowercase = ms;
    }
    
    return _cachedMethodsNamePartsLowercase;
}

- (NSMutableSet *)protocolsNames {
    
    Class class = NSClassFromString(classObjectName);
    if(class == nil) {
        NSLog(@"-- no class named %@", classObjectName);
        return nil;
    }
    
    NSMutableSet *ms = [NSMutableSet set];
    
    unsigned int protocolListCount = 0;
    __unsafe_unretained Protocol **protocolList = class_copyProtocolList(class, &protocolListCount);
    if (protocolList != NULL && (protocolListCount > 0)) {
        NSUInteger i;
        for(i = 0; i < protocolListCount; i++) {
            Protocol *p = protocolList[i];
            const char* protocolName = protocol_getName(p);
            if(protocolName) [ms addObject:[NSString stringWithCString:protocolName encoding:NSUTF8StringEncoding]];
        }
    }
    free(protocolList);
    
    return ms;
}

- (NSArray *)sortedProtocolsNames {
    NSArray *a = [[self protocolsNames] allObjects];
    
    return [a sortedArrayUsingSelector:@selector(compare:)];
}

- (NSSet *)iVarDecodedTypes {
    
    Class class = NSClassFromString(classObjectName);
    if(class == nil) {
        NSLog(@"-- no class named %@", classObjectName);
        return nil;
    }
    
    NSMutableSet *encodedTypesSet = [NSMutableSet set]; // use this to avoid decoding types that were already decoded
    NSMutableSet *decodedTypesSet = [NSMutableSet set];
    
    unsigned int ivarListCount;
    Ivar *ivarList = class_copyIvarList(class, &ivarListCount);
    
    for (unsigned int i = 0; i < ivarListCount; ++i ) {
        Ivar ivar = ivarList[i];
        
        NSString *encodedType = [NSString stringWithFormat:@"%s", ivar_getTypeEncoding(ivar)];
        
        if([encodedTypesSet containsObject:encodedType]) continue;
        
        NSString *decodedType = [RTBTypeDecoder decodeType:encodedType flat:NO];
        [decodedTypesSet addObject:decodedType];
        
        [encodedTypesSet addObject:encodedType];
    }
    free(ivarList);
    
    return decodedTypesSet;
}

- (NSMutableSet *)protocolsNamesLowercase {
    NSSet *tokens = [self protocolsNames];
    NSMutableSet *lowercaseTokens = [NSMutableSet set];
    for(NSString *token in tokens) {
        [lowercaseTokens addObject:[token lowercaseString]];
    }
    return lowercaseTokens;
}

- (NSMutableSet *)protocolsNamesWithSuperclassesProtocols:(BOOL)includeSuperclassesProtocols {
    
    Class class = NSClassFromString(classObjectName);
    NSAssert(class, @"no class named %@", classObjectName);
    
    NSMutableSet *ms = [self protocolsNames];
    
    if (includeSuperclassesProtocols) {
        Class c;
        for(c = class; class_getSuperclass(c) != c; c = class_getSuperclass(c)) {
            RTBClass *superCS = [RTBClass classStubWithClass:c];
            NSMutableSet *ms2 = [superCS protocolsNames];
            [ms unionSet:ms2];
        }
    }
    
    return ms;
}

- (RTBClass *)initWithClass:(Class)klass {
    self = [super init];
    
    NSString *className = NSStringFromClass(klass);
    
    [self setClassObjectName:className];
    
    const char* imageNameC = class_getImageName(klass);
    
    NSString *image = nil;
    if(imageNameC) {
        image = [NSString stringWithCString:imageNameC encoding:NSUTF8StringEncoding];
    } else {
        NSLog(@"-- cannot find image for class %@", className);
        //image = [[NSBundle bundleForClass:klass] bundlePath];
    }
    
    self.imagePath = image;
    
    self.subclassesStubs = [NSMutableArray array];
    _subclassesAreSorted = NO;
    _shouldSortSubclasses = YES;
    return self;
}

- (NSArray *)subclassesStubs {
    if (_subclassesAreSorted == NO && _shouldSortSubclasses) {
        [subclassesStubs sortUsingSelector:@selector(compare:)];
        _subclassesAreSorted = YES;
    }
    return (NSArray *)subclassesStubs;
}

- (void)addSubclassStub:(RTBClass *)classStub {
    [subclassesStubs addObject:classStub];
    _subclassesAreSorted = NO;
}

- (NSString *)description {
    return classObjectName;
}

- (NSComparisonResult)compare:(RTBClass *)otherCS {
    return [classObjectName compare:[otherCS classObjectName]];
}

- (BOOL)containsSearchString:(NSString *)searchString {
    
    NSString *ss = [searchString lowercaseString];
    
    if([[classObjectName lowercaseString] rangeOfString:ss].location != NSNotFound) {
        return YES;
    }
    
    for(NSString *s in [self iVarNames]) {
        if([[s lowercaseString] rangeOfString:ss].location != NSNotFound) {
            return YES;
        }
    }
    
    for(NSString *s in [self methodsNamePartsLowercase]) {
        if([s rangeOfString:ss].location != NSNotFound) {
            return YES;
        }
    }
    
    for(NSString *s in [self protocolsNamesLowercase]) {
        if([s rangeOfString:ss].location != NSNotFound) {
            return YES;
        }
    }
    
    for(NSString *s in [self iVarDecodedTypes]) {
        if([[s lowercaseString] rangeOfString:ss].location != NSNotFound) {
            return YES;
        }
    }
    
    return NO;
}

- (NSArray *)sortedIvarDictionaries {
    
    Class class = NSClassFromString(classObjectName);
    NSAssert(class, @"no class named %@", classObjectName);

    unsigned int ivarListCount;
    Ivar *ivarList = class_copyIvarList(class, &ivarListCount);
    
    NSMutableArray *ivarDictionaries = [NSMutableArray array];
    
    for (unsigned int i = 0; i < ivarListCount; ++i ) {
        Ivar ivar = ivarList[i];
        
        NSString *encodedType = [NSString stringWithFormat:@"%s", ivar_getTypeEncoding(ivar)];
        NSString *decodedType = [RTBTypeDecoder decodeType:encodedType flat:NO];
        
        // TODO: compiler may generate ivar entries with NULL ivar_name (e.g. for anonymous bit fields).
        NSString *name = [NSString stringWithFormat:@"%s", ivar_getName(ivar)];
        
        NSString *s = [NSString stringWithFormat:@"    %@%@;", decodedType, name];
        
        [ivarDictionaries addObject:@{@"name":name, @"description":s}];
        
    }
    free(ivarList);
    
    [ivarDictionaries sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        return [obj1[@"name"] compare:obj2[@"name"]];
    }];
    
    return ivarDictionaries;
}

- (NSArray *)sortedMethodsIsClassMethod:(BOOL)isClassMethod {
    
    Class aClass = NSClassFromString(classObjectName);
    NSAssert(aClass, @"no class named %@", classObjectName);

    Class class = aClass;
    
    if(isClassMethod) {
        class = objc_getMetaClass(class_getName(aClass));
    }
    
    NSMutableArray *ma = [NSMutableArray array];
    
    unsigned int methodListCount = 0;
    Method *methodList = class_copyMethodList(class, &methodListCount);
    
    for (NSUInteger i = 0; i < methodListCount; i++) {
        Method method = methodList[i];
        
        RTBMethod *m = [RTBMethod methodObjectWithMethod:method isClassMethod:isClassMethod];
        
        [ma addObject:m];
    }
    
    free(methodList);
    
    [ma sortUsingSelector:@selector(compare:)];
    
    return ma;
}

- (NSArray *)sortedPropertiesDictionariesWithDisplayPropertiesDefaultValues:(BOOL)displayPropertiesDefaultValues {
    
    Class aClass = NSClassFromString(classObjectName);
    NSAssert(aClass, @"no class named %@", classObjectName);

    NSMutableArray *ma = [NSMutableArray array];
    
    unsigned int propertiesCount = 0;
    objc_property_t *propertyList = class_copyPropertyList(aClass, &propertiesCount);
    
    for (unsigned int i = 0; i < propertiesCount; i++) {
        objc_property_t property = propertyList[i];
        
        NSString *name = [NSString stringWithCString:property_getName(property) encoding:NSASCIIStringEncoding];
        NSString *attributes = [NSString stringWithCString:property_getAttributes(property) encoding:NSASCIIStringEncoding];
        
        NSString *description = [RTBRuntimeHeader descriptionForPropertyWithName:name attributes:attributes displayPropertiesDefaultValues:displayPropertiesDefaultValues];
        
        NSDictionary *d = @{@"name":name, @"description":description};
        
        [ma addObject:d];
    }
    
    free(propertyList);
    
    [ma sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        return [obj1[@"name"] compare:obj2[@"name"]];
    }];
    
    return ma;
}

#pragma mark BrowserNode protocol

- (NSArray *)children {
    return [self subclassesStubs];
}

- (NSString *)nodeName {
    return classObjectName;
}

- (NSString *)nodeInfo {
    return [NSString stringWithFormat:@"%@ (%lu)", [self nodeName], (unsigned long)[[self children] count]];
}

- (BOOL)canBeSavedAsHeader {
    return YES;
}

@end
