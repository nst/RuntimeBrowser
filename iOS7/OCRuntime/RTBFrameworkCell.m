//
//  FrameworkCell.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 01.09.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import "RTBFrameworkCell.h"

@interface RTBFrameworkCell ()
@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIImageView *frameworkImageView;
@end

@implementation RTBFrameworkCell

- (void)setFrameworkName:(NSString *)frameworkName {
    self.label.text = frameworkName;
}

- (NSString *)frameworkName {
    return self.label.text;
}

/*
- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
	if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
		// Initialization code
	}
	return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

	[super setSelected:selected animated:animated];

	// Configure the view for the selected state
}


- (void)dealloc {
	[super dealloc];
}
*/

@end
