//
//  ProtocolStub.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 24/04/15.
//
//

#import "ProtocolStub.h"
#import "ClassStub.h"

@implementation ProtocolStub

- (NSComparisonResult)compare:(ProtocolStub *)other {
    return [self.protocolName compare:other.protocolName];
}

+ (instancetype)protocolStubWithProtocolName:(NSString *)protocolName {
    NSAssert([protocolName isKindOfClass:[NSString class]], @"");
    
    ProtocolStub *ps = [[ProtocolStub alloc] init];
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
