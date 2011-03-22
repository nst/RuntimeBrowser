//
//  ClassDisplayViewController.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 31.08.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ClassDisplayVC : UIViewController {
	NSString *className;
	
	IBOutlet UINavigationBar *navigationBar;
	IBOutlet UITextView *textView;
	IBOutlet UIBarButtonItem *useButton;
}

@property (nonatomic, retain) NSString *className;

@property (nonatomic, retain) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *useButton;

- (IBAction)dismissModalView:(id)sender;
- (IBAction)use:(id)sender;

@end
