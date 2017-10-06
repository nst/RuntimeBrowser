//
//  FrameworksTableViewController.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 01.09.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RTBRuntime;

@interface RTBFrameworksTVC : UITableViewController <UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating>

@property (strong, nonatomic) NSArray *publicFrameworks;
@property (strong, nonatomic) NSArray *privateFrameworks;
@property (strong, nonatomic) NSArray *bundleFrameworks;
@property (strong, nonatomic) RTBRuntime *allClasses;

@property (strong, nonatomic) NSArray *filteredPublicFrameworks;
@property (strong, nonatomic) NSArray *filteredPrivateFrameworks;

@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) UISearchController *searchController;

- (IBAction)loadAllFrameworks:(id)sender;

@end
