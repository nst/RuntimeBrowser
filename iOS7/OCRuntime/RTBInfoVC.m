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

@implementation RTBInfoVC

- (IBAction)closeAction:(id)sender {
	[self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

- (void)updateWebServerStatus {
	RTBAppDelegate *appDelegate = (RTBAppDelegate *)[[UIApplication sharedApplication] delegate];
	NSString *serverURL = [NSString stringWithFormat:@"http://%@:%d/", [appDelegate myIPAddress], [appDelegate serverPort]];
	_webServerStatusLabel.text = [[appDelegate httpServer] isRunning] ? serverURL : @"";
}

- (void)viewWillAppear:(BOOL)animated {
    [_showPreludeInHeadersSwitch setOn:[[[NSUserDefaults standardUserDefaults] valueForKey:@"ShowPreludeInHeaders"] boolValue]];
    [_showOCRuntimeClassesSwitch setOn:[[[NSUserDefaults standardUserDefaults] valueForKey:@"ShowOCRuntimeClasses"] boolValue]];
    [_toggleWebServerSwitch setOn:[[[NSUserDefaults standardUserDefaults] valueForKey:@"EnableWebServer"] boolValue]];

    [self updateWebServerStatus];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
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
