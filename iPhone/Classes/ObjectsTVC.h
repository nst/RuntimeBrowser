//
//  ObjectWithMethodsViewController.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 11.06.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ObjectsTVC : UITableViewController {
	id object;
	NSMutableArray *methods;
}

@property (nonatomic, retain) id object;
@property (nonatomic, retain) NSMutableArray *methods;

@end
