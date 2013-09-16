//
//  RuntimeBrowserAppDelegate.h
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 17.01.09.
//  Copyright Sen:te 2009. All rights reserved.
//

#warning TODO: upgrade graphics to retina display

#import <UIKit/UIKit.h>
#import "HTTPResponse.h"

@class ClassDisplayVC;
@class ObjectsTVC;
@class HTTPServer;
@class AllClasses;

@interface AppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> {
    IBOutlet UIWindow *window;
    IBOutlet UITabBarController *tabBarController;
	IBOutlet ObjectsTVC *objectsTVC;
	
	ClassDisplayVC *classDisplayVC;

	HTTPServer *httpServer;
	AllClasses *allClasses;
}

@property (nonatomic, retain) AllClasses *allClasses;

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UITabBarController *tabBarController;

@property (nonatomic, retain) ClassDisplayVC *classDisplayVC;
@property (nonatomic, retain) ObjectsTVC *objectsTVC;

- (NSObject<HTTPResponse> *)responseForPath:(NSString *)path;
- (NSString *)myIPAddress;
- (UInt16)serverPort;

- (void)useClass:(NSString *)className;
- (HTTPServer *)httpServer;

@end
