//
//  FrameworkCell.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 01.09.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FrameworkCell : UITableViewCell {
	IBOutlet UILabel *label;
	IBOutlet UIButton *button;
}

@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIButton *button;

@end
