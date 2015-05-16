//
//  ClassDisplayViewController.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 31.08.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import "RTBClassDisplayVC.h"
#import "RTBAppDelegate.h"
#import "RTBObjectsTVC.h"
#import "NSString+SyntaxColoring.h"
#import "RTBRuntimeHeader.h"

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
    
    self.useButton = _className ? [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Use", nil) style:UIBarButtonItemStylePlain target:self action:@selector(use:)] : nil;
    self.navigationItem.leftBarButtonItem = self.useButton;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissModalView:)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
	self.textView.text = @"";
    self.title = _className ? _className : _protocolName;
	
//	// FIXME: ??
//	NSArray *forbiddenClasses = [NSArray arrayWithObjects:@"NSMessageBuilder", /*, @"NSObject", @"NSProxy", */@"Object", @"_NSZombie_", nil];
//	
//	self.useButton.enabled = ![forbiddenClasses containsObject:self.className];
    self.useButton.enabled = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
	self.textView.text = @"";
    
    [super viewDidDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSString *header = nil;
    
    if(_className) {
        BOOL displayPropertiesDefaultValues = [[NSUserDefaults standardUserDefaults] boolForKey:@"RTBDisplayPropertiesDefaultValues"];
        header = [RTBRuntimeHeader headerForClass:NSClassFromString(self.className) displayPropertiesDefaultValues:displayPropertiesDefaultValues];
    } else if (_protocolName) {
        RTBProtocol *p = [RTBProtocol protocolStubWithProtocolName:_protocolName];
        header = [RTBRuntimeHeader headerForProtocol:p];
    }
    
    NSString *keywordsPath = [[NSBundle mainBundle] pathForResource:@"Keywords" ofType:@"plist"];
	
	NSArray *keywords = [NSArray arrayWithContentsOfFile:keywordsPath];
    
    NSAttributedString *as = [header colorizeWithKeywords:keywords classes:nil colorize:YES];
    
    self.textView.attributedText = as;
}

@end
