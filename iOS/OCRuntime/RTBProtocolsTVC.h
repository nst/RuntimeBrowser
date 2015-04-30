//
//  RTBProtocolsTVC.h
//  OCRuntime
//
//  Created by Nicolas Seriot on 27/04/15.
//  Copyright (c) 2015 Nicolas Seriot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RTBProtocolsTVC : UITableViewController

@property (nonatomic, retain) NSArray *protocolStubs;
@property (nonatomic, retain) NSMutableArray *protocolStubsDictionaries; // [{'A':classStubs}, {'B':classStubs}]

@end
