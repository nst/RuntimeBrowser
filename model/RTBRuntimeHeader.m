//
//  RTBTypeParser.m
//  runtime_cli
//
//  Created by Nicolas Seriot on 02/04/15.
//
//

#import "RTBRuntimeHeader.h"
#import "RTBTypeDecoder.h"

@implementation RTBRuntimeHeader

+ (NSString *)decodedTypeForEncodedString:(NSString *)s {
    return [RTBTypeDecoder decodeType:s flat:YES];
}

+ (NSArray *)sortedMethodDictionariesForClass:(Class)aClass isClassMethod:(BOOL)isClassMethod {
    
    Class class = aClass;
    
    if(isClassMethod) {
        class = objc_getMetaClass(class_getName(aClass));
    }
    
    NSMutableArray *ma = [NSMutableArray array];
    
    unsigned int methodListCount = 0;
    Method *methodList = class_copyMethodList(class, &methodListCount);
    
    for (NSUInteger i = 0; i < methodListCount; i++) {
        Method method = methodList[i];
        
        
//        id signature = [aClass methodSignatureForSelector:method_getName(method)];
//        NSLog(@"--> %@", [signature debugDescription]);

        
        NSString *name = NSStringFromSelector(method_getName(method));
        NSString *description = [[self class] descriptionForMethod:method isClassMethod:isClassMethod];
        
        NSDictionary *d = @{@"name":name, @"description":description};
        
        [ma addObject:d];
    }
    
    free(methodList);
    
    [ma sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        return [obj1[@"name"] compare:obj2[@"name"]];
    }];
    
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

+ (NSArray *)argumentTypesForMethod:(Method)method {
    unsigned int numberOfArguments = method_getNumberOfArguments(method);
    
    NSMutableArray *argumentsTypes = [NSMutableArray array];
    for(unsigned int i = 0; i < numberOfArguments; i++) {
        char *argType = method_copyArgumentType(method, i);
        NSAssert(argType != NULL, @"");
        NSString *encodedType = [NSString stringWithCString:argType encoding:NSASCIIStringEncoding];
        free(argType);
        
        NSString *decodedType = [RTBTypeDecoder decodeType:encodedType flat:YES];
        [argumentsTypes addObject:decodedType];
    }
    return argumentsTypes;
}

+ (NSString *)descriptionForPropertyWithName:(NSString *)name attributes:(NSString *)attributes displayPropertiesDefaultValues:(BOOL)displayPropertiesDefaultValues {
    
    //NSLog(@"---- %@ | %@", name, attributes);
    
    NSString *getter = nil;
    NSString *setter = nil;
    NSString *type = nil;
    NSString *memory = nil;
    NSString *rw = nil;
    NSString *comment = nil;
    
    NSArray *attributesComponents = [attributes componentsSeparatedByString:@","];
    for(NSString *attribute in attributesComponents) {
        NSAssert([attributes length] >= 2, @"");
        unichar c = [attribute characterAtIndex:0];
        NSString *tail = [attribute substringFromIndex:1];
        if (c == 'R') rw = @"readonly";
        else if (c == 'C') rw = @"copy";
        else if (c == '&') rw = @"retain";
        else if (c == 'G') getter = tail;
        else if (c == 'S') setter = tail;
        else if (c == 't' || c == 'T') type = [RTBTypeDecoder decodeType:tail flat:YES];
        else if (c == 'D') {} // The property is dynamic (@dynamic)
        else if (c == 'W') {} // The property is a weak reference (__weak)
        else if (c == 'P') {} // The property is eligible for garbage collection
        else if (c == 'N') {} // The property is non-atomic (nonatomic)
        else if (c == 'V') {} // oneway
        else comment = [NSString stringWithFormat:@"/* unknown property attribute: %@ */", attribute];
    }
    
        if(displayPropertiesDefaultValues) {
            if(!memory) memory = @"assign";
            if(!rw) rw = @"readwrite";
        }
    
    NSMutableString *ms = [NSMutableString stringWithString:@"@property"];
    
    NSMutableArray *attributesString = [NSMutableArray array];
    if(getter) [attributesString addObject:[NSString stringWithFormat:@"getter=%@", getter]];
    if(setter) [attributesString addObject:[NSString stringWithFormat:@"setter=%@", setter]];
    if(memory) [attributesString addObject:memory];
    if(rw)     [attributesString addObject:rw];
    
    if([attributesString count] > 0) {
        NSString *attributesDescription = [NSString stringWithFormat:@"(%@)", [attributesString componentsJoinedByString:@","]];
        [ms appendString:attributesDescription];
    }
    
    [ms appendFormat:@" %@ %@;", type, name];
    
    if(comment)
        [ms appendFormat:@" %@", comment];
    
    return ms;
}

+ (NSString *)descriptionForMethod:(Method)method isClassMethod:(BOOL)isClassMethod {
    
    NSString *returnType = [NSString stringWithCString:method_copyReturnType(method) encoding:NSASCIIStringEncoding];
    NSString *methodName = NSStringFromSelector(method_getName(method));
    
    NSArray *methodNameParts = [methodName componentsSeparatedByString:@":"];
    NSAssert([methodNameParts count] > 0, @"");
    
    NSMutableString *ms = [NSMutableString string];
    [ms appendString: isClassMethod ? @"+" : @"-"];
    [ms appendFormat:@" (%@)", [RTBTypeDecoder decodeType:returnType flat:YES]];
    
    NSArray *argumentsTypes = [self argumentTypesForMethod:method];
    
    //    NSLog(@"-- parts: %@", methodNameParts);
    //    NSLog(@"-- types: %@", argumentsTypes);
    
    BOOL hasArgs = [argumentsTypes count] > 2;
    
    [methodNameParts enumerateObjectsUsingBlock:^(NSString *part, NSUInteger i, BOOL *stop) {
        
        if(i == [methodNameParts count] - 1 && [part isEqualToString:@""]) {
            [ms deleteCharactersInRange:NSMakeRange([ms length]-1, 1)]; // remove extraneous space
            *stop = YES;
            return;
        }
        
        [ms appendString:part];
        
        if(hasArgs) {
            [ms appendFormat:@":(%@)arg%@ ", argumentsTypes[i+2], @(i+1)]; // offset of 2 because argumentsTypes start with cmd and sel
        }
    }];
    
    [ms appendString:@";"];
    
    return ms;
}

+ (NSArray *)sortedProtocolsForClass:(Class)class {
    NSMutableArray *protocols = [NSMutableArray array];
    
    unsigned int protocolListCount = 0;
    __unsafe_unretained Protocol **protocolList = class_copyProtocolList(class, &protocolListCount);
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
    NSArray *sortedClassMethodsDictionaries = [self sortedMethodDictionariesForClass:aClass isClassMethod:YES];
    for(NSDictionary *d in sortedClassMethodsDictionaries) {
        [header appendFormat:@"%@\n", d[@"description"]];
    }
    if([sortedClassMethodsDictionaries count] > 0) {
        [header appendString:@"\n"];
    }
    
    // instance methods
    // class methods
    NSArray *sortedInstanceMethodsDictionaries = [self sortedMethodDictionariesForClass:aClass isClassMethod:NO];
    for(NSDictionary *d in sortedInstanceMethodsDictionaries) {
        [header appendFormat:@"%@\n", d[@"description"]];
    }
    if([sortedInstanceMethodsDictionaries count] > 0) {
        [header appendString:@"\n"];
    }
    
    [header appendString:@"@end\n"];
    
    return header;
}

@end
