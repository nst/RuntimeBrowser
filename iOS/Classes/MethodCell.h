//
//  MethodCell.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 13.08.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MethodCell : UITableViewCell {
	IBOutlet UILabel *label;
}

@property (nonatomic, retain) IBOutlet UILabel *label;

@end
