//
//  InfoViewController.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 25.01.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "RTBInfoVC.h"
#import "RTBAppDelegate.h"

#import <mach/mach.h>
#import <mach/mach_host.h>

@implementation RTBInfoVC

- (IBAction)closeAction:(id)sender {
	[self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

- (void)viewDidAppear:(BOOL)animated {
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	
	RTBAppDelegate *appDelegate = (RTBAppDelegate *)[[UIApplication sharedApplication] delegate];
	NSString *serverURL = [NSString stringWithFormat:@"http://%@:%d/", [appDelegate myIPAddress], [appDelegate serverPort]];
	_webServerStatusLabel.text = [appDelegate httpServer] != nil ? serverURL : @"stopped";
	
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
    
}

- (IBAction)showOCRuntimeClassesAction:(id)sender {

}

- (IBAction)toggleWebServerAction:(id)sender {
    RTBAppDelegate *appDelegate = (RTBAppDelegate *)[[UIApplication sharedApplication] delegate];

    if(((UISwitch *)sender).isOn) {
        [appDelegate startWebServer];
    } else {
        [appDelegate stopWebServer];
    }
}

@end
