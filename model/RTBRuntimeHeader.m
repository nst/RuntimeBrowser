//
//  RTBTypeParser.m
//  runtime_cli
//
//  Created by Nicolas Seriot on 02/04/15.
//
//

#import "RTBRuntimeHeader.h"
#import "RTBTypeDecoder.h"
#import "RTBMethod.h"

OBJC_EXPORT const char *_protocol_getMethodTypeEncoding(Protocol *, SEL, BOOL isRequiredMethod, BOOL isInstanceMethod) __OSX_AVAILABLE_STARTING(__MAC_10_8, __IPHONE_6_0);

@implementation RTBRuntimeHeader

+ (NSString *)decodedTypeForEncodedString:(NSString *)s {
    return [RTBTypeDecoder decodeType:s flat:YES];
}

+ (NSArray *)sortedMethodsForClass:(Class)aClass isClassMethod:(BOOL)isClassMethod {
    
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

+ (NSArray *)sortedPropertiesDictionariesForClass:(Class)aClass displayPropertiesDefaultValues:(BOOL)displayPropertiesDefaultValues {
    
    NSMutableArray *ma = [NSMutableArray array];
    
    unsigned int propertiesCount = 0;
    objc_property_t *propertyList = class_copyPropertyList(aClass, &propertiesCount);
    
    for (unsigned int i = 0; i < propertiesCount; i++) {
        objc_property_t property = propertyList[i];
        
        NSString *name = [NSString stringWithCString:property_getName(property) encoding:NSASCIIStringEncoding];
        NSString *attributes = [NSString stringWithCString:property_getAttributes(property) encoding:NSASCIIStringEncoding];
        
        NSString *description = [[self class] descriptionForPropertyWithName:name attributes:attributes displayPropertiesDefaultValues:displayPropertiesDefaultValues];
        
        NSDictionary *d = @{@"name":name, @"description":description};
        
        [ma addObject:d];
    }
    
    free(propertyList);
    
    [ma sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        return [obj1[@"name"] compare:obj2[@"name"]];
    }];
    
    return ma;
}

+ (NSString *)descriptionForPropertyWithName:(NSString *)name attributes:(NSString *)attributes displayPropertiesDefaultValues:(BOOL)displayPropertiesDefaultValues {
    
    // https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
    
    NSString *getter = nil;
    NSString *setter = nil;
    NSString *type = nil;
    NSString *atomicity = nil;
    NSString *memory = nil;
    NSString *rw = nil;
    NSString *comment = nil;
    
    NSArray *attributesComponents = [attributes componentsSeparatedByString:@","];
    for(NSString *attribute in attributesComponents) {
        NSAssert([attributes length] >= 2, @"");
        unichar c = [attribute characterAtIndex:0];
        NSString *tail = [attribute substringFromIndex:1];
        if (c == 'R') rw = @"readonly";
        else if (c == 'C') memory = @"copy";
        else if (c == '&') memory = @"retain";
        else if (c == 'G') getter = tail; // custom getter
        else if (c == 'S') setter = tail; // custome setter
        else if (c == 't' || c == 'T') type = [RTBTypeDecoder decodeType:tail flat:YES]; // Specifies the type using old-style encoding
        else if (c == 'D') {} // The property is dynamic (@dynamic)
        else if (c == 'W') {} // The property is a weak reference (__weak)
        else if (c == 'P') {} // The property is eligible for garbage collection
        else if (c == 'N') {} // memory - The property is non-atomic (nonatomic)
        else if (c == 'V') {} // oneway
        else comment = [NSString stringWithFormat:@"/* unknown property attribute: %@ */", attribute];
    }
    
    if(displayPropertiesDefaultValues) {
        if(!atomicity) atomicity = @"nonatomic";
        if(!rw) rw = @"readwrite";
    }
    
    NSMutableString *ms = [NSMutableString stringWithString:@"@property "];
    
    NSMutableArray *attributesArray = [NSMutableArray array];
    if(getter)    [attributesArray addObject:[NSString stringWithFormat:@"getter=%@", getter]];
    if(setter)    [attributesArray addObject:[NSString stringWithFormat:@"setter=%@", setter]];
    if(atomicity) [attributesArray addObject:atomicity];
    if(rw)        [attributesArray addObject:rw];
    if(memory)    [attributesArray addObject:memory];
    
    if([attributesArray count] > 0) {
        NSString *attributesDescription = [NSString stringWithFormat:@"(%@)", [attributesArray componentsJoinedByString:@", "]];
        [ms appendString:attributesDescription];
    }
    
    [ms appendFormat:@" %@ %@;", type, name];
    
    if(comment)
        [ms appendFormat:@" %@", comment];
    
    return ms;
}

+ (NSString *)descriptionForMethodName:(NSString *)methodName
                            returnType:(NSString *)returnType
                         argumentTypes:(NSArray *)argumentsTypes
                      newlineAfterArgs:(BOOL)newlineAfterArgs
                         isClassMethod:(BOOL)isClassMethod {
    
    //NSLog(@"-- methodName: %@", methodName);
    
    NSArray *methodNameParts = [methodName componentsSeparatedByString:@":"];
    if([[methodNameParts lastObject] length] == 0) {
        methodNameParts = [methodNameParts subarrayWithRange:NSMakeRange(0, [methodNameParts count]-1)];
    }
    NSAssert([methodNameParts count] > 0, @"");
    
    NSMutableArray *ma = [NSMutableArray array];
    
    __block NSMutableString *ms = [NSMutableString string];
    
    NSString *signAndReturnTypeString = [NSString stringWithFormat:@"%c (%@)", (isClassMethod ? '+' : '-'), returnType];
    
    [ms appendString:signAndReturnTypeString];
    
    BOOL hasArgs = [argumentsTypes count] > 2;
    
    __block NSUInteger paddingIndex = 0;
    
    [methodNameParts enumerateObjectsUsingBlock:^(NSString *part, NSUInteger i, BOOL *stop) {
        
        [ms appendString:part];

        if(hasArgs) {
            NSString *s = [NSString stringWithFormat:@":(%@)arg%@", argumentsTypes[i+2], @(i+1)];
            
            if(paddingIndex == 0) {
                paddingIndex = [ms length];
            }
            
            paddingIndex = MAX(paddingIndex, [part length]);
            
            [ms appendString:s];
            
            BOOL isLastPart = i == [methodNameParts count] - 1;
            
            [ms appendString:(isLastPart ? @";" : @" ")];
        }

        [ma addObject:ms];
        ms = [NSMutableString string];
    }];
    
    if([[ma lastObject] hasSuffix:@";"] == NO) {
        [[ma lastObject] appendString:@";"];
    }

    NSString *joinerString = @"";
    
    if(newlineAfterArgs) {
        NSMutableArray *ma2 = [NSMutableArray array];
        
        [ma enumerateObjectsUsingBlock:^(NSString *s, NSUInteger idx, BOOL *stop) {
            NSString *part = methodNameParts[idx];
            if(idx == 0) {
                part = [part stringByAppendingString:signAndReturnTypeString];
            }
            NSMutableString *_ms = [NSMutableString string];
            NSInteger padSize = paddingIndex - [part length];
            if(padSize < 0) padSize = 0;
            for(int i = 0; i < padSize; i++) [_ms appendString:@" "];
            NSString *s2 = [_ms stringByAppendingString:s];
            
            [ma2 addObject:s2];
            
        }];
        
        ma = ma2;
        
        joinerString = @"\n";
    }
    
    NSString *s = [ma componentsJoinedByString:joinerString];
    
    return s;
}

+ (NSString *)descriptionForProtocol:(Protocol *)protocol selector:(SEL)selector isRequiredMethod:(BOOL)isRequiredMethod isInstanceMethod:(BOOL)isInstanceMethod {
    
    const char *descriptionString = _protocol_getMethodTypeEncoding(protocol, selector, isRequiredMethod, isInstanceMethod);
    NSString *argumentTypesEncodedString = [NSString stringWithCString:descriptionString encoding:NSUTF8StringEncoding];
    NSArray *argumentTypes = [RTBTypeDecoder decodeTypes:argumentTypesEncodedString flat:YES];
    NSString *returnType = [argumentTypes objectAtIndex:0];
    NSString *methodName = NSStringFromSelector(selector);
    
    return [self descriptionForMethodName:methodName
                               returnType:returnType
                            argumentTypes:[argumentTypes subarrayWithRange:NSMakeRange(1, [argumentTypes count]-1)]
                         newlineAfterArgs:NO
                            isClassMethod:(isInstanceMethod == NO)];
}

+ (NSArray *)sortedProtocolsForClass:(Class)aClass {
    NSMutableArray *protocols = [NSMutableArray array];
    
    unsigned int protocolListCount = 0;
    __unsafe_unretained Protocol **protocolList = class_copyProtocolList(aClass, &protocolListCount);
    for(unsigned int i = 0; i < protocolListCount; i++) {
        NSString *name = [NSString stringWithCString:protocol_getName(protocolList[i]) encoding:NSUTF8StringEncoding];
        [protocols addObject:name];
    }
    
    free(protocolList);
    
    [protocols sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];
    
    return protocols;
}

+ (NSArray *)sortedIvarDictionariesForClass:(Class)aClass {
    
    unsigned int ivarListCount;
    Ivar *ivarList = class_copyIvarList(aClass, &ivarListCount);
    
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

+ (NSSet *)ivarSetForClass:(Class)aClass {
    NSArray *a = [self sortedIvarDictionariesForClass:aClass];
    NSArray *descriptions = [a valueForKey:@"description"];
    return [NSMutableSet setWithArray:descriptions];
}

+ (NSString *)headerForClass:(Class)aClass displayPropertiesDefaultValues:(BOOL)displayPropertiesDefaultValues {
    if(aClass == nil) return nil;
    
    NSMutableString *header = [NSMutableString string];
    
    // top header
    [header appendFormat:@"/* Generated by RuntimeBrowser\n   Image: %s\n */\n\n", class_getImageName(aClass)];
    
    // @interface NSString : NSObject <NSCopying, NSMutableCopying, NSSecureCoding>
    
    // interface declaration
    [header appendFormat:@"@interface %s ", class_getName(aClass)];
    
    // inheritance
    Class superClass = class_getSuperclass(aClass);
    if (superClass)
        [header appendFormat: @": %s", class_getName(superClass)];
    
    // protocols
    NSArray *protocols = [[self class] sortedProtocolsForClass:aClass];
    if([protocols count] > 0) {
        NSString *protocolsString = [protocols componentsJoinedByString:@", "];
        [header appendFormat:@" <%@>", protocolsString];
    }
    
    // ivars
    NSArray *sortedIvarDictionaries = [self sortedIvarDictionariesForClass:aClass];
    if([sortedIvarDictionaries count] > 0){
        [header appendString:@" {\n"];
        for(NSDictionary *d in sortedIvarDictionaries) {
            [header appendFormat:@"%@\n", d[@"description"]];
        }
        [header appendString:@"}"];
    }
    [header appendString:@"\n\n"];
    
    // properties
    NSArray *propertiesDictionaries = [self sortedPropertiesDictionariesForClass:aClass displayPropertiesDefaultValues:displayPropertiesDefaultValues];
    for(NSDictionary *d in propertiesDictionaries) {
        [header appendFormat:@"%@\n", d[@"description"]];
    }
    if([propertiesDictionaries count] > 0) {
        [header appendString:@"\n"];
    }
    
    // class methods
    NSArray *sortedClassMethods = [self sortedMethodsForClass:aClass isClassMethod:YES];
    for(RTBMethod *m in sortedClassMethods) {
        [header appendFormat:@"%@\n", [m headerDescriptionWithNewlineAfterArgs:NO]];
    }
    if([sortedClassMethods count] > 0) {
        [header appendString:@"\n"];
    }
    
    // instance methods
    // class methods
    NSArray *sortedInstanceMethods = [self sortedMethodsForClass:aClass isClassMethod:NO];
    for(RTBMethod *m in sortedInstanceMethods) {
        [header appendFormat:@"%@\n", [m headerDescriptionWithNewlineAfterArgs:NO]];
    }
    if([sortedInstanceMethods count] > 0) {
        [header appendString:@"\n"];
    }
    
    [header appendString:@"@end\n"];
    
    return header;
}

+ (NSArray *)sortedProtocolsAdoptedByProtocol:(NSString *)protocol {
    Protocol *p = NSProtocolFromString(protocol);
    if(p == nil) return nil;
    
    NSMutableArray *ma = [NSMutableArray array];
    
    unsigned int outCount = 0;
    __unsafe_unretained Protocol **protocolList = protocol_copyProtocolList(p, &outCount);
    for(int i = 0; i < outCount; i++) {
        Protocol *adoptedProtocol = protocolList[i];
        NSString *adoptedProtocolName = [NSString stringWithCString:protocol_getName(adoptedProtocol) encoding:NSUTF8StringEncoding];
        [ma addObject:adoptedProtocolName];
    }
    free(protocolList);
    
    [ma sortedArrayUsingSelector:@selector(compare:)];
    
    return ma;
}

+ (NSArray *)sortedMethodsInProtocol:(NSString *)protocol required:(BOOL)required instanceMethods:(BOOL)instanceMethods {
    Protocol *p = NSProtocolFromString(protocol);
    if(p == nil) return nil;
    
    NSMutableArray *ma = [NSMutableArray array];
    
    unsigned int outCount = 0;
    struct objc_method_description *methods = protocol_copyMethodDescriptionList(p, required, instanceMethods, &outCount);
    for(int i = 0; i < outCount; i++) {
        struct objc_method_description method = methods[i];
        
        NSString *name = NSStringFromSelector(method.name);
        NSString *description = [[self class] descriptionForProtocol:p selector:method.name isRequiredMethod:required isInstanceMethod:instanceMethods];
        
        NSDictionary *d = @{@"name":name, @"description":description};
        
        [ma addObject:d];
    }
    
    free(methods);
    
    [ma sortUsingComparator:^NSComparisonResult(NSDictionary *d1, NSDictionary *d2) {
        return [d1[@"name"] compare:d2[@"name"]];
    }];
    
    return ma;
}

+ (NSString *)headerForProtocolName:(NSString *)protocolName {
    NSMutableString *header = [NSMutableString string];
    
    [header appendString:@"/* Generated by RuntimeBrowser.\n */\n\n"];
    
    [header appendFormat:@"@protocol %@", protocolName];
    
    // adopted protocols
    NSArray *adoptedProtocols = [self sortedProtocolsAdoptedByProtocol:protocolName];
    if([adoptedProtocols count]) {
        NSString *adoptedProtocolsString = [adoptedProtocols componentsJoinedByString:@", "];
        [header appendFormat:@" <%@>", adoptedProtocolsString];
    }
    [header appendString:@"\n\n"];
    
    NSArray *requiredClassMethods = [self sortedMethodsInProtocol:protocolName required:YES instanceMethods:NO];
    NSArray *requiredInstanceMethods = [self sortedMethodsInProtocol:protocolName required:YES instanceMethods:YES];
    NSArray *optionalClassMethods = [self sortedMethodsInProtocol:protocolName required:NO instanceMethods:NO];
    NSArray *optionalInstanceMethods = [self sortedMethodsInProtocol:protocolName required:NO instanceMethods:YES];
    
    if([requiredClassMethods count] + [requiredInstanceMethods count] > 0) {
        [header appendString:@"@required\n\n"];
    }
    
    // required class methods
    for(NSDictionary *d in requiredClassMethods) {
        [header appendFormat:@"%@\n", d[@"description"]];
    }
    if([requiredClassMethods count] > 0) {
        [header appendString:@"\n"];
    }
    
    // required instance methods
    for(NSDictionary *d in requiredInstanceMethods) {
        [header appendFormat:@"%@\n", d[@"description"]];
    }
    if([requiredInstanceMethods count] > 0) {
        [header appendString:@"\n"];
    }
    
    if([optionalClassMethods count] + [optionalInstanceMethods count] > 0) {
        [header appendString:@"@optional\n\n"];
    }
    
    // optional class methods
    for(NSDictionary *d in optionalClassMethods) {
        [header appendFormat:@"%@\n", d[@"description"]];
    }
    if([optionalClassMethods count] > 0) {
        [header appendString:@"\n"];
    }
    
    // optional instance methods
    for(NSDictionary *d in optionalInstanceMethods) {
        [header appendFormat:@"%@\n", d[@"description"]];
    }
    if([optionalInstanceMethods count] > 0) {
        [header appendString:@"\n"];
    }
    
    [header appendString:@"@end\n"];
    
    return header;
}

@end
