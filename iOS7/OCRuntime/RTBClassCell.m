//
//  ClassCell.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 13.08.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import "RTBClassCell.h"
#import "ClassStub.h"

@interface RTBClassCell ()
@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIButton *button;
@end

@implementation RTBClassCell

@synthesize classStub = _classStub;

- (void)setClassStub:(ClassStub *)classStub {
    _classStub = classStub;
    _label.text = classStub.stubClassname;
}

- (ClassStub *)classStub {
    return _classStub;
}

/*
- (NSString *)className {
    return _label.text;
}
*/

- (IBAction)showHeaders:(id)sender {
    // TODO: use a notification here
	id appDelegate = [[UIApplication sharedApplication] delegate];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
	[appDelegate performSelector:@selector(showHeaderForClassStub:) withObject:self.classStub];
#pragma clang diagnostic pop
}

@end
