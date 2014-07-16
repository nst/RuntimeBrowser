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

@interface RTBClassDisplayVC ()

@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) UIBarButtonItem *useButton;

@end

@implementation RTBClassDisplayVC

- (void)use:(id)sender {

	[self dismissViewControllerAnimated:YES completion:^{
        
        RTBAppDelegate *appDelegate = (RTBAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate useClass:self.className];
    }];
}

- (void)dismissModalView:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
	self.textView.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    
    self.useButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Use", nil) style:UIBarButtonItemStylePlain target:self action:@selector(use:)];
    self.navigationItem.leftBarButtonItem = self.useButton;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissModalView:)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
	self.textView.text = @"";
	self.title = _className;
	
	// FIXME: ??
	NSArray *forbiddenClasses = [NSArray arrayWithObjects:@"NSMessageBuilder", /*, @"NSObject", @"NSProxy", */@"Object", @"_NSZombie_", nil];
	
	self.useButton.enabled = ![forbiddenClasses containsObject:self.className];
}

- (void)viewDidDisappear:(BOOL)animated {
	self.textView.text = @"";
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
	ClassDisplay *cd = [ClassDisplay classDisplayWithClass:NSClassFromString(self.className)];
    self.textView.text = [cd header];
    
    NSString *keywordsPath = [[NSBundle mainBundle] pathForResource:@"Keywords" ofType:@"plist"];
	
	NSArray *keywords = [NSArray arrayWithContentsOfFile:keywordsPath];
    
    NSAttributedString *as = [[cd header] colorizeWithKeywords:keywords classes:nil];
    
    self.textView.attributedText = as;
}

@end
