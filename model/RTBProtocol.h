//
//  ProtocolStub.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 24/04/15.
//
//

#import <Foundation/Foundation.h>

@interface RTBProtocol : NSObject

@property (nonatomic, strong) NSString *protocolName;
@property (nonatomic, strong) NSMutableSet *conformingClassesStubsSet;

+ (instancetype)protocolStubWithProtocolName:(NSString *)protocolName;

- (NSArray *)sortedAdoptedProtocolsNames;
- (NSArray *)sortedMethodsRequired:(BOOL)required instanceMethods:(BOOL)instanceMethods;

// BrowserNode protocol

- (NSArray *)children; // same as subclassesStubs
- (NSString *)nodeName;// same as stubClassname
- (NSString *)nodeInfo;
- (BOOL)canBeSavedAsHeader;

- (BOOL)hasChildren;

@end
