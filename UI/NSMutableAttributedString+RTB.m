//
//  NSMutableAttributedString+RTB.m
//  OCRuntime
//
//  Created by Nicolas Seriot on 7/21/13.
//  Copyright (c) 2013 Nicolas Seriot. All rights reserved.
//

#import "NSMutableAttributedString+RTB.h"

@implementation NSMutableAttributedString (RTB)

#if TARGET_OS_IPHONE
- (void)setTextColor:(UIColor *)color font:(UIFont *)font range:(NSRange)range {
#else
- (void)setTextColor:(NSColor *)color font:(NSFont *)font range:(NSRange)range {
#endif

    NSDictionary *d = @{ NSForegroundColorAttributeName : color, NSFontAttributeName : font };
    [self setAttributes:d range:range];
}

@end
