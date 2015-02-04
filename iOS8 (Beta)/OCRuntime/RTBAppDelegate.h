//
//  AppDelegate.h
//  OCRuntime
//
//  Created by Nicolas Seriot on 6/14/13.
//  Copyright (c) 2013 Nicolas Seriot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTTPResponse.h"

@class RTBObjectsTVC;
@class HTTPServer;
@class AllClasses;

@interface RTBAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) AllClasses *allClasses;
@property (strong, nonatomic) RTBObjectsTVC *objectsTVC;
@property (strong, nonatomic) HTTPServer *httpServer;

- (NSObject<HTTPResponse> *)responseForPath:(NSString *)path;
- (NSString *)myIPAddress;
- (UInt16)serverPort;

- (void)stopWebServer;
- (void)startWebServer;

- (void)useClass:(NSString *)className;

@end
