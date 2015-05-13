//
//  ClassCell.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 13.08.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import "RTBProtocolCell.h"

@interface RTBProtocolCell ()
@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIButton *button;
@end

@implementation RTBProtocolCell

- (void)setProtocolObject:(RTBProtocol *)p {
    _protocolObject = p;
    _label.text = [p protocolName];
    _label.font = [UIFont fontWithName:@"HelveticaNeue-LightItalic" size:18];
    self.accessoryType = [p hasChildren] ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
}

- (IBAction)showHeaders:(id)sender {
    // TODO: use a notification here
	id appDelegate = [[UIApplication sharedApplication] delegate];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
	[appDelegate performSelector:@selector(showHeaderForProtocol:) withObject:_protocolObject];
#pragma clang diagnostic pop
}

@end
