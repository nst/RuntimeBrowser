//
//  NSMutableAttributedString+RTB.h
//  OCRuntime
//
//  Created by Nicolas Seriot on 7/21/13.
//  Copyright (c) 2013 Nicolas Seriot. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
@compatibility_alias UIColor NSColor;
@compatibility_alias UIFont NSFont;
#endif

#import <Foundation/Foundation.h>

@interface NSMutableAttributedString (RTB)

- (void)setTextColor:(UIColor *)color font:(UIFont *)font range:(NSRange)range;

@end
