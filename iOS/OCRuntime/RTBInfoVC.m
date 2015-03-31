//
//  InfoViewController.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 25.01.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "RTBInfoVC.h"
#import "RTBAppDelegate.h"
#import "HTTPServer.h"

@interface RTBInfoVC ()

@property (nonatomic, retain) IBOutlet UILabel *webServerStatusLabel;

@property (nonatomic, retain) IBOutlet UISwitch *showPreludeInHeadersSwitch;
@property (nonatomic, retain) IBOutlet UISwitch *showOCRuntimeClassesSwitch;
@property (nonatomic, retain) IBOutlet UISwitch *toggleWebServerSwitch;

@end

@implementation RTBInfoVC

- (void)dismissModalView:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateWebServerStatus {
	RTBAppDelegate *appDelegate = (RTBAppDelegate *)[[UIApplication sharedApplication] delegate];
	NSString *serverURL = [NSString stringWithFormat:@"http://%@:%d/", [appDelegate myIPAddress], [appDelegate serverPort]];
	_webServerStatusLabel.text = [[appDelegate httpServer] isRunning] ? serverURL : @"";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [_showPreludeInHeadersSwitch setOn:[[[NSUserDefaults standardUserDefaults] valueForKey:@"ShowPreludeInHeaders"] boolValue]];
    [_showOCRuntimeClassesSwitch setOn:[[[NSUserDefaults standardUserDefaults] valueForKey:@"ShowOCRuntimeClasses"] boolValue]];
    [_toggleWebServerSwitch setOn:[[[NSUserDefaults standardUserDefaults] valueForKey:@"EnableWebServer"] boolValue]];

    [self updateWebServerStatus];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"About", nil);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissModalView:)];
}

- (IBAction)openWebSiteAction:(id)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/nst/RuntimeBrowser/"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	
	self.webServerStatusLabel = nil;
}

- (IBAction)showPreludeInHeadersAction:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:((UISwitch *)sender).isOn forKey:@"ShowPreludeInHeaders"];
}

- (IBAction)showOCRuntimeClassesAction:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:((UISwitch *)sender).isOn forKey:@"ShowOCRuntimeClasses"];
}

- (IBAction)toggleWebServerAction:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:((UISwitch *)sender).isOn forKey:@"EnableWebServer"];

    RTBAppDelegate *appDelegate = (RTBAppDelegate *)[[UIApplication sharedApplication] delegate];

    if(((UISwitch *)sender).isOn) {
        [appDelegate startWebServer];
    } else {
        [appDelegate stopWebServer];
    }
    
    [self updateWebServerStatus];
}

@end
