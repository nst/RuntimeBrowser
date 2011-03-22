//
//  RootItem.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 2/20/11.
//  Copyright 2011 seriot.ch. All rights reserved.
//

#import "BrowserNode.h"
#import "AllClasses.h"

@implementation BrowserNode

@synthesize nodeName;
@synthesize children;

+ (BrowserNode *)rootNodeList {
	BrowserNode *rn = [[BrowserNode alloc] init];
	rn.children = [[AllClasses sharedInstance] sortedClassStubs];
	return [rn autorelease];
}

+ (BrowserNode *)rootNodeTree {
	BrowserNode *rn = [[BrowserNode alloc] init];
	rn.children = [[AllClasses sharedInstance] rootClasses];
	return [rn autorelease];
}

+ (BrowserNode *)rootNodeImages {
	BrowserNode *bn = [[BrowserNode alloc] init];
	
	NSDictionary *allStubsByImage = [AllClasses sharedInstance].allClassStubsByImagePath;
	
	NSMutableArray *images = [NSMutableArray array];
	
	for(NSString *image in [allStubsByImage allKeys]) {
		BrowserNode *node = [[BrowserNode alloc] init];
		node.nodeName = image;
		NSMutableArray *stubs = [NSMutableArray arrayWithArray:[allStubsByImage valueForKey:image]];
		[stubs sortUsingSelector:@selector(compare:)];
		node.children = stubs;
		[images addObject:node];
		[node release];
	}
	
	[images sortUsingSelector:@selector(compare:)]; // TODO: sort by lastPathComponent?
	
	bn.nodeName = @"Images";
	bn.children = images;
	return [bn autorelease];
}

- (NSImage *)icon {

    NSArray *extensions = [NSArray arrayWithObjects:@".app", @".framework", @".bundle", @".dylib", nil];
    for(NSString *ext in extensions) {
		NSRange range = [nodeName rangeOfString:ext];
		if(range.location != NSNotFound) {
			NSString *bundlePath = [nodeName substringToIndex:(range.location + [ext length])];
			return [[NSWorkspace sharedWorkspace] iconForFile:bundlePath];
		}
	}
	
	return nil;
}

+ (void)thisClassIsPartOfTheRuntimeBrowser {}

- (NSComparisonResult)compare:(BrowserNode *)otherNode {
    return [nodeName compare:[otherNode nodeName]];
}

- (NSString *)nodeInfo {
    NSArray *pathComponents = [nodeName componentsSeparatedByString:@"/"];
    return [NSString stringWithFormat:@"%@ (%d)", [pathComponents lastObject], [children count]];
}

- (void)dealloc {
	[children release];
	[nodeName release];
	return [super dealloc];
}

- (BOOL)canBeSavedAsHeader {
	return NO;
}

@end
