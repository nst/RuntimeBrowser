//
//  ListViewController.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 18.01.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "RTBListTVC.h"
#import "RTBRuntime.h"
#import "RTBClassCell.h"
#import "RTBClass.h"

@interface RTBListTVC ()
@property (nonatomic, strong) NSString *filterStringLowercase;
@end

@implementation RTBListTVC

- (IBAction)dismissModalView:(id)sender {
    [[self navigationController] dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

- (void)setupIndexedClassStubs {
    
    self.navigationItem.title = [NSString stringWithFormat:@"%@ (%lu)", self.titleForNavigationItem, (unsigned long)[self.classStubs count]];
    
    NSMutableArray *ma = [[NSMutableArray alloc] init];
    
    unichar firstLetter = 0;
    unichar currentLetter = 0;
    NSMutableArray *currentLetterClassStubs = [[NSMutableArray alloc] init];
    
    for(RTBClass *cs in self.classStubs) {
        
        if(_filterStringLowercase && [[cs.classObjectName lowercaseString] rangeOfString:_filterStringLowercase].location == NSNotFound) {
            continue;
        }

        firstLetter = [cs.classObjectName characterAtIndex:0];
        
        if(currentLetter == 0) {
            currentLetter = firstLetter;
        }
        
        BOOL letterChange = firstLetter != currentLetter;
        
        if(letterChange) {
            NSDictionary *d = [NSDictionary dictionaryWithObject:currentLetterClassStubs
                                                          forKey:[NSString stringWithFormat:@"%c", currentLetter]];
            [ma addObject:d];
            currentLetterClassStubs = [[NSMutableArray alloc] init];
            currentLetter = firstLetter;
        }
        
        [currentLetterClassStubs addObject:cs];
    }

    NSDictionary *d = [NSDictionary dictionaryWithObject:currentLetterClassStubs
                                                  forKey:[NSString stringWithFormat:@"%c", currentLetter]];
    [ma addObject:d];

    self.classStubsDictionaries = ma;
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"List";
    
    if(self.titleForNavigationItem == nil) {
        self.titleForNavigationItem = @"All Classes";
    }
    
    [super viewDidLoad];
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    
    self.navigationItem.title = self.titleForNavigationItem;
    
    if(_classStubs == nil) {
        self.classStubs = [[RTBRuntime sharedInstance] sortedClassStubs];
    }
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [self setupIndexedClassStubs];
    
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_classStubsDictionaries count] ? [_classStubsDictionaries count] : 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section >= [_classStubsDictionaries count]) return 0;
    
    NSDictionary *d = [_classStubsDictionaries objectAtIndex:section];
    return [[[d allValues] lastObject] count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    RTBClassCell *cell = (RTBClassCell *)[tableView dequeueReusableCellWithIdentifier:@"RTBClassCell"];
    
    if(indexPath.section >= [_classStubsDictionaries count]) {
        cell.textLabel.text = @"";
        cell.accessoryType = UITableViewCellAccessoryNone;
        return cell;
    }
    
    NSDictionary *d = [_classStubsDictionaries objectAtIndex:indexPath.section];
    NSArray *theClassStubs = [[d allValues] lastObject];
    
    RTBClass *cs = [theClassStubs objectAtIndex:indexPath.row];
    cell.className = cs.classObjectName;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    // The header for the section is the region name -- get this from the dictionary at the section index
    if(section >= [_classStubsDictionaries count]) return @"";
    
    NSDictionary *d = [_classStubsDictionaries objectAtIndex:section];
    
    NSString *letter = [[d allKeys] lastObject];
    NSUInteger i = [[[d allValues] lastObject] count];
    return [NSString stringWithFormat:@"%@ (%@)", letter, @(i)];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    /*
     Return the index titles for each of the sections (e.g. "A", "B", "C"...).
     Use key-value coding to get the value for the key @"letter" in each of the dictionaries in list.
     */
    NSMutableArray *a = [[NSMutableArray alloc] init];
    
    for(NSDictionary *d in _classStubsDictionaries) {
        [a addObject:[[d allKeys] lastObject]];
    }
    
    return a;
}

#pragma mark UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText { // called when text changes (including clear)
    
    if([searchText length] > 0) {
        self.filterStringLowercase = searchText;
    } else {
        self.filterStringLowercase = nil;
        
        [searchBar performSelector:@selector(resignFirstResponder)
                        withObject:nil
                        afterDelay:0];
    }
    
    [self setupIndexedClassStubs];
}

@end
