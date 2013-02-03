//
//  TreeViewController.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 17.01.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ClassDisplayVC;
@class InfoVC;
@class AllClasses;

@interface TreeTVC : UITableViewController <UITableViewDataSource, UITableViewDelegate> {
	ClassDisplayVC *classDisplayVC;
	BOOL isSubLevel;
	NSArray *classStubs;
	AllClasses *allClasses;
	
	InfoVC *infoVC;
}

@property BOOL isSubLevel;
@property (nonatomic, retain) NSArray *classStubs;
@property (nonatomic, retain) AllClasses *allClasses;
@property (nonatomic, retain) ClassDisplayVC *classDisplayVC;
@property (nonatomic, retain) InfoVC *infoVC;

- (IBAction)showInfo:(id)sender;

@end
