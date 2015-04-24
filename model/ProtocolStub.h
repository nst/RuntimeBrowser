//
//  ProtocolStub.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 24/04/15.
//
//

#import <Foundation/Foundation.h>

@interface ProtocolStub : NSObject

@property (nonatomic, strong) NSString *protocolName;

+ (instancetype)protocolStubWithProtocolName:(NSString *)protocolName;

@end
