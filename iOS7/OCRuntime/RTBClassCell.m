//
//  ClassCell.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 13.08.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import "RTBClassCell.h"

@implementation RTBClassCell

- (IBAction)showHeaders:(id)sender {
	id appDelegate = [[UIApplication sharedApplication] delegate];
	[appDelegate performSelector:@selector(showHeaderForClassName:) withObject:_label.text];
}

@end
