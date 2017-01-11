//
//  NSMutableAttributedString+RTB.m
//  OCRuntime
//
//  Created by Nicolas Seriot on 7/21/13.
//  Copyright (c) 2013 Nicolas Seriot. All rights reserved.
//

#import "NSMutableAttributedString+RTB.h"

@implementation NSMutableAttributedString (RTB)

- (void)setTextColor:(UIColor *)color font:(UIFont *)font range:(NSRange)range {
    NSDictionary *d = @{ NSForegroundColorAttributeName : color, NSFontAttributeName : font };
    if(range.location + range.length > [self length]) return;
    [self setAttributes:d range:range];
}

@end
