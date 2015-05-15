//
//  ListViewController.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 18.01.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RTBListTVC : UITableViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableArray *classStubsDictionaries; // [{'A':classStubs}, {'B':classStubs}]
@property (nonatomic, strong) NSArray *classStubs;
@property (nonatomic, strong) NSString *titleForNavigationItem;

@end
