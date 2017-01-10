//
//  FrameworksTableViewController.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 01.09.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import "RTBFrameworksTVC.h"
#import "RTBFrameworkCell.h"
#import "RTBRuntime.h"
#import "RTBListTVC.h"
#import "RTBInfoVC.h"

static const NSUInteger kPublicFrameworks = 0;
static const NSUInteger kPrivateFrameworks = 1;

@implementation RTBFrameworksTVC

//- (IBAction)showInfo:(id)sender {
//    
//    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
//    RTBInfoVC *infoVC = (RTBInfoVC *)[sb instantiateViewControllerWithIdentifier:@"RTBInfoVC"];
//    
//    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:infoVC];
//    [self presentViewController:navigationController animated:YES completion:nil];
//}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == kPublicFrameworks) return @"Public Frameworks";
    if(section == kPrivateFrameworks) return @"Private Frameworks";
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == kPublicFrameworks) {
        return [_filteredPublicFrameworks count];
    } else if (section == kPrivateFrameworks) {
        return [_filteredPrivateFrameworks count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    RTBFrameworkCell *cell = (RTBFrameworkCell *)[tableView dequeueReusableCellWithIdentifier:@"RTBFrameworkCell"];
    
    NSBundle *b = nil;
    
    if(indexPath.section == kPublicFrameworks) {
        b = [_filteredPublicFrameworks objectAtIndex:indexPath.row];
    } else {
        b = [_filteredPrivateFrameworks objectAtIndex:indexPath.row];
    }
    
    NSString *name = [[[b bundlePath] lastPathComponent] stringByDeletingPathExtension];
    
    cell.frameworkName = name;
    
    cell.accessoryType = [b isLoaded] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSBundle *b = nil;
    if(indexPath.section == kPublicFrameworks) {
        b = [_filteredPublicFrameworks objectAtIndex:indexPath.row];
    } else {
        b = [_filteredPrivateFrameworks objectAtIndex:indexPath.row];
    }
    
    NSString *bundlePath = [b bundlePath];
    NSString *name = [[bundlePath lastPathComponent] stringByDeletingPathExtension];
    
    if([b isLoaded] == NO) {
        
        NSError *error = nil;
        BOOL success = [b loadAndReturnError:&error];
        
        if(success == NO || [b isLoaded] == NO) {
            NSString *alertTitle = [NSString stringWithFormat:@"Error: could not load %@.", name];
            NSString *alertMessage = error ? [error localizedFailureReason] : @"The framework could not be loaded.";
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:alertTitle
                                                            message:alertMessage
                                                           delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            return;
        }
        
        [tableView reloadData];
        [_allClasses emptyCachesAndReadAllRuntimeClasses];
    }
    
    NSString *imageName = [[bundlePath lastPathComponent] stringByDeletingPathExtension];
    NSString *imagePath = [bundlePath stringByAppendingPathComponent:imageName];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    RTBListTVC *listTVC = (RTBListTVC *)[sb instantiateViewControllerWithIdentifier:@"RTBListTVC"];
    NSArray *allStubsInImage = [_allClasses.allClassStubsByImagePath valueForKey:imagePath];
    if(allStubsInImage == nil)
        allStubsInImage = [NSArray array];
    listTVC.classStubs = [allStubsInImage sortedArrayUsingSelector:@selector(compare:)];
    listTVC.titleForNavigationItem = name;
    
    [self.navigationController pushViewController:listTVC animated:YES];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
	NSString *filter = [searchController.searchBar.text lowercaseString];
	if ([filter length] != 0) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            return [[[[[evaluatedObject bundlePath] lastPathComponent] stringByDeletingPathExtension] lowercaseString] containsString:filter];
        }];
        self.filteredPublicFrameworks = [self.publicFrameworks filteredArrayUsingPredicate:predicate];
        self.filteredPrivateFrameworks = [self.privateFrameworks filteredArrayUsingPredicate:predicate];
    } else {
        self.filteredPublicFrameworks = self.publicFrameworks;
        self.filteredPrivateFrameworks = self.privateFrameworks;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (IBAction)loadAllFrameworks:(id)sender {
    _alertView = [[UIAlertView alloc] init];
    _alertView.title = @"Loading All Frameworks";
    _alertView.message = nil;
    
    _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(20.0, 60.0, 245.0, 9.0)];
    _progressView.progress = 0.0;
    [_alertView addSubview:_progressView];
    [_alertView show];
    
    __weak typeof(self) weakSelf = self;
    
    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if(strongSelf == nil) return;
        
        NSArray *allFrameworks = [strongSelf.publicFrameworks arrayByAddingObjectsFromArray:strongSelf.privateFrameworks];
        allFrameworks = [allFrameworks arrayByAddingObjectsFromArray:strongSelf.bundleFrameworks];
        
        NSUInteger count = 0;
        NSUInteger total = [allFrameworks count];
        
        for(NSBundle *b in allFrameworks) {
            
#if TARGET_IPHONE_SIMULATOR
            if([[b bundlePath] isEqualToString:@"/System/Library/PrivateFrameworks/Safari.framework"]) {
                NSLog(@"-- skip /System/Library/PrivateFrameworks/Safari.framework, known to be a crasher on simulator");
                continue;
            }
#endif
            
            count++;
            float percent = (float)count / (float)total;
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if(strongSelf == nil) return;
                
                strongSelf.progressView.progress = percent;
            }];
            
            @try {
                //NSLog(@"-- %@", b);
                NSError *loadError = nil;
                BOOL success = [b loadAndReturnError:&loadError];
                if(success == NO) {
                    //NSLog(@"-- couln't load %@", b);
                    NSLog(@"-- [ERROR] %@", [loadError localizedDescription]);
                }
            } @catch (NSException * e) {
                NSLog(@"-- exception while loading bundle %@", b);
            } @finally {
            }
        }
    }];
    
    [op setCompletionBlock:^{
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if(strongSelf == nil) return;
            
            [strongSelf.alertView dismissWithClickedButtonIndex:0 animated:YES];
            
            [strongSelf.allClasses emptyCachesAndReadAllRuntimeClasses];
            
            [strongSelf.tableView reloadData];
            
            //			[self.navigationController.navigationItem setRightBarButtonItem:nil animated:YES];
        }];
    }];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:op];
}

- (NSArray *)frameworksAtPath:(NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *c = [fm contentsOfDirectoryAtPath:path error:&error];
    if(c == nil) NSLog(@"-- %@", error);
    
    NSMutableArray *ma = [NSMutableArray array];
    for(NSString *s in c) {
        if([[s pathExtension] isEqualToString:@"framework"]) {
            NSBundle *b = [NSBundle bundleWithPath:[path stringByAppendingPathComponent:s]];
            if(b) [ma addObject:b];
        }
    }
    
    return ma;
}

- (NSArray *)loadedBundleFrameworks {
    NSArray *bundles = [NSBundle allFrameworks];
    NSMutableArray *a = [NSMutableArray array];
    for(NSBundle *b in bundles) {
        if([b isLoaded]) {
            [a addObject:b];
        }
    }
    return a;
}

- (void)setPublicFrameworks:(NSArray *)publicFrameworks {
	_publicFrameworks = publicFrameworks;
	_filteredPublicFrameworks = publicFrameworks;
	[self updateSearchResultsForSearchController:self.searchController];
}

- (void)setPrivateFrameworks:(NSArray *)privateFrameworks {
	_privateFrameworks = privateFrameworks;
	_filteredPrivateFrameworks = privateFrameworks;
	[self updateSearchResultsForSearchController:self.searchController];
}

- (void)viewDidLoad {
    self.title = @"Frameworks";
    
    self.allClasses = [RTBRuntime sharedInstance];
    
    self.bundleFrameworks = [self loadedBundleFrameworks];
    
    self.privateFrameworks = [self frameworksAtPath:@"/System/Library/PrivateFrameworks"];
    self.publicFrameworks = [self frameworksAtPath:@"/System/Library/Frameworks"];
	
	self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	self.definesPresentationContext = YES;
	self.searchController.searchResultsUpdater = self;
	self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
	self.tableView.tableHeaderView = self.searchController.searchBar;
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

//- (void)viewWillDisappear:(BOOL)animated {
//}
//
//- (void)viewDidDisappear:(BOOL)animated {
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end

