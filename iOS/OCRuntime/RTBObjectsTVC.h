//
//  ObjectWithMethodsViewController.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 11.06.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RTBObjectsTVC : UITableViewController

- (void)setInspectedObject:(id)o;

- (IBAction)close:(id)sender;

@end
