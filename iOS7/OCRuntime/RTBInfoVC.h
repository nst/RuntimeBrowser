//
//  InfoViewController.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 25.01.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RTBInfoVC : UIViewController

@property (nonatomic, retain) IBOutlet UILabel *webServerStatusLabel;

- (IBAction)openWebSiteAction:(id)sender;
- (IBAction)closeAction:(id)sender;

- (IBAction)showPreludeInHeadersAction:(id)sender;
- (IBAction)showOCRuntimeClassesAction:(id)sender;
- (IBAction)toggleWebServerAction:(id)sender;

@end
