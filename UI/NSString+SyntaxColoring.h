//
//  NSTextView+SyntaxColoring.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 04.08.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

@interface NSString (SyntaxColoring)

- (NSAttributedString *)colorizeWithKeywords:(NSArray *)keywords classes:(NSArray *)classes colorize:(BOOL)colorize;

@end
