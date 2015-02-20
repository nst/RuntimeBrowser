//
//  ClassDisplayViewController.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 31.08.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ClassStub;

@interface RTBClassDisplayVC : UIViewController

//@property (nonatomic, copy) NSString *className;
@property (nonatomic, retain) ClassStub *classStub;

@end
