//
//  RTBTreeTVC.h
//  OCRuntime
//
//  Created by Nicolas Seriot on 7/17/13.
//  Copyright (c) 2013 Nicolas Seriot. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RTBClassDisplayVC;
@class RTBInfoVC;
@class AllClasses;

@interface RTBTreeTVC : UITableViewController <UITableViewDataSource, UITableViewDelegate>

@property BOOL isSubLevel;
@property (nonatomic, retain) NSArray *classStubs;
@property (nonatomic, retain) AllClasses *allClasses;
@property (nonatomic, retain) RTBClassDisplayVC *classDisplayVC;
@property (nonatomic, retain) RTBInfoVC *infoVC;

- (IBAction)showInfo:(id)sender;

@end
