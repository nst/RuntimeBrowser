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
#import "RTBRuntime.h"
#import "NSString+SyntaxColoring.h"
#import "BrowserNode.h"
#import "BrowserCell.h"
#import "RTBClass.h"
#import "RTBRuntimeHeader.h"
#import "RTBProtocol.h"

@interface AppController ()
@property (nonatomic, strong) NSMutableDictionary *cachedClassStubsMatchingForSearchStringLowercase;
@end

@implementation AppController

+ (void)thisClassIsPartOfTheRuntimeBrowser {}

- (instancetype)init {
    self = [super init];
    if(self == nil) return nil;

    NSString *keywordsPath = [[NSBundle mainBundle] pathForResource:@"Keywords" ofType:@"plist"];
    self.keywords = [NSArray arrayWithContentsOfFile:keywordsPath];

    self.allClasses = [RTBRuntime sharedInstance];

    NSString *defaultsPath = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

    return self;
}

- (BOOL)saveAsHeaderIsEnabled {
    id item = [_classBrowser itemAtIndexPath:[_classBrowser selectionIndexPath]];
    return [item canBeSavedAsHeader];
}

- (RBBrowserViewType)currentViewType {
    return (RBBrowserViewType)[[NSUserDefaults standardUserDefaults] integerForKey:@"RTBViewType"];
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
        [self.allClasses emptyCachesAndReadAllRuntimeClasses]; // TODO: read only classes from bundles instead of everything
        [_classBrowser loadColumnZero];

        [_label setStringValue:@"Select a Class"];
        [_headerTextView setString:@""];

        if([self currentViewType] == RBBrowserViewTypeImages) {
            NSString *rootTitle = [NSString stringWithFormat:@"%lu images", (unsigned long)[[self.allClasses allClassStubsByImagePath] count]];
            [_classBrowser setTitle:rootTitle ofColumn:0];
        }

        self.cachedClassStubsMatchingForSearchStringLowercase = nil;
    }
}

- (void)application:(NSApplication *)application openURLs:(NSArray<NSURL *> *)urls {
    [self loadBundlesURLs:urls];
}

- (NSArray *)acceptableExtensions {
    return @[@"dylib", @"framework", @"bundle", @"app"];
}

- (IBAction)openAction:(id)sender {

    NSOpenPanel *oPanel = [NSOpenPanel openPanel];

    [oPanel setAllowsMultipleSelection:YES];
    [oPanel setCanChooseDirectories:YES];
    [oPanel setCanChooseFiles:YES];

    [oPanel beginSheetModalForWindow:self.mainWindow completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            [self loadBundlesURLs:[oPanel URLs]];
        }
    }];
}

- (IBAction)saveAction:(id)sender {

    NSString *className = [[_classBrowser selectedCell] stringValue];
    if ([className length] == 0) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Select a class before saving.";
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        return;
    }

    NSSavePanel *sp = [NSSavePanel savePanel];
    [sp setDirectoryURL:self.saveDirURL];
    [sp setAllowedFileTypes:@[@"h"]];
    [sp setNameFieldStringValue:className];

    __weak typeof(self) weakSelf = self;

    [sp beginSheetModalForWindow:[_classBrowser window] completionHandler:^(NSModalResponse result) {

        __strong typeof(weakSelf) strongSelf = weakSelf;
        if(strongSelf == nil) return;

        if ( result != NSModalResponseOK ) return;

        NSString *fileContents = [strongSelf.headerTextView string];
        NSURL *fileURL = [sp URL];

        NSError *error = nil;
        [[NSProcessInfo processInfo] disableSuddenTermination];

        BOOL success = [fileContents writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:&error];
        [[NSProcessInfo processInfo] enableSuddenTermination];

        if (success) {
            strongSelf.saveDirURL = [fileURL URLByDeletingLastPathComponent];
        } else {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"Save Failed :( !";
            alert.informativeText = [NSString stringWithFormat:@"Please try again, perhaps selecting a different file/directory. Error: %@", error];
            [alert addButtonWithTitle:@"OK"];
            [alert beginSheetModalForWindow:strongSelf.mainWindow completionHandler:nil];
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

    __weak typeof(self) weakSelf = self;

    [sp beginSheetModalForWindow:[_classBrowser window] completionHandler:^(NSModalResponse result) {

        if ( result != NSModalResponseOK ) return;

        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [queue addOperationWithBlock:^{

            __strong typeof(weakSelf) strongSelf = weakSelf;
            if(strongSelf == nil) return;

            NSUInteger saved = 0;
            NSUInteger failed = 0;
            NSURL *dirURL = [sp URL];

            NSArray *classNames = [[[strongSelf.allClasses allClassStubsByName] allKeys] copy];

            [[NSProcessInfo processInfo] disableSuddenTermination];

            for(NSString *className in classNames) {
                NSString *filename = [NSString stringWithFormat:@"%@.h", className];
                NSURL *url = [dirURL URLByAppendingPathComponent:filename];

                BOOL displayPropertiesDefaultValues = [[NSUserDefaults standardUserDefaults] boolForKey:@"RTBDisplayPropertiesDefaultValues"];
                NSString *header = [RTBRuntimeHeader headerForClass:NSClassFromString(className) displayPropertiesDefaultValues:displayPropertiesDefaultValues];

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

            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"Save All Finished";
                alert.informativeText = [NSString stringWithFormat:@"Done saving all classes into %@. \n  %lu classes saved. \n  %lu classes failed to save.", [dirURL path], (unsigned long)saved, (unsigned long)failed];
                [alert addButtonWithTitle:@"OK"];
                [alert beginSheetModalForWindow:strongSelf.mainWindow completionHandler:nil];
            }];
        }];
    }];
}

- (BOOL)validateMenuItem:(NSMenuItem *)aMenuItem {
    if ( [[aMenuItem title] isEqualToString:@"Save As..."] )
        return ( [[[_classBrowser selectedCell] stringValue] length] != 0 );
    return YES;
}

- (BOOL)shouldShowDisclosureIndicatorOnClasses {
    return [self currentViewType] == RBBrowserViewTypeTree;
}

- (BOOL)isInSearchMode {
    return [[_searchField stringValue] length] > 0;
}

- (void)changeViewTypeTo:(RBBrowserViewType)viewType {
    [[NSUserDefaults standardUserDefaults] setInteger:viewType forKey:@"RTBViewType"];
    
    NSUInteger nbOfColumns = 1;
    if(viewType == RBBrowserViewTypeImages) nbOfColumns = 2;
    if(viewType == RBBrowserViewTypeTree) nbOfColumns = 3;
    if(viewType == RBBrowserViewTypeProtocols) nbOfColumns = 2;
    [_classBrowser setMaxVisibleColumns:nbOfColumns];
    
    NSBrowserColumnResizingType resizingType = viewType == RBBrowserViewTypeTree ? NSBrowserUserColumnResizing : NSBrowserAutoColumnResizing;
    [_classBrowser setColumnResizingType:resizingType];
    
    [_classBrowser loadColumnZero];
    
    id rootItem = [self rootItemForBrowser:_classBrowser];
    
    NSString *rootTitle = @"";
    if(viewType == RBBrowserViewTypeList) {
        rootTitle = [NSString stringWithFormat:@"%lu Classes", (unsigned long)[[rootItem children] count]];
        
        if([self isInSearchMode]) {
            rootTitle = @"No classes found";
        }
    }
    
    if(viewType == RBBrowserViewTypeTree)   rootTitle = [NSString stringWithFormat:@"%lu Root Classes", (unsigned long)[[rootItem children] count]];
    if(viewType == RBBrowserViewTypeImages) rootTitle = [NSString stringWithFormat:@"%lu Images", (unsigned long)[[rootItem children] count]];
    if(viewType == RBBrowserViewTypeProtocols) rootTitle = [NSString stringWithFormat:@"%lu Protocols", (unsigned long)[[rootItem children] count]];
    
    [_label setStringValue:@""];
    [_headerTextView setString:@""];
    
    [_classBrowser setTitle:rootTitle ofColumn:0];
}

- (IBAction)changeViewTypeFromSegmentedControl:(NSSegmentedControl *)sender {
    RBBrowserViewType viewType = (RBBrowserViewType)sender.selectedSegment;
    if(viewType != RBBrowserViewTypeList) [_searchField setStringValue:@""];

    [self changeViewTypeTo:viewType];
}

- (IBAction)changeViewTypeFromMenuItem:(NSMenuItem *)sender {
    RBBrowserViewType viewType = (RBBrowserViewType)[sender tag];

    if([self isInSearchMode]) {
        if(viewType != RBBrowserViewTypeList) [_searchField setStringValue:@""];
        [self.segmentedControl setEnabled:YES forSegment:0];
        [self.segmentedControl setEnabled:YES forSegment:2];
    }

    [self changeViewTypeTo:viewType];
}

- (void)foundMatchingClass:(RTBClass *)classStub forSearchString:(NSString *)searchString {
    
    NSString *searchStringLowercase = [searchString lowercaseString];
    
    if(_cachedClassStubsMatchingForSearchStringLowercase == nil) {
        self.cachedClassStubsMatchingForSearchStringLowercase = [NSMutableDictionary dictionary];
    }
    
    if(_cachedClassStubsMatchingForSearchStringLowercase[searchStringLowercase] == nil) {
        _cachedClassStubsMatchingForSearchStringLowercase[searchStringLowercase] = [NSMutableSet set];
    }
    
    [_cachedClassStubsMatchingForSearchStringLowercase[searchStringLowercase] addObject:classStub];
    
    /**/
    
    if([self.searchResults containsObject:classStub]) return;
    
    [self.searchResults addObject:classStub];
    
    self.searchResultsNode.children = self.searchResults;
    
    NSString *rootTitle = [NSString stringWithFormat:@"\"%@\": %lu classes, searching...", searchString, (unsigned long)[self.searchResults count]];
    [self.classBrowser setTitle:rootTitle ofColumn:0];
    
    [self.classBrowser loadColumnZero];
    
}

- (void)didFinishSearchingForString:(NSString *)searchString {
    if([searchString isEqualToString:[self.searchField stringValue]] == NO) {
        NSLog(@"-- discard all results for %@", searchString);
        return;
    }
    
    NSLog(@"-- finished searching for %@, %lul results", searchString, (unsigned long)[self.searchResults count]);
    
    NSString *rootTitle = [NSString stringWithFormat:@"\"%@\": %lu classes", searchString, (unsigned long)[self.searchResults count]];
    [self.classBrowser setTitle:rootTitle ofColumn:0];
}

- (IBAction)search:(id)sender {

    BOOL isInSearchMode = [self isInSearchMode];

    [self.searchQueue cancelAllOperations];

    [self.segmentedControl setEnabled:!isInSearchMode forSegment:0];
    [self.segmentedControl setEnabled:!isInSearchMode forSegment:2];
    [self.segmentedControl setEnabled:!isInSearchMode forSegment:3];

    if(isInSearchMode == NO) {
        [self changeViewTypeTo:RBBrowserViewTypeList];
        return;
    }

    self.searchResults = [NSMutableArray array];

    self.searchResultsNode = [[BrowserNode alloc] init];

    NSString *searchString = [[_searchField stringValue] copy];

    NSArray *classStubs = [[RTBRuntime sharedInstance] sortedClassStubs];

    // lookup in search caches
    NSString *searchStringLowercase = [searchString lowercaseString];

    if(_cachedClassStubsMatchingForSearchStringLowercase[searchStringLowercase]) {

        NSSet *set = _cachedClassStubsMatchingForSearchStringLowercase[searchStringLowercase];
        NSMutableArray *ma = [[set allObjects] mutableCopy];
        [ma sortUsingSelector:@selector(compare:)];

        self.searchResults = ma;
        self.searchResultsNode.children = self.searchResults;

        [self.classBrowser loadColumnZero];
        [self didFinishSearchingForString:searchString];

        return;
    }

    self.searchQueue = [[NSOperationQueue alloc] init];

    NSBlockOperation *op = [[NSBlockOperation alloc] init];

    __weak NSBlockOperation *weakOp = op;
    __weak typeof(self) weakSelf = self;

    [op addExecutionBlock:^{

        __strong NSBlockOperation *strongOp = weakOp;
        if(strongOp == nil || [strongOp isCancelled]) return;

        __strong typeof(weakSelf) strongSelf = weakSelf;
        if(strongSelf == nil) return;

        for (RTBClass *classStub in classStubs) {

            if(![classStub containsSearchString:searchString]) continue;

            [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                __strong typeof(weakSelf) innerSelf = weakSelf;
                if(innerSelf == nil) return;

                if([searchString isEqualToString:[innerSelf.searchField stringValue]] == NO) {
                    [strongOp cancel];
                    return;
                }

                [innerSelf foundMatchingClass:classStub forSearchString:searchString];
            }];
        }
    }];

    [op setCompletionBlock:^{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if(strongSelf == nil) return;
            [strongSelf didFinishSearchingForString:searchString];
        }];
    }];

    [self.searchQueue addOperation:op];

    [self changeViewTypeTo:RBBrowserViewTypeList];
}

#pragma mark NSDraggingDestination

- (NSArray<NSURL *> *)acceptableFileURLsFromPasteboard:(NSPasteboard *)pboard {
    NSArray<NSURL *> *urls = [pboard readObjectsForClasses:@[[NSURL class]]
                                                   options:@{NSPasteboardURLReadingFileURLsOnlyKey: @YES}];
    NSArray *acceptable = [self acceptableExtensions];
    NSPredicate *p = [NSPredicate predicateWithBlock:^BOOL(NSURL *url, NSDictionary *bind) {
        return [acceptable containsObject:[url pathExtension]];
    }];
    return [urls filteredArrayUsingPredicate:p];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSArray *urls = [self acceptableFileURLsFromPasteboard:[sender draggingPasteboard]];
    return [urls count] > 0 ? NSDragOperationLink : NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSArray<NSURL *> *urls = [self acceptableFileURLsFromPasteboard:[sender draggingPasteboard]];
    if([urls count] > 0) {
        [self loadBundlesURLs:urls];
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

    [self.mainWindow registerForDraggedTypes:@[NSPasteboardTypeFileURL]];

    [_classBrowser setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
    [_classBrowser setAllowsMultipleSelection:YES];

    [_classBrowser setRowHeight:20];
    [_classBrowser setAutohidesScroller:YES];
    [_classBrowser setCellClass:[BrowserCell class]];

    [_headerTextView setFont:[NSFont userFixedPitchFontOfSize:11.0]]; // TODO -- make size and font a default

    [self changeViewTypeTo:[self currentViewType]];
}

- (void)cellClickedAction:(id)sender {
    
    NSBrowserCell *cell = [sender selectedCell];
    if(cell == nil) {
        [_label setStringValue:@""];
        [_headerTextView setString:@""];
        return;
    }
    
    BOOL colorize = [[NSUserDefaults standardUserDefaults] boolForKey:@"RTBColorizeHeaderFile"];
    
    NSIndexPath *ip = [_classBrowser selectionIndexPath];
    id item = [_classBrowser itemAtIndexPath:ip];
    
    [_classBrowser setTitle:[item nodeInfo] ofColumn:[ip length]];
    
    if([item isKindOfClass:[BrowserNode class]]) {
        [_label setStringValue:[item nodeName]];
        [_headerTextView setString:@""];
        return;
    } else if ([item isKindOfClass:[RTBProtocol class]]) {
        [_label setStringValue:[item nodeName]];
        [_headerTextView setString:@""];
        
        RTBProtocol *protocolStub = (RTBProtocol *)item;
        NSString *header = [RTBRuntimeHeader headerForProtocol:protocolStub];

        NSAttributedString *attributedString = [header colorizeWithKeywords:self.keywords classes:self.classes colorize:colorize];
        [[_headerTextView textStorage] setAttributedString:attributedString];

        return;
    }
    
    NSString *classname = [[sender selectedCell] stringValue];
    Class klass = nil;
    
    if ([classname length]) {
        [_label setStringValue:[NSString stringWithFormat:@"%@.h", classname]];
        
        klass = NSClassFromString(classname);
    }
    
    if(klass == nil) {
        [_label setStringValue:[NSString stringWithFormat:@"%@.h", classname]];
        [_headerTextView setString:[NSString stringWithFormat:@"can't load class with name: %@", classname]];
        return;
    }
    
    BOOL displayPropertiesDefaultValues = [[NSUserDefaults standardUserDefaults] boolForKey:@"RTBDisplayPropertiesDefaultValues"];
    
    NSString *header = [RTBRuntimeHeader headerForClass:klass displayPropertiesDefaultValues:displayPropertiesDefaultValues];

    NSAttributedString *attributedString = [header colorizeWithKeywords:self.keywords classes:self.classes colorize:colorize];

    [[_headerTextView textStorage] setAttributedString:attributedString];

    // TODO: highlight each occurrence
    NSString *searchString = [_searchField stringValue];
    if([searchString length] > 0) {
        NSRange range = [header rangeOfString:searchString options:NSCaseInsensitiveSearch];
        if(range.location != NSNotFound) {
            [_headerTextView scrollRangeToVisible:range];
            [_headerTextView showFindIndicatorForRange:range];
        }
    }
}

#pragma mark NSBrowserDelegate

- (BrowserNode *)rootItemForBrowser:(NSBrowser *)browser {
    NSString *searchString = [_searchField stringValue];
    if([searchString length] > 0) {
        return self.searchResultsNode;
    }

    switch([self currentViewType]) {
        case RBBrowserViewTypeList:      return [BrowserNode rootNodeList];
        case RBBrowserViewTypeTree:      return [BrowserNode rootNodeTree];
        case RBBrowserViewTypeImages:    return [BrowserNode rootNodeImages];
        case RBBrowserViewTypeProtocols: return [BrowserNode rootNodeProtocols];
    }
    return nil;
}

- (NSInteger)browser:(NSBrowser *)browser numberOfChildrenOfItem:(id)item {
    if([self currentViewType] == RBBrowserViewTypeProtocols && [item isKindOfClass:[RTBClass class]]) return 0;

    return [[item children] count];
}

- (id)browser:(NSBrowser *)browser child:(NSInteger)index ofItem:(id)item {
    return [[item children] objectAtIndex:index];
}

- (BOOL)browser:(NSBrowser *)browser isLeafItem:(id)item {
    switch([self currentViewType]) {
        case RBBrowserViewTypeList:      return YES;
        case RBBrowserViewTypeTree:      return [[item children] count] == 0;
        case RBBrowserViewTypeImages:    return [item isKindOfClass:[RTBClass class]];
        case RBBrowserViewTypeProtocols: return [item isKindOfClass:[RTBProtocol class]] ? [[item children] count] == 0 : YES;
    }
    return YES;
}

- (id)browser:(NSBrowser *)browser objectValueForItem:(id)item {
    return item;
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
    
    NSArray *selectedIndexPaths = [_classBrowser selectionIndexPaths];
    
    NSMutableArray *selectedItems = [NSMutableArray array];
    
    for(NSIndexPath *ip in selectedIndexPaths) {
        id item = [_classBrowser itemAtIndexPath:ip];
        [selectedItems addObject:item];
    }
    
    NSLog(@"dragging items: %@", selectedItems);
    
    NSMutableArray *filenames = [NSMutableArray array];
    
    NSString *directoryPath = [dropDestination path];
    
    for(id item in selectedItems) {
        if([item isKindOfClass:[RTBClass class]]) {
            RTBClass *cs = (RTBClass *)item;
            
            NSString *filename = [[cs classObjectName] stringByAppendingPathExtension:@"h"];
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
            
            for(RTBClass *cs in [bn children]) {
                
                NSString *filename = [[cs classObjectName] stringByAppendingPathExtension:@"h"];
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
    
    NSIndexPath *ip = [_classBrowser selectionIndexPath];
    id item = [_classBrowser itemAtIndexPath:ip];
    
    if([item isKindOfClass:[RTBClass class]]) {
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
