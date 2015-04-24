//
//  ProtocolStub.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 24/04/15.
//
//

#import "ProtocolStub.h"

@implementation ProtocolStub

+ (instancetype)protocolStubWithProtocolName:(NSString *)protocolName {
    ProtocolStub *ps = [[ProtocolStub alloc] init];
    ps.protocolName = protocolName;
    return ps;
}

- (NSArray *)children {
    return nil;
}

- (NSString *)nodeName {
    return _protocolName;
}

- (NSString *)nodeInfo {
    return [NSString stringWithFormat:@"%@", _protocolName];
}

@end
