/* 
 
 AppController.m created by eepstein on Mon 15-Apr-2002 
 
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
 text
 You should have received a copy of the GNU General Public License
 along with RuntimeBrowser (in a file called "COPYING.txt"); if not,
 write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 Boston, MA  02111-1307  USA
 
 */

#import "AppController.h"
#import "AllClasses.h"
#import "NSTextView+SyntaxColoring.h"
#import "BrowserNode.h"
#import "BrowserCell.h"
#import "ClassStub.h"

@implementation AppController

@synthesize saveDirURL;
//@synthesize openDir;
@synthesize keywords;
@synthesize classes;
@synthesize allClasses;
@synthesize segmentedControl;
@synthesize searchResultsNode;
@synthesize mainWindow;
@synthesize searchResults;
@synthesize searchQueue;

+ (void)thisClassIsPartOfTheRuntimeBrowser {}

- (id)init {
	self = [super init];
	
	NSString *keywordsPath = [[NSBundle mainBundle] pathForResource:@"Keywords" ofType:@"plist"];
	
	self.keywords = [NSArray arrayWithContentsOfFile:keywordsPath];
	
	self.allClasses = [AllClasses sharedInstance];
	
	NSDictionary *defaultsPath = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"]];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultsPath];
	
	return self;
}

- (void)dealloc {
	//[openDir release];
	[saveDirURL release];
	[keywords release];
    [searchResultsNode release];
	[mainWindow release];
    [searchResults release];
    [searchQueue release];
	[super dealloc];
}

- (BOOL)saveAsHeaderIsEnabled {
	id item = [classBrowser itemAtIndexPath:[classBrowser selectionIndexPath]];
	return [item canBeSavedAsHeader];
}

- (void)loadBundlesURLs:(NSArray *)bundlesURLs {
	BOOL loadedNew = NO;
	
	NSMutableArray *errors = [NSMutableArray array];
	
	for (NSURL *url in bundlesURLs) {        
		NSBundle *bundle = [NSBundle bundleWithURL:url];
		NSError *error = nil;
		loadedNew |= [bundle loadAndReturnError:&error];
		if(error) {
			[errors addObject:error];
		}
	}
	
	// we show only one error
	NSError *error = [errors lastObject];
	if(error) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
	}
    
	if (loadedNew) {
		//[classBrowser scrollColumnToVisible:0];
		[allClasses emptyCachesAndReadAllRuntimeClasses]; // TODO: read only classes from bundles instead of everything
		[classBrowser loadColumnZero];
        
		//self.openDir = [[bundlesURLs lastObject] stringByDeletingLastPathComponent];
		[label setStringValue:@"Select a Class"];
		[headerTextView setString:@""];
		
		RBBrowserViewType viewType = [[NSUserDefaults standardUserDefaults] integerForKey:@"ViewType"];
		if(viewType == RBBrowserViewTypeImages) {
			NSString *rootTitle = [NSString stringWithFormat:@"%d images", [[allClasses allClassStubsByImagePath] count]];
			[classBrowser setTitle:rootTitle ofColumn:0];
		}
	}
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
    
    NSMutableArray *urls = [NSMutableArray arrayWithCapacity:[filenames count]];
    
    for(NSString *path in filenames) {
        NSURL *url = [NSURL URLWithString:path];
        [urls addObject:url];
    }
    
	[self loadBundlesURLs:urls];
}

- (NSArray *)acceptableExtensions {
	return [NSArray arrayWithObjects:@"dylib", @"framework", @"bundle", @"app", nil];//@"EOMbundle", @"EOMplugin", @"woa", @"dll", @"exe"
}

- (IBAction)openAction:(id)sender {
	
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	
    [oPanel setAllowsMultipleSelection:YES];
    [oPanel setCanChooseDirectories:YES];
    [oPanel setCanChooseFiles:YES];
	
    [oPanel beginSheetModalForWindow:mainWindow completionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            NSArray *urlsToOpen = [oPanel URLs];
            [self loadBundlesURLs:urlsToOpen];
        }
    }];
}

- (IBAction)saveAction:(id)sender {
    
    NSString *className = [[classBrowser selectedCell] stringValue];
    if ([className length] == 0) {
        NSRunAlertPanel(nil, @"Select a class before saving.", @"OK", nil, nil);
        return;
    }
	
    NSSavePanel *sp = [NSSavePanel savePanel];
	[sp setDirectoryURL:saveDirURL];
	[sp setAllowedFileTypes:[NSArray arrayWithObject:@"h"]];
	[sp setNameFieldStringValue:className];
	
    [sp beginSheetModalForWindow:[classBrowser window] completionHandler:^(NSInteger result) {
		
		if ( result != NSOKButton ) return;
		
		NSString *fileContents = [headerTextView string];
		NSURL *fileURL = [sp URL];
		
		NSError *error = nil;
		[[NSProcessInfo processInfo] disableSuddenTermination];
        //        if(canUseLionAPIs) {
        //            [[NSProcessInfo processInfo] disableAutomaticTermination:@"writing files"];
        //        }
        
		BOOL success = [fileContents writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:&error];
		[[NSProcessInfo processInfo] enableSuddenTermination];
        //        if(canUseLionAPIs) {
        //            [[NSProcessInfo processInfo] enableAutomaticTermination:@"did finish writing files"];
        //		}
        
		if (success) {
			self.saveDirURL = [fileURL URLByDeletingLastPathComponent];
		} else {
			NSString *message = [NSString stringWithFormat:@"Please try again, perhaps selecting a different file/directory. Error: %@", error];
			NSRunAlertPanel(@"Save Failed :( !", message, @"OK", nil, nil);
		}
	}];
}

- (IBAction)saveAllAction:(id)sender {
	
    NSOpenPanel *sp = [NSOpenPanel openPanel]; // we want to open a folder to save
	
    [sp setAllowsMultipleSelection:NO];
    [sp setCanChooseDirectories:YES];
    [sp setCanChooseFiles:NO];
    [sp setCanCreateDirectories:YES];
	[sp setMessage:@"Choose a folder where to save all headers."];
    [sp setTitle:@"Save All Classes"];
    [sp setPrompt:@"Save"];
	
	[sp beginSheetModalForWindow:[classBrowser window] completionHandler:^(NSInteger result) {
        
        if ( result != NSOKButton ) return;
        
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [queue addOperationWithBlock:^{
            
            NSUInteger saved = 0;
            NSUInteger failed = 0;
            NSURL *dirURL = [sp URL];
            
            NSArray *classNames = [[[allClasses allClassStubsByName] allKeys] copy];
            
            [[NSProcessInfo processInfo] disableSuddenTermination];
            //               if(canUseLionAPIs) {
            //                   [[NSProcessInfo processInfo] disableAutomaticTermination:@"writing files"];
            //               }
            
            for(NSString *className in classNames) {
                NSString *filename = [NSString stringWithFormat:@"%@.h", className];
                NSURL *url = [dirURL URLByAppendingPathComponent:filename];
                
                ClassDisplay *cd = [ClassDisplay classDisplayWithClass:NSClassFromString(className)];
                NSString *header = [cd header];
                
                NSError *error = nil;
                BOOL success = [header writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&error];
                
                if (success) {
                    ++saved;
                } else {
                    ++failed;
                    NSLog(@"-- error, could not save class %@ at URL %@, error %@", className, url, error);
                }
            }
            
            [[NSProcessInfo processInfo] enableSuddenTermination];
            //               if(canUseLionAPIs) {
            //                   [[NSProcessInfo processInfo] enableAutomaticTermination:@"did finish writing files"];
            //               }
            
            [classNames release];
            
            NSString *message = [NSString stringWithFormat:@"Done saving all classes into %@. \n  %d classes saved. \n  %d classes failed to save.", [dirURL path], saved, failed];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                NSRunInformationalAlertPanel(@"Save All Finished", message, @"OK", nil, nil);
            }];
            
        }];
        [queue release];
        
    }
	 ];
}

- (BOOL)validateMenuItem:(NSMenuItem *)aMenuItem {
    if ( [[aMenuItem title] isEqualToString:@"Save As..."] )
        return ( [[[classBrowser selectedCell] stringValue] length] != 0 ); 
    return YES;
}

- (BOOL)shouldShowDisclosureIndicatorOnClasses {
	RBBrowserViewType viewType = [[NSUserDefaults standardUserDefaults] integerForKey:@"ViewType"];
	return viewType == RBBrowserViewTypeTree;
}

- (BOOL)isInSearchMode {
    return [[searchField stringValue] length] > 0;
}

- (void)changeViewTypeTo:(RBBrowserViewType)viewType {    
	[[NSUserDefaults standardUserDefaults] setInteger:viewType forKey:@"ViewType"];
	
    NSUInteger nbOfColumns = 1;
    if(viewType == RBBrowserViewTypeImages) nbOfColumns = 2;
    if(viewType == RBBrowserViewTypeTree) nbOfColumns = 3;
	[classBrowser setMaxVisibleColumns:nbOfColumns];
    
	NSBrowserColumnResizingType resizingType = viewType == RBBrowserViewTypeTree ? NSBrowserUserColumnResizing : NSBrowserAutoColumnResizing;
	[classBrowser setColumnResizingType:resizingType];
    
	[classBrowser loadColumnZero];
	
    id rootItem = [self rootItemForBrowser:classBrowser];
    
	NSString *rootTitle = @"";
	if(viewType == RBBrowserViewTypeList) {
        rootTitle = [NSString stringWithFormat:@"%d classes", [[rootItem children] count]];
        
        if([self isInSearchMode]) {
            rootTitle = @"No classes found";
        }
    }
    
    if(viewType == RBBrowserViewTypeTree)   rootTitle = [NSString stringWithFormat:@"%d Root Classes", [[rootItem children] count]];
	if(viewType == RBBrowserViewTypeImages) rootTitle = [NSString stringWithFormat:@"%d Images", [[rootItem children] count]];
	
    [label setStringValue:@""];
    [headerTextView setString:@""];
    
	[classBrowser setTitle:rootTitle ofColumn:0];
}

- (IBAction)changeViewTypeFromSegmentedControl:(NSSegmentedControl *)sender {
    RBBrowserViewType viewType = sender.selectedSegment;
    if(viewType != RBBrowserViewTypeList) [searchField setStringValue:@""];
    
	[self changeViewTypeTo:sender.selectedSegment];
}

- (IBAction)changeViewTypeFromMenuItem:(NSMenuItem *)sender {
    RBBrowserViewType viewType = [sender tag];
	
    if([self isInSearchMode]) {
        if(viewType != RBBrowserViewTypeList) [searchField setStringValue:@""];
        [segmentedControl setEnabled:YES forSegment:0];
        [segmentedControl setEnabled:YES forSegment:2];
    }
	
	[self changeViewTypeTo:[sender tag]];
}

- (IBAction)search:(id)sender {
	
    BOOL isInSearchMode = [self isInSearchMode];
    
    [searchQueue cancelAllOperations];
    
    if(isInSearchMode == NO) {
        [self changeViewTypeTo:RBBrowserViewTypeList];
        return;
    }
    
    self.searchResults = [NSMutableArray array];
    
    self.searchResultsNode = [[[BrowserNode alloc] init] autorelease];
	
    NSString *searchString = [[[searchField stringValue] copy] autorelease];
    
    NSArray *classStubs = [[AllClasses sharedInstance] sortedClassStubs];
    
    self.searchQueue = [[[NSOperationQueue alloc] init] autorelease];
    
    //    NSUInteger maxConcurrentOperationCount = [[NSProcessInfo processInfo] processorCount] + 1;
    
    //    [searchQueue setMaxConcurrentOperationCount:maxConcurrentOperationCount];
    
    NSBlockOperation *op = [[NSBlockOperation alloc] init];
    
    for (id classStub in classStubs) {
        
        [op addExecutionBlock:^{

            if([op isCancelled]) {
                //NSLog(@"-- op isCancelled");
                return;
            }

            BOOL found = [classStub containsSearchString:searchString];
            
            if(found) {
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    
                    if([searchString isEqualToString:[searchField stringValue]] == NO) {
                        //rNSLog(@"-- discard results for %@", searchString);
                        [op cancel];
                        return;
                    }
                    
                    if([searchResults containsObject:classStub]) return;
                    
                    [searchResults addObject:classStub];
                    
                    searchResultsNode.children = searchResults;
                    
                    NSString *rootTitle = [NSString stringWithFormat:@"\"%@\": %d classes, searching...", searchString, [searchResults count]];
                    [classBrowser setTitle:rootTitle ofColumn:0];
                    
                    [classBrowser loadColumnZero];
                }];
            }
        }];
        
    }
    
    [op setCompletionBlock:^{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            if([searchString isEqualToString:[searchField stringValue]] == NO) {
                NSLog(@"-- discard all results for %@", searchString);
                return;
            }
            
            NSLog(@"-- finished searching for %@, %ul results", searchString, [searchResults count]);
            
            NSString *rootTitle = [NSString stringWithFormat:@"\"%@\": %d classes", searchString, [searchResults count]];
            [classBrowser setTitle:rootTitle ofColumn:0];
            
        }];
    }];
    
    [searchQueue addOperation:op];
    [op release];
    
    [segmentedControl setEnabled:!isInSearchMode forSegment:0];
    [segmentedControl setEnabled:!isInSearchMode forSegment:2];
    
    [self changeViewTypeTo:RBBrowserViewTypeList];
}

#pragma mark NSDraggingDestination

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    
	NSPasteboard *pboard = [sender draggingPasteboard];
	
	if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *paths = [pboard propertyListForType:NSFilenamesPboardType];
		
		for(NSString *path in paths) {
			NSString *ext = [[path lastPathComponent] pathExtension];
			if([[self acceptableExtensions] containsObject:ext]) return NSDragOperationLink;
		}
	}
	
	return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    
    NSPasteboard *pboard = [sender draggingPasteboard];
    
	if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		//NSLog(@"-- files: %@", files);
        
		NSPredicate *p = [NSPredicate predicateWithBlock: ^BOOL(id obj, NSDictionary *bind) {
			NSString *ext = [[obj lastPathComponent] pathExtension];
            return [[self acceptableExtensions] containsObject:ext];
        }];
        
		NSArray *bundlePaths = [files filteredArrayUsingPredicate:p];
        
        NSMutableArray *bundleURLs = [NSMutableArray arrayWithCapacity:[bundlePaths count]];
        
        for(NSString *path in bundlePaths) {
            NSURL *url = [NSURL fileURLWithPath:path];
            [bundleURLs addObject:url];
        }
        
		//NSLog(@"-- bundlesToOpen: %@", bundlesToOpen);
		[self loadBundlesURLs:bundleURLs];
        
    }
    return YES;
}

#pragma mark NSTextViewDelegate

- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRanges:(NSArray *)affectedRanges replacementStrings:(NSArray *)replacementStrings {
    return replacementStrings == nil; // let the user change the font, but not change the text
}

#pragma mark delegate methods
#pragma mark -

- (void)windowWillClose:(NSNotification *)notification {
	[NSApp terminate:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {	
	[NSFont setUserFixedPitchFont:[NSFont fontWithName:@"Menlo Regular" size:11]];
}

- (void)awakeFromNib {
	[super awakeFromNib];
    
    //    SInt32 MacVersion;
    //    
    //    if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr) {
    //        canUseLionAPIs = MacVersion >= 0x1070;
    //    }
    //
    //    NSLog(@"-- canUseLionAPIs: %d", canUseLionAPIs);
    //    
    //    if(canUseLionAPIs) {
    //        [mainWindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
    //
    //    //    [mainWindow setRestorable:YES];
    //    //    [mainWindow setRestorationClass:[mainWindow class]];
    //        
    //        [[NSProcessInfo processInfo] setAutomaticTerminationSupportEnabled: YES];
    //    }
    
	[mainWindow registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
	
	[classBrowser setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
	[classBrowser setAllowsMultipleSelection:YES];
	
	[classBrowser setRowHeight:18];
	[classBrowser setAutohidesScroller:YES];
	[classBrowser setCellClass:[BrowserCell class]];
	
    [headerTextView setFont:[NSFont userFixedPitchFontOfSize:11.0]]; // TODO -- make size and font a default
    
	RBBrowserViewType viewType = [[NSUserDefaults standardUserDefaults] integerForKey:@"ViewType"];
	[self changeViewTypeTo:viewType];
}

- (void)cellClickedAction:(id)sender {
	
	NSBrowserCell *cell = [sender selectedCell];
	if(cell == nil) {
		[label setStringValue:@""];
		[headerTextView setString:@""];
		return;
	}
	
    NSIndexPath *ip = [classBrowser selectionIndexPath];
	id item = [classBrowser itemAtIndexPath:ip];
	
    [classBrowser setTitle:[item nodeInfo] ofColumn:[ip length]];    
    
    if([item isKindOfClass:[BrowserNode class]]) {
		[label setStringValue:[item nodeName]];
		[headerTextView setString:@""];
        return;
	}
    
    NSString *classname = [[sender selectedCell] stringValue];
    Class klass = nil;
	
    if ([classname length]) {
		[label setStringValue:[NSString stringWithFormat:@"%@.h", classname]];
		
		klass = NSClassFromString(classname);
    }
	
	if(klass == nil) {
		[label setStringValue:[NSString stringWithFormat:@"%@.h", classname]];
		[headerTextView setString:[NSString stringWithFormat:@"can't load class with name: %@", classname]];
		return;
	}
	
	ClassDisplay *classDisplay = [ClassDisplay classDisplayWithClass:klass];
	classDisplay.displayPropertiesDefaultValues = [[NSUserDefaults standardUserDefaults] boolForKey:@"displayPropertiesDefaultValues"];
    NSString *header = [classDisplay header];
	
    [headerTextView setString:header];
	
	[headerTextView setTextColor:[NSColor blackColor]];
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"colorizeHeaderFile"]) {
		[headerTextView colorizeWithKeywords:keywords classes:classes];
	}
    
    /* highlight search string */
    
    // TODO: highlight each occurrence
    
    NSString *searchString = [searchField stringValue];
    if([searchString length] > 0) {
        NSRange range = [header rangeOfString:searchString options:NSCaseInsensitiveSearch];
        if(range.location != NSNotFound) {
            [headerTextView scrollRangeToVisible:range];
			[headerTextView showFindIndicatorForRange:range];
        }
    }
    
	/*
	 NSMutableSet *protocols = [NSMutableSet set];
	 NSMutableSet *classnames = [NSMutableSet set];
	 
	 for(ClassStub *cs in [allClasses sortedClassStubs]) {
	 [protocols addObjectsFromArray:[cs protocolsTokens]];
	 [classnames addObject:[[cs stubClassname] lowercaseString]];
	 }
	 
	 [protocols intersectSet:classnames];
	 
	 NSLog(@"-- %@", protocols);
	 */
}

#pragma mark NSBrowserDelegate

- (BrowserNode *)rootItemForBrowser:(NSBrowser *)browser {
	RBBrowserViewType viewType = [[NSUserDefaults standardUserDefaults] integerForKey:@"ViewType"];
	
	NSString *searchString = [searchField stringValue];
	if([searchString length] > 0) {
        return searchResultsNode;
	}
	
	if(viewType == RBBrowserViewTypeList)   return [BrowserNode rootNodeList];
	if(viewType == RBBrowserViewTypeTree)   return [BrowserNode rootNodeTree];
	if(viewType == RBBrowserViewTypeImages) return [BrowserNode rootNodeImages];
	return nil;
}

- (NSInteger)browser:(NSBrowser *)browser numberOfChildrenOfItem:(id)item {
	return [[item children] count];
}

- (id)browser:(NSBrowser *)browser child:(NSInteger)index ofItem:(id)item {
	return [[item children] objectAtIndex:index];
}

- (BOOL)browser:(NSBrowser *)browser isLeafItem:(id)item {
	RBBrowserViewType viewType = [[NSUserDefaults standardUserDefaults] integerForKey:@"ViewType"];
	
    if(viewType == RBBrowserViewTypeList) return YES;
    if(viewType == RBBrowserViewTypeTree) return [[item children] count] == 0;
    if(viewType == RBBrowserViewTypeImages) return [item isKindOfClass:[ClassStub class]];
    
    return YES;    
}

- (id)browser:(NSBrowser *)browser objectValueForItem:(id)item {
	return [item nodeName];
}

#pragma mark ** Dragging Source Methods **

/*
 This method is called after it has been determined that a drag should begin, but before the drag has been started.
 To refuse the drag, return NO.
 To start a drag, declared the pasteboard types that you support with [pasteboard declareTypes:owner:], place your data on the pasteboard, and return YES from the method.
 The drag image and other drag related information will be set up and provided by the view once this call returns with YES.
 You need to implement this method for your browser to be a drag source. 
 */
- (BOOL)browser:(NSBrowser *)browser writeRowsWithIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)column toPasteboard:(NSPasteboard *)pasteboard {
	[pasteboard declareTypes:[NSArray arrayWithObject:NSFilesPromisePboardType] owner:self];
	[pasteboard setPropertyList:[NSArray arrayWithObject:@"h"] forType:NSFilesPromisePboardType];
	return YES;
}

/*
 The delegate can support file promise drags by adding NSFilesPromisePboardType to the pasteboard in browser:writeRowsWithIndexes:inColumn:toPasteboard:.
 NSBrowser implements -namesOfPromisedFilesDroppedAtDestination: to return the results of this data source method.
 This method should returns an array of filenames for the created files (filenames only, not full paths).
 The URL represents the drop location.
 For more information on file promise dragging, see documentation on the NSDraggingSource protocol and -namesOfPromisedFilesDroppedAtDestination:.
 You do not need to implement this method for your browser to be a drag source.
 */

- (NSArray *)browser:(NSBrowser *)aBrowser namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)column {
    
	NSArray *selectedIndexPaths = [classBrowser selectionIndexPaths];
	
	NSMutableArray *selectedItems = [NSMutableArray array];
	
	for(NSIndexPath *ip in selectedIndexPaths) {
		id item = [classBrowser itemAtIndexPath:ip];
		[selectedItems addObject:item];
	}
	
	NSLog(@"dragging items: %@", selectedItems);
	
	NSMutableArray *filenames = [NSMutableArray array];
	
	NSString *directoryPath = [dropDestination path];
    
	for(id item in selectedItems) {
		if([item isKindOfClass:[ClassStub class]]) {
			ClassStub *cs = (ClassStub *)item;
			
			NSString *filename = [[cs stubClassname] stringByAppendingPathExtension:@"h"];
			NSString *path = [directoryPath stringByAppendingPathComponent:filename];
			
			[cs writeAtPath:path];
			
			[filenames addObject:filename];
			
		} else if ([item isKindOfClass:[BrowserNode class]]) {
			
			BrowserNode *bn = (BrowserNode *)item;
			
			directoryPath = [directoryPath stringByAppendingPathComponent:[[bn nodeName] lastPathComponent]];
			
			NSError *error = nil;
			BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:&error];
            
			if(success == NO) {
				[[NSAlert alertWithError:error] runModal];
				break;
			}
			
			for(ClassStub *cs in [bn children]) {
                
				NSString *filename = [[cs stubClassname] stringByAppendingPathExtension:@"h"];
				NSString *path = [directoryPath stringByAppendingPathComponent:filename];
                
				[cs writeAtPath:path];
				[filenames addObject:filename];				
			}
			
		} else {
			NSLog(@"-- cannot handle item: %@", item);
		}
	}	
	
	return filenames;
}

/*
 Allows the delegate to compute a dragging image for the particular cells being dragged.
 'rowIndexes' are the indexes of the cells being dragged in the matrix in 'column'.
 'event' is a reference to the mouse down event that began the drag.
 'dragImageOffset' is an in/out parameter.
 This method will be called with dragImageOffset set to NSZeroPoint, but it can be modified to re-position the returned image.
 A dragImageOffset of NSZeroPoint will cause the image to be centered under the mouse.
 You can safely call [browser dragImageForRowsWithIndexes:inColumn:withEvent:offset:] from inside this method.
 You do not need to implement this method for your browser to be a drag source.
 You can safely call the corresponding NSBrowser method.
 */
- (NSImage *)browser:(NSBrowser *)browser draggingImageForRowsWithIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)column withEvent:(NSEvent *)event offset:(NSPointPointer)dragImageOffset {
    
    NSIndexPath *ip = [classBrowser selectionIndexPath];
	id item = [classBrowser itemAtIndexPath:ip];
    
	if([item isKindOfClass:[ClassStub class]]) {
		return [[NSWorkspace sharedWorkspace] iconForFileType:@"public.c-header"];
	} else if([item isKindOfClass:[BrowserNode class]]) {
		BrowserNode *bn = (BrowserNode *)item;
		return [bn icon];
	} else {
		NSLog(@"-- cannot handle item: %@", item);
	}
	
	return nil;	
}

@end
