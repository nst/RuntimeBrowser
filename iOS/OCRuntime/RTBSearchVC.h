//
//  SearchViewController.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 18.01.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RTBRuntime;

@interface RTBSearchVC : UIViewController <UITableViewDataSource, UISearchBarDelegate>

@property (nonatomic, retain) NSMutableArray *foundClasses;
@property (nonatomic, retain) RTBRuntime *allClasses;

@property (nonatomic, retain) IBOutlet UISearchBar *theSearchBar;
@property (nonatomic, retain) IBOutlet UITableView *tableView;

@end
