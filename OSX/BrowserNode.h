//
//  RootItem.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 2/20/11.
//  Copyright 2011 seriot.ch. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BrowserNode : NSObject

@property (nonatomic, strong) NSString *nodeName;
@property (nonatomic, strong) NSArray *children;

+ (BrowserNode *)rootNodeImages;
+ (BrowserNode *)rootNodeList;
+ (BrowserNode *)rootNodeTree;
+ (BrowserNode *)rootNodeProtocols;

- (NSImage *)icon;

@end
