//
//  RTBProtocolsTVC.m
//  OCRuntime
//
//  Created by Nicolas Seriot on 27/04/15.
//  Copyright (c) 2015 Nicolas Seriot. All rights reserved.
//

#import "RTBProtocolsTVC.h"
#import "RTBProtocol.h"
#import "RTBProtocolCell.h"
#import "RTBRuntime.h"
#import "RTBListTVC.h"

@interface RTBProtocolsTVC ()

@end

@implementation RTBProtocolsTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.protocolStubs = [[RTBRuntime sharedInstance] sortedProtocolStubs];
    
    [self setupIndexedClassStubs];
}

- (void)setupIndexedClassStubs {
    
    __weak typeof(self) weakSelf = self;
    
    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if(strongSelf == nil) return;
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if(strongSelf == nil) return;
            
            strongSelf.navigationItem.title = [NSString stringWithFormat:@"All Protocols (%d)", [strongSelf.protocolStubs count]];
        }];
        
        NSMutableArray *ma = [[NSMutableArray alloc] init];
        
        unichar firstLetter = 0;
        unichar currentLetter = 0;
        NSMutableArray *currentLetterProtocolStubs = [[NSMutableArray alloc] init];
        
        for(RTBProtocol *p in strongSelf.protocolStubs) {
            if([p.protocolName length] < 1) continue;
            
            firstLetter = [p.protocolName characterAtIndex:0];
            
            if(currentLetter == 0) {
                currentLetter = firstLetter;
            }
            
            BOOL letterChange = firstLetter != currentLetter;
            
            if(letterChange) {
                NSDictionary *d = [NSDictionary dictionaryWithObject:currentLetterProtocolStubs
                                                              forKey:[NSString stringWithFormat:@"%c", currentLetter]];
                [ma addObject:d];
                currentLetterProtocolStubs = [[NSMutableArray alloc] init];
                currentLetter = firstLetter;
            }
            
            [currentLetterProtocolStubs addObject:p];
            
            if(p == [strongSelf.protocolStubs lastObject]) {
                NSDictionary *d = [NSDictionary dictionaryWithObject:currentLetterProtocolStubs
                                                              forKey:[NSString stringWithFormat:@"%c", currentLetter]];
                [ma addObject:d];
            }
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if(strongSelf == nil) return;
            
            strongSelf.protocolStubsDictionaries = ma;
        }];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if(strongSelf == nil) return;
            
            [strongSelf.tableView reloadData];
        }];
        
    }];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:op];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_protocolStubsDictionaries count] ? [_protocolStubsDictionaries count] : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section >= [_protocolStubsDictionaries count]) return 0;
    
    NSDictionary *d = [_protocolStubsDictionaries objectAtIndex:section];
    return [[[d allValues] lastObject] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RTBProtocolCell *cell = (RTBProtocolCell *)[tableView dequeueReusableCellWithIdentifier:@"RTBProtocolCell"];

    if (!cell) {
        cell = [[RTBProtocolCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"RTBProtocolCell"];
    }
    
    NSDictionary *d = [_protocolStubsDictionaries objectAtIndex:indexPath.section];
    NSArray *protocols = [[d allValues] lastObject];
    
    RTBProtocol *p = [protocols objectAtIndex:indexPath.row];
    cell.protocolObject = p;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSDictionary *d = [_protocolStubsDictionaries objectAtIndex:indexPath.section];
    NSArray *protocols = [[d allValues] lastObject];
    RTBProtocol *p = [protocols objectAtIndex:indexPath.row];
    
    NSArray *children = [p children];
    
    if([children count] == 0) return;

    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    RTBListTVC *listTVC = (RTBListTVC *)[sb instantiateViewControllerWithIdentifier:@"RTBListTVC"];
    listTVC.titleForNavigationItem = p.protocolName;
    listTVC.classStubs = children;
    
    [self.navigationController pushViewController:listTVC animated:YES];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
