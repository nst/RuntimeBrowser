//
//  NSMutableAttributedString+RTB.m
//  OCRuntime
//
//  Created by Nicolas Seriot on 7/21/13.
//  Copyright (c) 2013 Nicolas Seriot. All rights reserved.
//

#import "NSMutableAttributedString+RTB.h"

@implementation NSMutableAttributedString (RTB)

- (void)setTextColor:(UIColor *)color range:(NSRange)range {
    
//    NSDictionary *d = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:60.0f],
//                         NSForegroundColorAttributeName : [UIColor redColor], NSBackgroundColorAttributeName : [UIColor blackColor]};
   
    NSDictionary *d = @{ NSForegroundColorAttributeName : color };
    
    [self setAttributes:d range:range];
}

@end
