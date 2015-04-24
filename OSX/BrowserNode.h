//
//  RootItem.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 2/20/11.
//  Copyright 2011 seriot.ch. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BrowserNode : NSObject {
	NSString *nodeName;
	NSArray *children;
}

@property (nonatomic, retain) NSString *nodeName;
@property (nonatomic, retain) NSArray *children;

+ (BrowserNode *)rootNodeImages;
+ (BrowserNode *)rootNodeList;
+ (BrowserNode *)rootNodeTree;
+ (BrowserNode *)rootNodeProtocols;

- (NSImage *)icon;

@end
