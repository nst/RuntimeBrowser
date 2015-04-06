//
//  AppDelegate.m
//  OCRuntime
//
//  Created by Nicolas Seriot on 6/14/13.
//  Copyright (c) 2013 Nicolas Seriot. All rights reserved.
//

#import "RTBAppDelegate.h"

#include <sys/types.h>
#include <sys/sysctl.h>

#import "RTBClassDisplayVC.h"
#import "ClassDisplay.h"
#import "ClassStub.h"
#import "HTTPServer.h"
#import "HTTPDataResponse.h"
#import "RTBMyIP.h"
#import "AllClasses.h"
#import "RTBObjectsTVC.h"

#if (! TARGET_OS_IPHONE)
#import <objc/objc-runtime.h>
#else
#import <objc/runtime.h>
#import <objc/message.h>
#endif


@implementation RTBAppDelegate

//- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
//{
//    // Override point for customization after application launch.
//    return YES;
//}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

//- (void)applicationWillTerminate:(UIApplication *)application
//{
//    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//}


//- (RTBClassDisplayVC *)classDisplayVC {
//	if(_classDisplayVC == nil) {
//		self.classDisplayVC = [[RTBClassDisplayVC alloc] initWithNibName:@"RTBClassDisplayVC" bundle:nil];
//	}
//	return _classDisplayVC;
//}

- (void)useClass:(NSString *)className {
    
    UITabBarController *tabBarController = (UITabBarController *)_window.rootViewController;
    
    tabBarController.selectedIndex = 4;
    
    UINavigationController *nc = (UINavigationController *)[tabBarController.viewControllers objectAtIndex:4];
    [nc popToRootViewControllerAnimated:NO];
    
    RTBObjectsTVC *objectsTVC = (RTBObjectsTVC *)nc.topViewController;
    
    Class klass = NSClassFromString(className);
    objectsTVC.object = klass;
}

- (NSString *)myIPAddress {
    NSString *myIP = [[[RTBMyIP sharedInstance] ipsForInterfaces] objectForKey:@"en0"];
    
#if TARGET_IPHONE_SIMULATOR
    if(!myIP) {
        myIP = [[[RTBMyIP sharedInstance] ipsForInterfaces] objectForKey:@"en1"];
    }
#endif
    
    return myIP;
}

- (NSObject<HTTPResponse> *)responseForList {
    NSMutableString *ms = [NSMutableString string];
    
    NSArray *classes = [_allClasses sortedClassStubs];
    [ms appendFormat:@"%@ classes loaded\n\n", @([classes count])];
    for(ClassStub *cs in classes) {
        //if([cs.stubClassname compare:@"S"] == NSOrderedAscending) continue;
        [ms appendFormat:@"<A HREF=\"/list/%@.h\">%@.h</A>\n", cs.stubClassname, cs.stubClassname];
    }
    
    
    NSString *html = [self htmlPageWithContents:ms title:@"iOS Runtime Browser - List View"];
    
    NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
    
    return [[HTTPDataResponse alloc] initWithData:data];
}

+ (NSString *)basePath {
    
    static NSString *basePath = nil;
    
    if(basePath == nil) {
        
        const char* imageNameC = class_getImageName([NSString class]);
        if(imageNameC == NULL) return nil;
        
        NSString *imagePath = [NSString stringWithCString:imageNameC encoding:NSUTF8StringEncoding];
        if(imagePath == nil) return nil;
        
        static NSString *s = @"/System/Library/Frameworks/Foundation.framework/Foundation";
        
        if([s length] > [imagePath length]) return nil;
        NSUInteger i = [imagePath length] - [s length];
        basePath = [imagePath substringToIndex:i];
    }
    
    return basePath;
}

- (NSObject<HTTPResponse> *)responseForHeaderPath:(NSString *)headerPath {
    NSString *fileName = [headerPath lastPathComponent];
    NSString *className = [fileName stringByDeletingPathExtension];
    
    ClassDisplay *cd = [ClassDisplay classDisplayWithClass:NSClassFromString(className)];
    
    NSString *header = [cd header];
    
    NSData *data = [header dataUsingEncoding:NSISOLatin1StringEncoding];
    
    return [[HTTPDataResponse alloc] initWithData:data];
}

- (NSObject<HTTPResponse> *)responseForTreeWithFrameworksName:(NSString *)name directory:(NSString *)dir {
    
    if([[name pathExtension] isEqualToString:@"framework"] == NO) return nil;
    
    NSString *basePath = [[self class] basePath];
    NSString *fullPath = [[basePath stringByAppendingPathComponent:dir] stringByAppendingPathComponent:name];
    NSBundle *b = [NSBundle bundleWithPath:fullPath];
    
    if([b isLoaded] == NO) {
        NSLog(@"-- loading %@", fullPath);
        NSError *error = nil;
        BOOL success = [b loadAndReturnError:&error];
        if(success) {
            [[AllClasses sharedInstance] emptyCachesAndReadAllRuntimeClasses];
        } else {
            NSLog(@"-- %@", [error localizedDescription]);
        }
    }

    NSDictionary *allClassesByImagesPath = [[AllClasses sharedInstance] allClassStubsByImagePath];
    
    NSString *end = [[name lastPathComponent] stringByDeletingPathExtension];
    NSString *imagePath = [[dir stringByAppendingPathComponent:name] stringByAppendingPathComponent:end];

    if([allClassesByImagesPath objectForKey:imagePath] == NO) {
        [[AllClasses sharedInstance] emptyCachesAndReadAllRuntimeClasses];
        allClassesByImagesPath = [[AllClasses sharedInstance] allClassStubsByImagePath];
        NSLog(@"-- %@", [allClassesByImagesPath objectForKey:imagePath]);
    }
    
    NSArray *classes = allClassesByImagesPath[imagePath];
    
    /**/
    
    NSMutableString *ms = [NSMutableString string];
    [ms appendFormat:@"%@\n%@ frameworks\n\n", name, @([classes count])];
    
    NSArray *sortedDylibs = [classes sortedArrayUsingComparator:^NSComparisonResult(NSString *s1, NSString *s2) {
        return [s1 compare:s2];
    }];
    
    for(NSString *s in sortedDylibs) {
        [ms appendFormat:@"<A HREF=\"/tree%@/%@.h\">%@.h</A>\n", name, s, s];
    }
    
    NSString *html = [self htmlPageWithContents:ms title:[name lastPathComponent]];
    
    NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
    
    return [[HTTPDataResponse alloc] initWithData:data];
}

- (NSObject<HTTPResponse> *)responseForTreeWithDylibWithName:(NSString *)name {
    
    if([[name pathExtension] isEqualToString:@"dylib"] == NO) return nil;
    
    NSDictionary *allClassesByImagesPath = [[AllClasses sharedInstance] allClassStubsByImagePath];
    __block NSArray *classes = nil;
    
    [allClassesByImagesPath enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        BOOL isDylib = [[key pathExtension] isEqualToString:@"dylib"];
        if([key containsString:name] || (isDylib && [[key lastPathComponent] isEqualToString:[name lastPathComponent]])) {
            classes = obj;
            *stop = YES;
        }
    }];

    /**/

    NSMutableString *ms = [NSMutableString string];
    [ms appendFormat:@"%@\n%@ dylibs\n\n", name, @([classes count])];
    
    NSArray *sortedDylibs = [classes sortedArrayUsingComparator:^NSComparisonResult(NSString *s1, NSString *s2) {
        return [s1 compare:s2];
    }];
    
    for(NSString *s in sortedDylibs) {
        [ms appendFormat:@"<A HREF=\"/tree%@/%@.h\">%@.h</A>\n", name, s, s];
    }
    
    NSString *html = [self htmlPageWithContents:ms title:[name lastPathComponent]];
    
    NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
    
    return [[HTTPDataResponse alloc] initWithData:data];
}

- (NSObject<HTTPResponse> *)responseForTreeWithPath:(NSString *)path {
    
    NSString *basePath = [[self class] basePath];

    NSObject <HTTPResponse> *response = [self responseForTreeWithFrameworksName:path directory:@"/System/Library/"];
    if(response) return response;
    
    response = [self responseForTreeWithDylibWithName:path];
    if(response) return response;
    
    if([path isEqualToString:@"/"]) {
        
        NSString *s = @"<a href=\"/tree/Frameworks/\">/Frameworks/</a>\n"
        "<a href=\"/tree/PrivateFrameworks/\">/PrivateFrameworks/</a>\n"
        "<a href=\"/tree/lib/\">/lib/</a>\n";
        
        NSString *html = [self htmlPageWithContents:s title:@"iOS Runtime Browser - Tree View"];
        
        NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
        
        return [[HTTPDataResponse alloc] initWithData:data];
    }
    
    NSMutableString *ms = [NSMutableString string];
    
    if([@[@"/Frameworks/", @"/PrivateFrameworks/"] containsObject:path]) {

        NSError *error = nil;
        NSString *fullPath = [NSString stringWithFormat:@"%@/System/Library%@", basePath, path];
        NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPath error:&error];
        if(dirContents == nil) {
            NSLog(@"-- %@", error);
        }
        
        NSMutableArray *files = [NSMutableArray array];
        [dirContents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if([[obj pathExtension] isEqualToString:@"framework"] == NO) return;
            [files addObject:obj];
        }];
        [files sortedArrayUsingSelector:@selector(compare:)];

        [ms appendFormat:@"%@\n%@ frameworks (loaded ones marked with *)\n\n", path, @([files count])];
        
        NSString *basePath = [[self class] basePath];
        
        for(NSString *fileName in files) {
            NSString *bundlePath = [[basePath stringByAppendingPathComponent:@"/System/Library/"]
                                    stringByAppendingPathComponent:[path stringByAppendingPathComponent:fileName]];
            NSLog(@"-- bundlePath: %@", [NSBundle bundleWithPath:bundlePath]);
            NSBundle *b = [NSBundle bundleWithPath:bundlePath];
            char isLoadedChar = [b isLoaded] ? '*' : ' ';
            [ms appendFormat:@"%c <a href=\"/tree%@%@\">%@/</a>\n", isLoadedChar, path, fileName, fileName];
        }

    } else if([path isEqualToString:@"/lib/"]) {
        
        NSDictionary *classStubsByImagePath = [[AllClasses sharedInstance] allClassStubsByImagePath];
        
        NSMutableArray *files = [NSMutableArray array];
        [classStubsByImagePath enumerateKeysAndObjectsUsingBlock:^(NSString *imagePath, ClassStub *classStub, BOOL *stop) {
            if([[imagePath pathExtension] isEqualToString:@"dylib"] == NO) return;
            [files addObject:[imagePath lastPathComponent]];
        }];
        [files sortedArrayUsingSelector:@selector(compare:)];

        [ms appendFormat:@"%@\n%@ dylibs\n\n", path, @([files count])];

        for(NSString *fileName in files) {
            [ms appendFormat:@"<a href=\"/tree%@%@\">%@/</a>\n", path, fileName, fileName];
        }
    }
    
    NSString *html = [self htmlPageWithContents:ms title:@"iOS Runtime Browser - Tree View"];
    
    NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
    
    return [[HTTPDataResponse alloc] initWithData:data];
}

- (NSString *)htmlHeader {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"header" ofType:@"html"];
    return [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
}

- (NSString *)htmlFooter {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"footer" ofType:@"html"];
    return [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
}

- (NSString *)htmlPageWithContents:(NSString *)contents title:(NSString *)title {
    NSString *header = [[[self htmlHeader] mutableCopy] stringByReplacingOccurrencesOfString:@"__TITLE__" withString:title];
    return [@[header, contents, [self htmlFooter]] componentsJoinedByString:@"\n"];
}

- (NSObject<HTTPResponse> *)responseForPath:(NSString *)path {
    
    if([path hasSuffix:@".h"]) {
        return [self responseForHeaderPath:path];
    }
    
    if([path hasPrefix:@"/list"]) {
        return [self responseForList];
    } else if ([path hasPrefix:@"/tree"]) {
        NSString *subPath = [path substringFromIndex:[@"/tree" length]];
        return [self responseForTreeWithPath:subPath];
    } else {
        NSString *s = [NSString stringWithFormat:
                       @" You can browse the loaded classes either by <a href=\"/list/\">list</a> or by <a href=\"/tree/\">tree</a>.\n\n"
                       " To retrieve the headers as on <a href=\"https://github.com/nst/iOS-Runtime-Headers\">https://github.com/nst/iOS-Runtime-Headers</a>:\n\n"
                       "     $ wget -r http://%@:10000/tree/\n", [self myIPAddress]];
        
        NSString *html = [self htmlPageWithContents:s title:@"iOS Runtime Browser"];
        
        NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
        
        return [[HTTPDataResponse alloc] initWithData:data];
    }
}

- (void)stopWebServer {
    [_httpServer stop];
}

- (void)startWebServer {
    NSDictionary *ips = [[RTBMyIP sharedInstance] ipsForInterfaces];
    BOOL isConnectedThroughWifi = [ips objectForKey:@"en0"] != nil;
    
    if(isConnectedThroughWifi || TARGET_IPHONE_SIMULATOR) {
        self.httpServer = [[HTTPServer alloc] init];
        [_httpServer setType:@"_http._tcp."];
        [_httpServer setPort:10000];
        
        NSError *error;
        BOOL success = [_httpServer start:&error];
        
        if(success == NO) {
            NSLog(@"Error starting HTTP Server.");
            
            if(error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error starting HTTP Server"
                                                                message:[error localizedDescription]
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            [_httpServer stop];
            self.httpServer = nil;
        } else {
            [UIApplication sharedApplication].idleTimerDisabled = YES; // prevent sleep
        }
    } else {
        // TODO: allow USB connection..
        NSLog(@"Not connected through wifi, don't start web server.");
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window.tintColor = [UIColor purpleColor];
    
    NSString *defaultsPath = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    self.allClasses = [AllClasses sharedInstance];
    
    BOOL startWebServer = [[NSUserDefaults standardUserDefaults] boolForKey:@"EnableWebServer"];
    
    if(startWebServer) {
        [self startWebServer];
    }
    
    return YES;
}

- (UInt16)serverPort {
    return [_httpServer port];
}

- (void)showHeaderForClassName:(NSString *)className {
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    RTBClassDisplayVC *classDisplayVC = (RTBClassDisplayVC *)[sb instantiateViewControllerWithIdentifier:@"RTBClassDisplayVC"];
    classDisplayVC.className = className;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:classDisplayVC];
    [self.window.rootViewController presentViewController:navigationController animated:YES completion:nil];
}

//- (IBAction)dismissModalView:(id)sender {
//	[_tabBarController dismissViewControllerAnimated:YES completion:^{
//        //
//    }];
//}

- (void)applicationWillTerminate:(UIApplication *)application {
    [_httpServer stop];
}

@end
