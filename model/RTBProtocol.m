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

@implementation RTBProtocol

- (NSComparisonResult)compare:(RTBProtocol *)other {
    return [self.protocolName compare:other.protocolName];
}

+ (instancetype)protocolStubWithProtocolName:(NSString *)protocolName {
    NSAssert([protocolName isKindOfClass:[NSString class]], @"");
    
    RTBProtocol *ps = [[RTBProtocol alloc] init];
    ps.protocolName = protocolName;
    ps.conformingClassesStubsSet = [NSMutableSet set];
    return ps;
}

- (NSArray *)sortedAdoptedProtocols {
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
