//
//  NSMutableAttributedString+RTB.h
//  OCRuntime
//
//  Created by Nicolas Seriot on 7/21/13.
//  Copyright (c) 2013 Nicolas Seriot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableAttributedString (RTB)

#if TARGET_OS_IPHONE
- (void)setTextColor:(UIColor *)color font:(UIFont *)font range:(NSRange)range;
#else
- (void)setTextColor:(NSColor *)color font:(NSFont *)font range:(NSRange)range;
#endif

@end
