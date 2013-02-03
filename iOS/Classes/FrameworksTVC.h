//
//  FrameworksTableViewController.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 01.09.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AllClasses;

@interface FrameworksTVC : UITableViewController <UITableViewDataSource, UITableViewDelegate> {
	NSArray *publicFrameworks;
	NSArray *privateFrameworks;
	NSArray *bundleFrameworks;
	
	AllClasses *allClasses;
	
	UIAlertView *alertView;
	UIProgressView *progressView;
}

@property (nonatomic, retain) NSArray *publicFrameworks;
@property (nonatomic, retain) NSArray *privateFrameworks;
@property (nonatomic, retain) NSArray *bundleFrameworks;
@property (nonatomic, retain) AllClasses *allClasses;

- (IBAction)loadAllFrameworks:(id)sender;

@end
