/* 

ClassStub.m created by eepstein on Sat 16-Mar-2002

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

#import "ClassStub.h"
#import "ClassDisplay.h"

#if (! TARGET_OS_IPHONE)
#import <objc/objc-runtime.h>
#else
#import <objc/runtime.h>
#import <objc/message.h>
#endif

@interface ClassStub()
@property (nonatomic, retain) NSString *imagePath;
- (ClassStub *)initWithClass:(Class)klass;
@end

@implementation ClassStub

@synthesize stubClassname;
@synthesize imagePath;
@synthesize subclassesStubs;

+ (ClassStub *)classStubWithClass:(Class)klass {
    return [[[ClassStub alloc] initWithClass:klass] autorelease];
}

+ (void)thisClassIsPartOfTheRuntimeBrowser {
/*" So the user knows when browsing this class in the RuntimeBrowser.
 We put this method last so it shows up first. "*/
}

- (BOOL)writeAtPath:(NSString *)path {

	NSURL *pathURL = [NSURL fileURLWithPath:path];
	
	Class klass = NSClassFromString(stubClassname);
	ClassDisplay *cd = [ClassDisplay classDisplayWithClass:klass];
	NSString *header = [cd header];
	
	NSError *error = nil;	
	BOOL success = [header writeToURL:pathURL atomically:NO encoding:NSUTF8StringEncoding error:&error];
	if(success == NO) {
		NSLog(@"-- %@", error);
	}
	
	return success;
}

- (NSMutableSet *)ivarTokens {
	Class klass = NSClassFromString(stubClassname);

	NSMutableSet *ms = [NSMutableSet set];
	
	unsigned int ivarListCount;
	Ivar *ivarList = class_copyIvarList(klass, &ivarListCount);
	
    if (ivarList != NULL && (ivarListCount>0)) {
        NSUInteger i;
        for (i = 0; i < ivarListCount; ++i ) {
            Ivar rtIvar = ivarList[i];
			const char* ivarName = ivar_getName(rtIvar);
			if(ivarName) [ms addObject:[[NSString stringWithCString:ivarName encoding:NSUTF8StringEncoding] lowercaseString]];
		}
	}
	
	free(ivarList);
	
	[ms removeObject:@""];
	
	return ms;
}

- (NSMutableSet *)methodsTokensForClass:(Class)klass {
	NSMutableSet *ms = [NSMutableSet set];
	
	unsigned int methodListCount;
	Method *methodList = class_copyMethodList(klass, &methodListCount);
	
    NSUInteger i;
	for (i = 0; i < methodListCount; i++) {
		Method currMethod = (methodList[i]);
		NSString *mName = [NSString stringWithCString:(const char *)method_getName(currMethod) encoding:NSASCIIStringEncoding];
		NSArray *mNameParts = [mName componentsSeparatedByString:@":"];
		for(NSString *mNamePart in mNameParts) {
			[ms addObject:[mNamePart lowercaseString]];
		}
    }
	
	free(methodList);

	return ms;
}

- (NSMutableSet *)methodsTokens {
	Class klass = NSClassFromString(stubClassname);
	Class metaClass = objc_getMetaClass(class_getName(klass));

	NSMutableSet *ms = [NSMutableSet set];
	
	[ms addObjectsFromArray:[[self methodsTokensForClass:klass] allObjects]];
	[ms addObjectsFromArray:[[self methodsTokensForClass:metaClass] allObjects]];
	
	[ms removeObject:@""];
	
	return ms;
}

- (NSMutableSet *)protocolsTokensForClass:(Class)c {
	NSMutableSet *ms = [NSMutableSet set];

	unsigned int protocolListCount;
	Protocol **protocolList = class_copyProtocolList(c, &protocolListCount);
	if (protocolList != NULL && (protocolListCount > 0)) {
		NSUInteger i;
        for(i = 0; i < protocolListCount; i++) {
			Protocol *p = protocolList[i];
			const char* protocolName = protocol_getName(p);
			if(protocolName) [ms addObject:[[NSString stringWithCString:protocolName encoding:NSUTF8StringEncoding] lowercaseString]];
		}
	}
	free(protocolList);

	return ms;
}

- (NSMutableSet *)protocolsTokensForClass:(Class)klass includeSuperclassesProtocols:(BOOL)includeSuperclassesProtocols {
	
	NSMutableSet *ms = [self protocolsTokensForClass:klass];
	
	if (includeSuperclassesProtocols) {
		Class c;
        for(c = klass; class_getSuperclass(c) != c; c = class_getSuperclass(c)) {
			NSMutableSet *ms2 = [self protocolsTokensForClass:c];
			[ms unionSet:ms2];
		}
	}
	
	return ms;
}

- (NSMutableSet *)protocolsTokens {
	Class klass = NSClassFromString(stubClassname);

	return [self protocolsTokensForClass:klass includeSuperclassesProtocols:YES]; // TODO: put includeSuperclassesProtocols in user defaults
}

- (NSString *)imagePath {
	return imagePath;
}

- (ClassStub *)initWithClass:(Class)klass {
    self = [super init];
	
	NSString *className = NSStringFromClass(klass);
	
    [self setStubClassname:className];
	
	const char* imageNameC = class_getImageName(klass);
	
	NSString *image = nil;
	if(imageNameC) {
		image = [NSString stringWithCString:imageNameC encoding:NSUTF8StringEncoding];	
	} else {
		NSLog(@"-- cannot find image for class %@", className);
		//image = [[NSBundle bundleForClass:klass] bundlePath];
	}
	
	self.imagePath = image;

	self.subclassesStubs = [NSMutableArray array];
    subclassesAreSorted = NO;
	shouldSortSubclasses = YES;
    return self;
}

- (NSArray *)subclassesStubs {
    if (!subclassesAreSorted && shouldSortSubclasses) {
        [subclassesStubs sortUsingSelector:@selector(compare:)];
        subclassesAreSorted = YES;
    }
    return (NSArray *)subclassesStubs;
}

- (void)addSubclassStub:(ClassStub *)classStub {
    [subclassesStubs addObject:classStub];
    subclassesAreSorted = NO;
}

- (NSString *)description {
    return stubClassname;
}

- (NSComparisonResult)compare:(ClassStub *)otherCS {
    return [stubClassname compare:[otherCS stubClassname]];
}

- (void)dealloc {
	[imagePath release];
    [stubClassname release];
    [subclassesStubs release];
    [super dealloc];
}

- (BOOL)containsSearchString:(NSString *)searchString {
    // TODO: cache searchStrings known to be in the class
    
    NSString *ss = [searchString lowercaseString];
    
    if([[stubClassname lowercaseString] rangeOfString:ss].location != NSNotFound) {
        return YES;
    }
    
    for(NSString *token in [self ivarTokens]) {
        if([[token lowercaseString] rangeOfString:ss].location != NSNotFound) {
            return YES;
        }
    }
    
    for(NSString *token in [self methodsTokens]) {
        if([[token lowercaseString] rangeOfString:ss].location != NSNotFound) {
            return YES;
        }
    }
    
    for(NSString *token in [self protocolsTokens]) {
        if([[token lowercaseString] rangeOfString:ss].location != NSNotFound) {
            return YES;
        }
    }
    
    ClassDisplay *cd = [ClassDisplay classDisplayWithClass:NSClassFromString(stubClassname)];

    for(NSString *token in [cd ivarsTypeTokens]) {
        if([[token lowercaseString] rangeOfString:ss].location != NSNotFound) {
            return YES;
        }        
    }
    
    return NO;
}

#pragma mark BrowserNode protocol

- (NSArray *)children {
	return [self subclassesStubs];
}

- (NSString *)nodeName {
	return stubClassname;
}

- (NSString *)nodeInfo {
    return [NSString stringWithFormat:@"%@ (%d)", [self nodeName], [[self children] count]];
}

- (BOOL)canBeSavedAsHeader {
	return YES;
}

@end
