//
//  SearchViewController.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 18.01.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "SearchVC.h"
#import "ClassStub.h"
#import "ClassCell.h"
#import "AllClasses.h"

@implementation SearchVC

@synthesize tableView;
@synthesize theSearchBar;
@synthesize foundClasses;
@synthesize allClasses;

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
	self.allClasses = [AllClasses sharedInstance];
	self.foundClasses = [NSMutableArray array];

	//searchBar.keyboardType = UIKeyboardTypeASCIICapable;
	theSearchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	theSearchBar.autocorrectionType = UITextAutocorrectionTypeNo;
	theSearchBar.showsCancelButton = YES;

    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	self.foundClasses = [NSMutableArray array];
}

- (void)dealloc {
	[allClasses release];
	[foundClasses release];
	[theSearchBar release];
	[tableView release];
    [super dealloc];
}

#pragma mark TableViewDataSouce protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [foundClasses count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	static NSString *ClassCellIdentifier = @"ClassCell";
	
	ClassCell *cell = (ClassCell *)[aTableView dequeueReusableCellWithIdentifier:ClassCellIdentifier];
	if(cell == nil) {
		cell = (ClassCell *)[[[NSBundle mainBundle] loadNibNamed:@"ClassCell" owner:self options:nil] lastObject];
	}
	
	// Set up the cell
	ClassStub *cs = [foundClasses objectAtIndex:indexPath.row];
	cell.label.text = cs.stubClassname;
	cell.accessoryType = UITableViewCellAccessoryNone;
	
    return cell;
}

#pragma mark UISearchBarDelegate protocol

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	//NSLog(@"textDidChange:%@", searchText);	

	if([searchBar.text length] == 0) {
		[foundClasses removeAllObjects];
		[tableView reloadData];
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
	
	[foundClasses removeAllObjects];
	
	NSRange range;
	for(ClassStub *cs in [allClasses sortedClassStubs]) {
		range = [[cs description] rangeOfString:searchBar.text options:NSCaseInsensitiveSearch];
		if(range.location != NSNotFound) {
			//NSLog(@"-- add %@", cs);
			[foundClasses addObject:cs];
		}
	}
	
	NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"description" ascending:YES];
	[foundClasses sortUsingDescriptors:[NSArray arrayWithObject:sd]];
	[sd release];
	
	[tableView reloadData];
}

@end
