//
//  ListViewController.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 18.01.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ClassDisplayVC;

@interface ListTVC : UITableViewController <UITableViewDataSource, UITableViewDelegate> {
	ClassDisplayVC *classDisplayVC;
	
	NSMutableArray *classStubsDictionaries; // [{'A':classStubs}, {'B':classStubs}]

	NSArray *classStubs;
	NSString *frameworkName; // nil to display all classes
}

@property (nonatomic, retain) ClassDisplayVC *classDisplayVC;
@property (nonatomic, retain) NSMutableArray *classStubsDictionaries;
@property (nonatomic, retain) NSArray *classStubs;
@property (nonatomic, retain) NSString *frameworkName;

@end
