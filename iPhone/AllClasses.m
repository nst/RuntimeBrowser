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

#import <objc/objc-runtime.h>

static NSArray *_rtbClasses = nil;

/* Dictionary mapping Class-Name to ClassStub, used to unique the ClassStub instances. */
static NSMutableDictionary *_allClassStubs = nil;

/* An array of all the root classes (classes that have no super class). */
static NSMutableArray *_rootClasses = nil;

/***********************************************************/

@implementation AllClasses

+ (void)thisClassIsPartOfTheRuntimeBrowser {}

+ (NSMutableDictionary *)allClassStubs
    /*" Classes are wrapped by ClassStub.  This contains wrappers for *ALL* classes in the runtime "*/
{
    if (!_allClassStubs)
        _allClassStubs = [[NSMutableDictionary alloc] init]; // static -- don't autorelease
    return _allClassStubs;
}

+ (NSMutableArray *)rootClasses
    /*" Classes are wrapped by ClassStub.  This array contains wrappers for root classes (classes that have no superclass). "*/
{
   if (!_rootClasses)
       _rootClasses = [[NSMutableArray alloc] init]; // static -- don't autorelease
    return _rootClasses;
}

/****/

+ (ClassStub *)getClassStubForClassName:(NSString *)classname
    /*" This looks up the stub for classname in +allClassStubs. "*/
{
    return [[self allClassStubs] objectForKey:classname];
}


+ (ClassStub *)_classStubForClass:(Class)klass
/*"
    Lookup the ClassStub for klass or create one if none exists and add it to +allClassStuds.
"*/
{
    ClassStub* cw = nil;
    // NSStringFromClass is defined in Foundation/NSObjCRuntime.h
    NSString *klassName = NSStringFromClass(klass);
	//NSLog(@"-- lookup %@", klassName);

    // PENDING: on/off based on Prefs...
    // If the prefix is NSFramework_ and its a root class (no superclass) then
    // let's skip it, since it's an artifact of how Frameworks are built.
    if ([klassName hasPrefix:@"NSFramework_"] && (class_getSuperclass(klass) == Nil))
        return cw;

    // First check if we've already got a ClassStub for klass.  If yes, we'll return it.
    cw = [self getClassStubForClassName:klassName];

    // klass doesn't yet have a ClassStub...
    if (cw == nil) {
        Class parent;
        ClassStub* parentCw;

        cw = [ClassStub classStubWithClass:klass];  // Create a ClassStub for klass
        [[self allClassStubs] setObject:cw forKey:klassName]; // Add it to our uniquing dictionary.

        parent = class_getSuperclass(klass);   // Get klass's superclass 
        if (parent != Nil) {               // and recursively create (or get) its stub.
            parentCw = [self _classStubForClass:parent];
            [parentCw addSubclassStub:cw];  // we are a subclass of our parent.
        } else  // If there is no superclass, then klass is a root class.
            [[self rootClasses] addObject:cw];
    }

    return cw;
}

/*****/

+ (NSMutableArray *)allSubclassesForClassStub:(ClassStub *)cs {
	NSMutableArray *a = [[NSMutableArray alloc] init];
	
	//NSLog(@"-- %@", cs.stubClassname);
	
	[a addObject:cs];
	for(ClassStub *sub in [cs subclassesStubs]) {
		[a addObjectsFromArray:[AllClasses allSubclassesForClassStub:sub]];
	}
	
	return [a autorelease];
}

+ (NSMutableArray *)allClasses {
	NSMutableArray *a = [[NSMutableArray alloc] init];
	for(ClassStub *cs in [AllClasses rootStubClassArray]) {
		[a addObjectsFromArray:[AllClasses allSubclassesForClassStub:cs]];
	}
	
	NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"description" ascending:YES];
	[a sortUsingDescriptors:[NSArray arrayWithObject:sd]];
	[sd release];
	
	return [a autorelease];
}

+ (NSArray *)rootStubClassArray {
	
	if(!_rtbClasses) {
		NSString *path = [[NSBundle mainBundle] pathForResource:@"RTBClasses" ofType:@"plist"];
		_rtbClasses = [NSArray arrayWithContentsOfFile:path];
		[_rtbClasses retain];
	}
	
    if (!_rootClasses) {
        int i, numClasses = 0;
        int newNumClasses = objc_getClassList(NULL, 0);
        Class *classes = NULL;

        while (numClasses < newNumClasses) {
            numClasses = newNumClasses;
            classes = realloc(classes, sizeof(Class) * numClasses);
            newNumClasses = objc_getClassList(classes, numClasses);
        }

		const char* currentImageName = class_getImageName([self class]);
        for (i=0; i<numClasses; ++i) {
			Class klass = classes[i];
			if(!klass) continue;
			
			BOOL hideRTBClasses = [[NSUserDefaults standardUserDefaults] boolForKey:@"HideCurrentApplicationClasses"];
			BOOL isFromCurrentImage = !strcmp(class_getImageName(klass), currentImageName);
			
			if(hideRTBClasses && isFromCurrentImage) {
				//NSLog(@"-- hide %@", NSStringFromClass(klass));
			} else {
				[self _classStubForClass:klass];			
			}
		}

        free(classes);

        [_rootClasses sortUsingSelector:@selector(compare:)];
    }
		
    return _rootClasses;
}

+ (void)reset
/*"
We autorelease and reset the nil the global, static containers that
 hold the parsed runtime info.  This forces the entire runtime to\
 be re-parsed.

 +reset is designed to be called after the user has loaded new
 bundles (via "File -> Open..." in the UI's menu).
"*/
{
   [_allClassStubs autorelease];
   [_rootClasses autorelease];
   _allClassStubs = nil;
   _rootClasses = nil;
}

@end
