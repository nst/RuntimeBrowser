//
//  ListViewController.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 18.01.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "ListTVC.h"
#import "AllClasses.h"
#import "ClassCell.h"
#import "ClassDisplayVC.h"
#import "ClassStub.h"

@implementation ListTVC

@synthesize classStubsDictionaries;
@synthesize classDisplayVC;
@synthesize classStubs;
@synthesize frameworkName;

- (ClassDisplayVC *)classDisplayVC {
	if(classDisplayVC == nil) {
		self.classDisplayVC = [[[ClassDisplayVC alloc] initWithNibName:@"ClassDisplayVC" bundle:nil] autorelease];
	}
	return classDisplayVC;
}

- (void)showHeaderForClassName:(NSString *)className {
	[self classDisplayVC].className = className;
	[[self navigationController] presentModalViewController:[classDisplayVC navigationController] animated:YES];
}

- (IBAction)dismissModalView:(id)sender {	
	[[self navigationController] dismissModalViewControllerAnimated:YES];
}

- (void)setupIndexedClassStubs {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
						
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			NSString *s = frameworkName ? frameworkName : @"All Classes";
			self.navigationItem.title = [NSString stringWithFormat:@"%@ (%d)", s, [classStubs count]];
		}];
		
		NSMutableArray *ma = [[NSMutableArray alloc] init];
		
		unichar firstLetter = 0;
		unichar currentLetter = 0;
		NSMutableArray *currentLetterClassStubs = [[NSMutableArray alloc] init];
		
		for(ClassStub *cs in classStubs) {
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
				[currentLetterClassStubs release];
				currentLetterClassStubs = [[NSMutableArray alloc] init];
				currentLetter = firstLetter;
			}

			[currentLetterClassStubs addObject:cs];
			
			if(cs == [classStubs lastObject]) {
				NSDictionary *d = [NSDictionary dictionaryWithObject:currentLetterClassStubs
															  forKey:[NSString stringWithFormat:@"%c", currentLetter]];
				[ma addObject:d];
			}
		}
		
		[currentLetterClassStubs release];
		
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			self.classStubsDictionaries = ma;
		}];
		
		[ma release];
				
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			[self.tableView reloadData];
		}];
		
	}];
	
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	[queue addOperation:op];
	[queue release];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.title = @"List";
	self.navigationItem.title = frameworkName ? frameworkName : @"All Classes";
	
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
	if(frameworkName == nil) {
		self.classStubs = [[AllClasses sharedInstance] sortedClassStubs];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	if(frameworkName == nil) {
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
	return [classStubsDictionaries count] ? [classStubsDictionaries count] : 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if(section >= [classStubsDictionaries count]) return 0;
	
	NSDictionary *d = [classStubsDictionaries objectAtIndex:section];
	return [[[d allValues] lastObject] count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *ClassCellIdentifier = @"ClassCell";
	
	ClassCell *cell = (ClassCell *)[tableView dequeueReusableCellWithIdentifier:ClassCellIdentifier];
	if(cell == nil) {
		cell = (ClassCell *)[[[NSBundle mainBundle] loadNibNamed:@"ClassCell" owner:self options:nil] lastObject];
	}
	
	// Set up the cell
	if(frameworkName == nil) {
		if(indexPath.section >= [classStubsDictionaries count]) {
			cell.textLabel.text = @"";
			cell.accessoryType = UITableViewCellAccessoryNone;
			return cell;
		}
	}
	
	NSDictionary *d = [classStubsDictionaries objectAtIndex:indexPath.section];
	NSArray *theClassStubs = [[d allValues] lastObject];
	
	ClassStub *cs = [theClassStubs objectAtIndex:indexPath.row];
	cell.label.text = cs.stubClassname;
	cell.accessoryType = UITableViewCellAccessoryNone;
	
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	// The header for the section is the region name -- get this from the dictionary at the section index
	if(section >= [classStubsDictionaries count]) return @"";
	
	NSDictionary *d = [classStubsDictionaries objectAtIndex:section];
	
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
	
	for(NSDictionary *d in classStubsDictionaries) {
		[a addObject:[[d allKeys] lastObject]];
	}
	
	return [a autorelease];
}

- (void)dealloc {
	[frameworkName release];
	[classStubsDictionaries release];
	//[allClasses release];
	[classDisplayVC release];
	[classStubs release];
	[super dealloc];
}

@end

