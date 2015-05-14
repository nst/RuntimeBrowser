//
//  ProtocolStub.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 24/04/15.
//
//

#import "RTBProtocol.h"
#import "RTBClass.h"
#import <objc/runtime.h>
#import "RTBRuntimeHeader.h"

@implementation RTBProtocol

- (NSComparisonResult)compare:(RTBProtocol *)other {
    return [self.protocolName compare:other.protocolName];
}

+ (instancetype)protocolStubWithProtocolName:(NSString *)protocolName {
    NSAssert([protocolName isKindOfClass:[NSString class]], @"");
    
    RTBProtocol *p = [[RTBProtocol alloc] init];
    p.protocolName = protocolName;
    p.conformingClassesStubsSet = [NSMutableSet set];
    return p;
}

- (NSArray *)sortedAdoptedProtocolsNames {
    Protocol *p = NSProtocolFromString(_protocolName);
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

- (NSArray *)sortedMethodsRequired:(BOOL)required instanceMethods:(BOOL)instanceMethods {
    Protocol *p = NSProtocolFromString([self protocolName]);
    if(p == nil) return nil;
    
    NSMutableArray *ma = [NSMutableArray array];
    
    unsigned int outCount = 0;
    struct objc_method_description *methods = protocol_copyMethodDescriptionList(p, required, instanceMethods, &outCount);
    for(int i = 0; i < outCount; i++) {
        struct objc_method_description method = methods[i];
        
        NSString *name = NSStringFromSelector(method.name);
        NSString *description = [RTBRuntimeHeader descriptionForProtocol:p selector:method.name isRequiredMethod:required isInstanceMethod:instanceMethods];
        
        NSDictionary *d = @{@"name":name, @"description":description};
        
        [ma addObject:d];
    }
    
    free(methods);
    
    [ma sortUsingComparator:^NSComparisonResult(NSDictionary *d1, NSDictionary *d2) {
        return [d1[@"name"] compare:d2[@"name"]];
    }];
    
    return ma;
}

- (NSString *)description {
    NSString *superDescription = [super description];
    return [NSString stringWithFormat:@"%@ - %@", superDescription, _protocolName];
}

- (BOOL)hasChildren {
    return [_conformingClassesStubsSet count] > 0;
}

#pragma mark BrowserNode protocol

- (NSArray *)children {
    NSMutableArray *ma = [[_conformingClassesStubsSet allObjects] mutableCopy];
    
    [ma sortedArrayUsingSelector:@selector(compare:)];
    
    return ma;
}

- (NSString *)nodeName {
    return _protocolName;
}

- (NSString *)nodeInfo {
    return [NSString stringWithFormat:@"%@", _protocolName];
}

- (BOOL)canBeSavedAsHeader {
    return YES;
}

@end
