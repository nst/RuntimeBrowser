//
//  FrameworksTableViewController.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 01.09.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AllClasses;

@interface RTBFrameworksTVC : UITableViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSArray *publicFrameworks;
@property (strong, nonatomic) NSArray *privateFrameworks;
@property (strong, nonatomic) NSArray *bundleFrameworks;
@property (strong, nonatomic) AllClasses *allClasses;

@property (strong, nonatomic) UIAlertView *alertView;
@property (strong, nonatomic) UIProgressView *progressView;

- (IBAction)loadAllFrameworks:(id)sender;

@end
