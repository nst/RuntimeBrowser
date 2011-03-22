//
//  InfoViewController.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 25.01.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface InfoVC : UIViewController {
//	IBOutlet UILabel *revisionLabel;
	IBOutlet UILabel *webServerStatusLabel;
	IBOutlet UILabel *memoryLabel;
}

//@property (nonatomic, retain) IBOutlet UILabel *revisionLabel;
@property (nonatomic, retain) IBOutlet UILabel *webServerStatusLabel;
@property (nonatomic, retain) IBOutlet UILabel *memoryLabel;

- (IBAction)openWebSiteAction:(id)sender;
- (IBAction)closeAction:(id)sender;

@end
