//
//  InfoViewController.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 25.01.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "RTBInfoVC.h"
#import "RTBAppDelegate.h"
#import "GCDWebServer.h"

@interface RTBInfoVC ()

@property (nonatomic, retain) IBOutlet UILabel *webServerStatusLabel;

@property (nonatomic, retain) IBOutlet UISwitch *showOCRuntimeClassesSwitch;
@property (nonatomic, retain) IBOutlet UISwitch *addCommentForBlocksSwitch;
@property (nonatomic, retain) IBOutlet UISwitch *toggleWebServerSwitch;

@end

@implementation RTBInfoVC

//- (void)dismissModalView:(id)sender {
//	[self dismissViewControllerAnimated:YES completion:nil];
//}

- (void)updateWebServerStatus {
	RTBAppDelegate *appDelegate = (RTBAppDelegate *)[[UIApplication sharedApplication] delegate];
	NSString *serverURL = [NSString stringWithFormat:@"http://%@:%d/", [appDelegate myIPAddress], [appDelegate serverPort]];
	_webServerStatusLabel.text = [[appDelegate webServer] isRunning] ? serverURL : @"";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [_showOCRuntimeClassesSwitch setOn:[[[NSUserDefaults standardUserDefaults] valueForKey:@"RTBShowOCRuntimeClasses"] boolValue]];
    [_addCommentForBlocksSwitch setOn:[[[NSUserDefaults standardUserDefaults] valueForKey:@"RTBAddCommentsForBlocks"] boolValue]];
    [_toggleWebServerSwitch setOn:[[[NSUserDefaults standardUserDefaults] valueForKey:@"RTBEnableWebServer"] boolValue]];

    [self updateWebServerStatus];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"About", nil);
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissModalView:)];
}

- (IBAction)openWebSiteAction:(id)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/nst/RuntimeBrowser/"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	
	self.webServerStatusLabel = nil;
}

- (IBAction)showOCRuntimeClassesAction:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:((UISwitch *)sender).isOn forKey:@"RTBShowOCRuntimeClasses"];
}

- (IBAction)addBlockCommentsAction:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:((UISwitch *)sender).isOn forKey:@"RTBAddCommentsForBlocks"];
}

- (IBAction)toggleWebServerAction:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:((UISwitch *)sender).isOn forKey:@"RTBEnableWebServer"];

    RTBAppDelegate *appDelegate = (RTBAppDelegate *)[[UIApplication sharedApplication] delegate];

    if(((UISwitch *)sender).isOn) {
        [appDelegate startWebServer];
    } else {
        [appDelegate stopWebServer];
    }
    
    [self updateWebServerStatus];
}

@end
