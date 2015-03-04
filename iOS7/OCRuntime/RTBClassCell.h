//
//  ClassCell.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 13.08.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ClassStub;

@interface RTBClassCell : UITableViewCell

@property (nonatomic, retain) ClassStub *classStub;

- (IBAction)showHeaders:(id)sender;

@end
