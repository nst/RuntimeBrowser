//
//  ClassCell.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 13.08.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import "RTBClassCell.h"

@interface RTBClassCell ()
@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIButton *button;
@end

@implementation RTBClassCell

- (void)setClassName:(NSString *)s {
    _label.text = s;
}

- (NSString *)className {
    return _label.text;
}

- (IBAction)showHeaders:(id)sender {
    // TODO: use a notification here
	id appDelegate = [[UIApplication sharedApplication] delegate];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
	[appDelegate performSelector:@selector(showHeaderForClassName:) withObject:_label.text];
#pragma clang diagnostic pop
}

@end
