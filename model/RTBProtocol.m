//
//  ProtocolStub.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 24/04/15.
//
//

#import "RTBProtocol.h"
#import "RTBClass.h"

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
