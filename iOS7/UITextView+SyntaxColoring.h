//
//  NSTextView+SyntaxColoring.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 04.08.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UITextView (SyntaxColoring)

- (void)colorizeWithKeywords:(NSArray *)keywords classes:(NSArray *)classes;

@end
