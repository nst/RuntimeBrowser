//
//  ClassCell.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 13.08.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ClassCell : UITableViewCell {
	IBOutlet UILabel *label;
	IBOutlet UIButton *button;
}

@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIButton *button;

- (IBAction)showHeaders:(id)sender;

@end
