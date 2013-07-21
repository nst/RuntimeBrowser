//
//  ClassDisplayViewController.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 31.08.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import "RTBClassDisplayVC.h"
#import "ClassDisplay.h"
#import "RTBAppDelegate.h"
#import "RTBObjectsTVC.h"
#import "NSString+SyntaxColoring.h"

@implementation RTBClassDisplayVC

- (IBAction)use:(id)sender {
	
	RTBAppDelegate *appDelegate = (RTBAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate useClass:_className];
	
	[self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

- (IBAction)dismissModalView:(id)sender {
	[self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

- (void)viewDidLoad {
	_textView.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
}

- (void)viewDidUnload {
	self.navigationBar = nil;
	self.textView = nil;
	self.useButton = nil;
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
	_textView.text = @"";
	_navigationBar.topItem.title = _className;
	
	// FIXME: ??
	NSArray *forbiddenClasses = [NSArray arrayWithObjects:@"NSMessageBuilder", /*, @"NSObject", @"NSProxy", */@"Object", @"_NSZombie_", nil];
	
	_useButton.enabled = ![forbiddenClasses containsObject:_className];
}

- (void)viewDidDisappear:(BOOL)animated {
	_textView.text = @"";
}

- (void)viewDidAppear:(BOOL)animated {
	ClassDisplay *cd = [ClassDisplay classDisplayWithClass:NSClassFromString(_className)];
    _textView.text = [cd header];
    
    NSString *keywordsPath = [[NSBundle mainBundle] pathForResource:@"Keywords" ofType:@"plist"];
	
	NSArray *keywords = [NSArray arrayWithContentsOfFile:keywordsPath];
    
    NSAttributedString *as = [[cd header] colorizeWithKeywords:keywords classes:nil];
    
    _textView.attributedText = as;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

@end
