//
//  ListViewController.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 18.01.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RTBClassDisplayVC;

@interface RTBListTVC : UITableViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) RTBClassDisplayVC *classDisplayVC;
@property (nonatomic, retain) NSMutableArray *classStubsDictionaries; // [{'A':classStubs}, {'B':classStubs}]
@property (nonatomic, retain) NSArray *classStubs;
@property (nonatomic, retain) NSString *frameworkName; // nil to display all classes

@end
