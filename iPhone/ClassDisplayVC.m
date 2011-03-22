//
//  ClassDisplayViewController.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 31.08.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import "ClassDisplayVC.h"
#import "ClassDisplay.h"
#import "AppDelegate.h"
#import "ObjectsTVC.h"

@implementation ClassDisplayVC

@synthesize className;
@synthesize useButton;
@synthesize navigationBar;
@synthesize textView;

- (IBAction)use:(id)sender {
	
	AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate useClass:className];
	
	[self dismissModalViewControllerAnimated:YES];	
}

- (IBAction)dismissModalView:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidLoad {
	textView.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
}

- (void)viewDidUnload {
	self.navigationBar = nil;
	self.textView = nil;
	self.useButton = nil;
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
	textView.text = @"";
	navigationBar.topItem.title = className;
	
	// FIXME: ??
	NSArray *forbiddenClasses = [NSArray arrayWithObjects:@"NSMessageBuilder", /*, @"NSObject", @"NSProxy", */@"Object", @"_NSZombie_", nil];
	
	useButton.enabled = ![forbiddenClasses containsObject:className];
}

- (void)viewDidDisappear:(BOOL)animated {
	textView.text = @"";
}

- (void)viewDidAppear:(BOOL)animated {
	ClassDisplay *cd = [ClassDisplay classDisplayWithClass:NSClassFromString(className)];
    textView.text = [cd header];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

- (void)dealloc {
	[className release];
	[navigationBar release];
	[textView release];
	[useButton release];
	[super dealloc];
}

@end
