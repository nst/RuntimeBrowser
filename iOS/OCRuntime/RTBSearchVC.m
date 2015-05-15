//
//  SearchViewController.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 18.01.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "RTBSearchVC.h"
#import "RTBClass.h"
#import "RTBClassCell.h"
#import "RTBRuntime.h"

@implementation RTBSearchVC

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	self.title = @"Search";
	self.allClasses = [RTBRuntime sharedInstance];
	self.foundClasses = [NSMutableArray array];

	//searchBar.keyboardType = UIKeyboardTypeASCIICapable;
	_theSearchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	_theSearchBar.autocorrectionType = UITextAutocorrectionTypeNo;
//	_theSearchBar.showsCancelButton = YES;

    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [_theSearchBar becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	self.foundClasses = [NSMutableArray array];
}

#pragma mark TableViewDataSouce protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_foundClasses count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    RTBClassCell *cell = (RTBClassCell *)[_tableView dequeueReusableCellWithIdentifier:@"RTBClassCell"];
    
	// Set up the cell
	RTBClass *cs = [_foundClasses objectAtIndex:indexPath.row];
	cell.className = cs.classObjectName;
	cell.accessoryType = UITableViewCellAccessoryNone;
	
    return cell;
}

#pragma mark UISearchBarDelegate protocol

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	//NSLog(@"textDidChange:%@", searchText);	

	if([searchBar.text length] == 0) {
		[_foundClasses removeAllObjects];
		[_tableView reloadData];
	}
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
	return YES;
}

//- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
//	NSLog(@"searchBarTextDidBeginEditing:");
//}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
	//NSLog(@"searchBarShouldEndEditing:");
	return YES;
}

//- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
//	NSLog(@"searchBarTextDidEndEditing:");
//}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	[searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	[searchBar resignFirstResponder];
	
	[_foundClasses removeAllObjects];
	
	NSRange range;
	for(RTBClass *cs in [_allClasses sortedClassStubs]) {
		range = [[cs description] rangeOfString:searchBar.text options:NSCaseInsensitiveSearch];
		if(range.location != NSNotFound) {
			//NSLog(@"-- add %@", cs);
			[_foundClasses addObject:cs];
		}
	}
	
	NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"description" ascending:YES];
	[_foundClasses sortUsingDescriptors:[NSArray arrayWithObject:sd]];
	
	[_tableView reloadData];
}

@end
