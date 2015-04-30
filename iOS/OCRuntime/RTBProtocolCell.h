//
//  ClassCell.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 13.08.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RTBProtocolCell : UITableViewCell

@property (nonatomic, retain) NSString *protocolName;

- (IBAction)showHeaders:(id)sender;

@end
