//
//  TreeViewController.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 17.01.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "TreeTVC.h"
#import "AllClasses.h"
#import "ClassCell.h"
#import "ClassStub.h"
#import "ClassDisplayVC.h"
#import "InfoVC.h"

@implementation TreeTVC

@synthesize classStubs;
@synthesize isSubLevel;
@synthesize infoVC;
@synthesize allClasses;
@synthesize classDisplayVC;

- (ClassDisplayVC *)classDisplayVC {
	if(classDisplayVC == nil) {
		self.classDisplayVC = [[[ClassDisplayVC alloc] initWithNibName:@"ClassDisplayVC" bundle:nil] autorelease];
	}
	return classDisplayVC;
}

- (InfoVC *)infoVC {
	if(infoVC == nil) {
		self.infoVC = [[[InfoVC alloc] initWithNibName:@"InfoVC" bundle:nil] autorelease];
	}
	return infoVC;
}

- (IBAction)showInfo:(id)sender {
	[self presentModalViewController:[self infoVC] animated:YES];
}

- (void)showHeaderForClassName:(NSString *)className {
	[self classDisplayVC].className = className;
	[[self navigationController] presentModalViewController:[classDisplayVC navigationController] animated:YES];
}

- (IBAction)dismissModalView:(id)sender {	
	[[self navigationController] dismissModalViewControllerAnimated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.allClasses = [AllClasses sharedInstance];
	if(!isSubLevel) {
		self.classStubs = [allClasses rootClasses];
		self.title = @"Tree";
		self.navigationItem.title = @"Root Classes";
	}
}

- (void)viewDidUnload {
	self.classDisplayVC = nil;
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
	if(!isSubLevel) {
		self.classStubs = [allClasses rootClasses]; // classes might have changed because of dynamic loading
	}
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [classStubs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *ClassCellIdentifier = @"ClassCell";
	
	ClassCell *cell = (ClassCell *)[tableView dequeueReusableCellWithIdentifier:ClassCellIdentifier];
	if(cell == nil) {
		cell = (ClassCell *)[[[NSBundle mainBundle] loadNibNamed:@"ClassCell" owner:self options:nil] lastObject];
	}
	
	// Set up the cell
	ClassStub *cs = [classStubs objectAtIndex:indexPath.row];
	cell.label.text = cs.stubClassname;
	cell.accessoryType = [[cs subclassesStubs] count] > 0 ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	ClassStub *cs = [classStubs objectAtIndex:indexPath.row];
	
	if([[cs subclassesStubs] count] == 0) return;
	
	TreeTVC *tvc = [[TreeTVC alloc] initWithNibName:@"TreeTVC" bundle:nil];
	tvc.isSubLevel = YES;
	tvc.classStubs = [cs subclassesStubs];
	tvc.title = cs.stubClassname;
	[self.navigationController pushViewController:tvc animated:YES];
	[tvc release];
}

- (void)dealloc {
	[allClasses release];
	[classDisplayVC release];
	[infoVC release];
	[classStubs release];
    [super dealloc];
}

@end

