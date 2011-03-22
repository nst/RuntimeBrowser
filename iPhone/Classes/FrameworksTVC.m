//
//  FrameworksTableViewController.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 01.09.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

#import "FrameworksTVC.h"
#import "FrameworkCell.h"
#import "AllClasses.h"
#import "ListTVC.h"

static const NSUInteger kPublicFrameworks = 0;
static const NSUInteger kPrivateFrameworks = 1;

@implementation FrameworksTVC

@synthesize publicFrameworks;
@synthesize privateFrameworks;
@synthesize bundleFrameworks;
@synthesize allClasses;

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
		return [publicFrameworks count];
	} else if (section == kPrivateFrameworks) {
		return [privateFrameworks count];
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *frameworkCellIdentifier = @"FrameworkCell";
	
	FrameworkCell *cell = (FrameworkCell *)[tableView dequeueReusableCellWithIdentifier:frameworkCellIdentifier];
	if(cell == nil) {
		cell = (FrameworkCell *)[[[NSBundle mainBundle] loadNibNamed:@"FrameworkCell" owner:self options:nil] lastObject];
	}
	
	NSBundle *b = nil;
	
	if(indexPath.section == kPublicFrameworks) {
		b = [publicFrameworks objectAtIndex:indexPath.row];
	} else {
		b = [privateFrameworks objectAtIndex:indexPath.row];
	}
	
	NSString *name = [[[b bundlePath] lastPathComponent] stringByDeletingPathExtension];
	// Configure the cell
	cell.label.text = name;
	cell.accessoryType = [b isLoaded] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSBundle *b = nil;
	if(indexPath.section == kPublicFrameworks) {
		b = [publicFrameworks objectAtIndex:indexPath.row];
	} else {
		b = [privateFrameworks objectAtIndex:indexPath.row];
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
			[alert release];
			return;
		}
		
		[tableView reloadData];
		[allClasses emptyCachesAndReadAllRuntimeClasses];
	}
	
	NSString *imageName = [[bundlePath lastPathComponent] stringByDeletingPathExtension];
	NSString *imagePath = [bundlePath stringByAppendingPathComponent:imageName];
	
	ListTVC *listTVC = [[ListTVC alloc] initWithNibName:@"ListTVC" bundle:nil];
	NSArray *allStubsInImage = [allClasses.allClassStubsByImagePath valueForKey:imagePath];
	if(allStubsInImage == nil)
		allStubsInImage = [NSArray array];
	listTVC.classStubs = [allStubsInImage sortedArrayUsingSelector:@selector(compare:)];
	listTVC.frameworkName = name;

	[self.navigationController pushViewController:listTVC animated:YES];
	[listTVC release];
}

- (void)dealloc {
	[publicFrameworks release];
	[privateFrameworks release];
	[bundleFrameworks release];
	[super dealloc];
}

- (IBAction)loadAllFrameworks:(id)sender {
	alertView = [[UIAlertView alloc] init];
	alertView.title = @"Loading All Frameworks";
	alertView.message = nil;
	
	progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(20.0, 60.0, 245.0, 9.0)];
	progressView.progress = 0.0;
	[alertView addSubview:progressView];
	[alertView show];
	
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		NSArray *allFrameworks = [publicFrameworks arrayByAddingObjectsFromArray:privateFrameworks];
		allFrameworks = [allFrameworks arrayByAddingObjectsFromArray:bundleFrameworks];
		
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
				progressView.progress = percent;
			}];
			
			@try {
				//			NSLog(@"-- %@", b);
				BOOL success = [b load];
				if(success == NO) NSLog(@"-- couln't load %@", b);
			} @catch (NSException * e) {
				NSLog(@"-- exception while loading bundle %@", b);
			} @finally {
			}
		}
	}];
	
	[op setCompletionBlock:^{
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			[alertView dismissWithClickedButtonIndex:0 animated:YES];
			[alertView release];
			
			[allClasses emptyCachesAndReadAllRuntimeClasses];
			
			[self.tableView reloadData];
			
			[progressView release];
			
			//			[self.navigationController.navigationItem setRightBarButtonItem:nil animated:YES];
		}];
	}];
	
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	[queue addOperation:op];
	[queue release];
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
	NSMutableArray *a = [[NSMutableArray alloc] init];
	for(NSBundle *b in bundles) {
		if([b isLoaded]) {
			[a addObject:b];
		}
	}
	return [a autorelease];
}

- (void)viewDidLoad {
	self.title = @"Frameworks";
	
	self.allClasses = [AllClasses sharedInstance];
	
	self.bundleFrameworks = [self loadedBundleFrameworks];
	
	self.privateFrameworks = [self frameworksAtPath:@"/System/Library/PrivateFrameworks"];
	self.publicFrameworks = [self frameworksAtPath:@"/System/Library/Frameworks"];
	
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
}

- (void)viewDidDisappear:(BOOL)animated {
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

@end

