/*
 
 AllClasses.m created by eepstein on Sat 16-Mar-2002 

 Author: Ezra Epstein (eepstein@prajna.com)

 Copyright (c) 2002 by Prajna IT Consulting.
                       http://www.prajna.com

 ========================================================================

 THIS PROGRAM AND THIS CODE COME WITH ABSOLUTELY NO WARRANTY.
 THIS CODE HAS BEEN PROVIDED "AS IS" AND THE RESPONSIBILITY
 FOR ITS OPERATIONS IS 100% YOURS.

 ========================================================================
 This file is part of RuntimeBrowser.

 RuntimeBrowser is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 RuntimeBrowser is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with RuntimeBrowser (in a file called "COPYING.txt"); if not,
 write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 Boston, MA  02111-1307  USA

*/

#import "AllClasses.h"
#import "ClassStub.h"

#if (! TARGET_OS_IPHONE)
#import <objc/objc-runtime.h>
#else
#import <objc/runtime.h>
#import <objc/message.h>
#endif

#import <stdio.h>

static AllClasses *sharedInstance;

@interface AllClasses()

@property (nonatomic, retain) NSMutableArray *rootClasses;
@property (nonatomic, retain) NSMutableArray *rootProtocols;

@end


@implementation AllClasses

@synthesize rootClasses = _rootClasses;
@synthesize rootProtocols = _rootProtocols;
@synthesize allClassStubsByName;
@synthesize allClassStubsByImagePath;
@synthesize allProtocolStubsByName;

+ (AllClasses *)sharedInstance {
	if(sharedInstance == nil) {
		sharedInstance = [[AllClasses alloc] init];
		sharedInstance.rootClasses = [NSMutableArray array];
        sharedInstance.rootProtocols = [NSMutableArray array];
		sharedInstance.allClassStubsByName = [NSMutableDictionary dictionary];
		sharedInstance.allClassStubsByImagePath = [NSMutableDictionary dictionary];
        sharedInstance.allProtocolStubsByName = [NSMutableDictionary dictionary];
	}
	
	return sharedInstance;
}

+ (void)thisClassIsPartOfTheRuntimeBrowser {}

- (void)dealloc {
	[self.rootClasses release];
    [self.rootProtocols release];
	[allClassStubsByName release];
	[allClassStubsByImagePath release];
    [allProtocolStubsByName release];
	[super dealloc];
}

- (ClassStub *)classStubForClassName:(NSString *)classname {
    return [allClassStubsByName valueForKey:classname];
}

- (ClassStub *)classStubForProtocolName:(NSString *)protocolname {
    return [allProtocolStubsByName valueForKey:protocolname];
}

- (ClassStub *)getOrCreateClassStubsRecursivelyForClass:(Class)klass {
	
	//Lookup the ClassStub for klass or create one if none exists and add it to +allClassStuds.
    NSString *klassName = NSStringFromClass(klass);
	
    // First check if we've already got a ClassStub for klass. If yes, we'll return it.
    ClassStub *cs = [self classStubForClassName:klassName];
	if(cs) return cs;
	
    // klass doesn't yet have a ClassStub...
	cs = [ClassStub classStubWithClass:klass]; // Create a ClassStub for klass
	
	if(cs == nil) {
		NSLog(@"-- cannot create classStub for %@, ignore it", klassName);
		return nil;
	}
	
	[allClassStubsByName setObject:cs forKey:klassName]; // Add it to our uniquing dictionary.
	
	/* fill stubsForImage */
	NSString *path = [cs imagePath];
    
#if TARGET_IPHONE_SIMULATOR
    // remove path prefix, eg.
    //   /Applications/Xcode5-DP.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator7.0.sdk/System/Library/PrivateFrameworks/CoreUI.framework/CoreUI
    // will become
    //   /System/Library/PrivateFrameworks/CoreUI.framework/CoreUI

    if([path hasPrefix:@"/Applications/"]) {
        NSUInteger i = [path rangeOfString:@".sdk"].location;
        if(i != NSNotFound) {
            NSUInteger start = i + 4;
            path = [path substringFromIndex:start];
        }
    }
#endif
    
	if(path) {
		NSMutableArray *stubsForImage = [allClassStubsByImagePath valueForKey:path];
		if(stubsForImage == nil) {
			[allClassStubsByImagePath setValue:[NSMutableArray array] forKey:path];
			stubsForImage = [allClassStubsByImagePath valueForKey:path];
		}
		if([stubsForImage containsObject:cs] == NO) [stubsForImage addObject:cs];
	}
	
	Class parent = class_getSuperclass(klass);   // Get klass's superclass 
	if (parent != nil) {               // and recursively create (or get) its stub.
		ClassStub *parentCs = [self getOrCreateClassStubsRecursivelyForClass:parent];
		[parentCs addSubclassStub:cs];  // we are a subclass of our parent.
	} else  // If there is no superclass, then klass is a root class.
		[[self rootClasses] addObject:cs];
	
    unsigned int i, numAdoptedProtocol;
    Protocol **adoptedProtocols = class_copyProtocolList(klass, &numAdoptedProtocol);
    for (i = 0; i < numAdoptedProtocol; i++) {
        ClassStub *parentCs = [self classStubForProtocolName:NSStringFromProtocol(adoptedProtocols[i])];
        [parentCs addSubclassStub:cs];  // we are a class adopting the protocol.
    }
    free (adoptedProtocols);
    
    return cs;
}

- (ClassStub *)getOrCreateProtocolStubsRecursivelyForProtocol:(Protocol *)proto {
    
    //Lookup the ClassStub for klass or create one if none exists and add it to +allClassStuds.
    NSString *protocolName = NSStringFromProtocol(proto);
    
    // First check if we've already got a ClassStub for klass. If yes, we'll return it.
    ClassStub *cs = [self classStubForProtocolName:protocolName];
    if(cs) return cs;
    
    // klass doesn't yet have a ClassStub...
    cs = [ClassStub classStubWithProtocol:proto]; // Create a ClassStub for klass
    
    if(cs == nil) {
        NSLog(@"-- cannot create classStub for %@, ignore it", protocolName);
        return nil;
    }
    
    [allProtocolStubsByName setObject:cs forKey:protocolName]; // Add it to our uniquing dictionary.
    
    unsigned int i, numAdoptedProtocol;
    Protocol **adoptedProtocols = protocol_copyProtocolList(proto, &numAdoptedProtocol);
    if (adoptedProtocols != NULL) {
        for (i = 0; i < numAdoptedProtocol; i++) {
            ClassStub *parentCs = [self getOrCreateProtocolStubsRecursivelyForProtocol:adoptedProtocols[i]];
            [parentCs addSubclassStub:cs];  // we are a protocol adopting the parent protocol.
        }
        free (adoptedProtocols);
    } else { // No adopted protocol, proto is a root protocol
        [[self rootProtocols] addObject:cs];
    }
    
    return cs;
}



- (NSArray *)sortedClassStubs:(ClassStubFilter)filter {
	if([allClassStubsByName count] == 0) [self readAllRuntimeClasses];
	
    NSMutableArray *stubs = [NSMutableArray array];
    if (filter == ClassStubClass || filter == ClassStubAll) {
        [stubs addObjectsFromArray:[allClassStubsByName allValues]];
    }
    if (filter == ClassStubProtocol || filter == ClassStubAll) {
        [stubs addObjectsFromArray:[allProtocolStubsByName allValues]];
    }
	[stubs sortUsingSelector:@selector(compare:)];
	return stubs;
}

- (void)readAllRuntimeProtocols {
    unsigned int i, numProtocols = 0;
    Protocol **protocols = objc_copyProtocolList(&numProtocols);
    
    for (i=0; i<numProtocols; ++i)
        [self getOrCreateProtocolStubsRecursivelyForProtocol:protocols[i]];
    
    free(protocols);
    
    // [rootClasses sortUsingSelector:@selector(compare:)];
}

- (void)readAllRuntimeClasses {
    [self readAllRuntimeProtocols];
    
	int i, numClasses = 0;
	int newNumClasses = objc_getClassList(NULL, 0);
	Class *classes = NULL;

	while (numClasses < newNumClasses) {
		numClasses = newNumClasses;
		classes = realloc(classes, sizeof(Class) * numClasses);
		newNumClasses = objc_getClassList(classes, numClasses);
	}

	for (i=0; i<numClasses; ++i)
		[self getOrCreateClassStubsRecursivelyForClass:classes[i]];

	free(classes);
	
	//[self.rootClasses sortUsingSelector:@selector(compare:)];
    //[self.rootProtocols sortUsingSelector:@selector(compare:)];
}

- (NSMutableDictionary *)allClassStubsByImagePath {
	if([allClassStubsByImagePath count] == 0) {
		[self readAllRuntimeClasses];
	}
	return allClassStubsByImagePath;
}

- (NSArray *)rootClassStubs:(ClassStubFilter)filter {
    /*" Classes are wrapped by ClassStub.  This array contains wrappers for root classes (classes that have no superclass). "*/
    if ([self.rootClasses count] == 0) {
        [self readAllRuntimeClasses];
    }
    
    NSMutableArray *stubs = [NSMutableArray array];
    if (filter == ClassStubClass || filter == ClassStubAll) {
        [stubs addObjectsFromArray:self.rootClasses];
    }
    if (filter == ClassStubProtocol || filter == ClassStubAll) {
        [stubs addObjectsFromArray:self.rootProtocols];
    }
    [stubs sortUsingSelector:@selector(compare:)];
    return stubs;
}

- (void)emptyCachesAndReadAllRuntimeClasses {
/*"
We autorelease and reset the nil the global, static containers that
 hold the parsed runtime info.  This forces the entire runtime to\
 be re-parsed.

 +reset is designed to be called after the user has loaded new
 bundles (via "File -> Open..." in the UI's menu).
"*/	
	self.rootClasses = [NSMutableArray array];
    self.rootProtocols = [NSMutableArray array];
	self.allClassStubsByName = [NSMutableDictionary dictionary];
	self.allClassStubsByImagePath = [NSMutableDictionary dictionary];
	
	[self readAllRuntimeClasses];
}

@end
