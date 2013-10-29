//
//  ClassCell.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 13.08.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RTBClassCell : UITableViewCell

@property (nonatomic, retain) NSString *className;

- (IBAction)showHeaders:(id)sender;

@end
