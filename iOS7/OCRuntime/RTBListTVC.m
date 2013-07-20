//
//  ListViewController.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 18.01.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "RTBListTVC.h"
#import "AllClasses.h"
#import "RTBClassCell.h"
#import "RTBClassDisplayVC.h"
#import "ClassStub.h"

@implementation RTBListTVC

- (IBAction)dismissModalView:(id)sender {	
	[[self navigationController] dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

- (void)setupIndexedClassStubs {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
						
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			NSString *s = _frameworkName ? _frameworkName : @"All Classes";
			self.navigationItem.title = [NSString stringWithFormat:@"%@ (%d)", s, [_classStubs count]];
		}];
		
		NSMutableArray *ma = [[NSMutableArray alloc] init];
		
		unichar firstLetter = 0;
		unichar currentLetter = 0;
		NSMutableArray *currentLetterClassStubs = [[NSMutableArray alloc] init];
		
		for(ClassStub *cs in _classStubs) {
			if([cs.stubClassname length] < 1) continue;
				
			firstLetter = [cs.stubClassname characterAtIndex:0];
			
			if(currentLetter == 0) {
				currentLetter = firstLetter;
			}
			
			BOOL letterChange = firstLetter != currentLetter;
			
			if(letterChange) {
				NSDictionary *d = [NSDictionary dictionaryWithObject:currentLetterClassStubs
															  forKey:[NSString stringWithFormat:@"%c", currentLetter]];
				[ma addObject:d];
				currentLetterClassStubs = [[NSMutableArray alloc] init];
				currentLetter = firstLetter;
			}

			[currentLetterClassStubs addObject:cs];
			
			if(cs == [_classStubs lastObject]) {
				NSDictionary *d = [NSDictionary dictionaryWithObject:currentLetterClassStubs
															  forKey:[NSString stringWithFormat:@"%c", currentLetter]];
				[ma addObject:d];
			}
		}
		
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			self.classStubsDictionaries = ma;
		}];
						
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			[self.tableView reloadData];
		}];
		
	}];
	
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	[queue addOperation:op];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
//	self.title = @"List";
	self.navigationItem.title = _frameworkName ? _frameworkName : @"All Classes";
	
	//[self setupIndexedClassStubs];

	[super viewDidLoad];
}

- (void)viewDidUnload {
	self.classDisplayVC = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
		
	// show all if not showing a framework
	if(_frameworkName == nil) {
		self.classStubs = [[AllClasses sharedInstance] sortedClassStubs];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	if(_frameworkName == nil) {
		self.navigationItem.title = @"All Classes";
	}

	[self setupIndexedClassStubs];

	[super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [_classStubsDictionaries count] ? [_classStubsDictionaries count] : 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if(section >= [_classStubsDictionaries count]) return 0;
	
	NSDictionary *d = [_classStubsDictionaries objectAtIndex:section];
	return [[[d allValues] lastObject] count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    RTBClassCell *cell = (RTBClassCell *)[tableView dequeueReusableCellWithIdentifier:@"RTBClassCell"];
	
	// Set up the cell
	if(_frameworkName == nil) {
		if(indexPath.section >= [_classStubsDictionaries count]) {
			cell.textLabel.text = @"";
			cell.accessoryType = UITableViewCellAccessoryNone;
			return cell;
		}
	}
	
	NSDictionary *d = [_classStubsDictionaries objectAtIndex:indexPath.section];
	NSArray *theClassStubs = [[d allValues] lastObject];
	
	ClassStub *cs = [theClassStubs objectAtIndex:indexPath.row];
    cell.className = cs.stubClassname;
	cell.accessoryType = UITableViewCellAccessoryNone;
	
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	// The header for the section is the region name -- get this from the dictionary at the section index
	if(section >= [_classStubsDictionaries count]) return @"";
	
	NSDictionary *d = [_classStubsDictionaries objectAtIndex:section];
	
	NSString *letter = [[d allKeys] lastObject];
	NSUInteger i = [[[d allValues] lastObject] count];
	return [NSString stringWithFormat:@"%@ (%d)", letter, i];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	/*
	 Return the index titles for each of the sections (e.g. "A", "B", "C"...).
	 Use key-value coding to get the value for the key @"letter" in each of the dictionaries in list.
	 */
	NSMutableArray *a = [[NSMutableArray alloc] init];
	
	for(NSDictionary *d in _classStubsDictionaries) {
		[a addObject:[[d allKeys] lastObject]];
	}
	
	return a;
}

@end

