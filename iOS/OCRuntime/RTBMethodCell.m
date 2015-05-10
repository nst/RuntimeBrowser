//
//  MethodCell.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 13.08.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import "RTBMethodCell.h"
#import "NSString+SyntaxColoring.h"

static NSArray *cachedKeywords = nil;

@implementation RTBMethodCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    RTBMethodCell *cell = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.textLabel.numberOfLines = 0;
    return cell;
}

- (void)setMethod:(RTBMethod *)method {
    _method = method;

    BOOL hasArguments = [method hasArguments];
    self.accessoryType = hasArguments ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
    NSString *returnType = [method returnTypeDecoded];
    
    NSString *selectorString = [method selectorString];
    
    if ([selectorString isEqualToString:@"alloc"] || [selectorString isEqualToString:@"init"]) {
        self.textLabel.textColor = [UIColor blueColor];
    } else if ([returnType isEqualToString:@"void"]  && !hasArguments && ([selectorString isEqualToString:@".cxx_destruct"] || [selectorString isEqualToString:@"dealloc"])) {
        self.textLabel.textColor = [UIColor orangeColor];
    } else {
        self.textLabel.textColor = [UIColor blackColor];
    }
    
    if(cachedKeywords == nil) {
        NSString *keywordsPath = [[NSBundle mainBundle] pathForResource:@"Keywords" ofType:@"plist"];
        NSArray *keywords = [NSArray arrayWithContentsOfFile:keywordsPath];
        cachedKeywords = keywords;
    }
    
    NSString *s = [method headerDescriptionWithNewlineAfterArgs:NO];
    
    NSAttributedString *as = [s colorizeWithKeywords:cachedKeywords classes:nil colorize:YES];
    
    self.textLabel.attributedText = as;
}

@end
