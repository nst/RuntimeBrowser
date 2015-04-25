//
//  BrowserCell.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 2/21/11.
//  Copyright 2011 IICT. All rights reserved.
//

#import "BrowserCell.h"

@implementation BrowserCell

+ (NSImage *)branchImage {
	return nil;
}

+ (NSImage *)highlightedBranchImage {
	return nil;
}

+ (void)thisClassIsPartOfTheRuntimeBrowser {}

- (NSImage *)iconForPath:(NSString *)s {
    
    NSInteger viewType = [[NSUserDefaults standardUserDefaults] integerForKey:@"ViewType"];
    if(viewType == 3) { // protocols
        return [NSImage imageNamed:@"protocol.tiff"];
    }
    
    NSString *appExtension = @".app";
    NSRange range = [s rangeOfString:appExtension];
    if(range.location != NSNotFound) {
        NSString *path = [s substringToIndex:(range.location + [appExtension length])];
        return [[NSWorkspace sharedWorkspace] iconForFile:path];
    }
    
    NSArray *extensions = [NSArray arrayWithObjects:@".dylib", @".framework", @".bundle", @".dylib", nil];
    for(NSString *ext in extensions) {
        if([s rangeOfString:ext].location != NSNotFound) return [NSImage imageNamed:@"framework.tiff"];
    }
    
    return [NSImage imageNamed:@"class.tiff"];
}

- (void)setObjectValue:(id <NSCopying>)obj {
	
    NSImage *icon = [self iconForPath:(NSString *)obj];
    [icon setSize:NSMakeSize(16,16)];
	
	[self setImage:icon];
	
	[super setObjectValue:[(NSString *)obj lastPathComponent]];
}

@end
