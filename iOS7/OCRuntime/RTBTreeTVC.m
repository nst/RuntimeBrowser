//
//  RTBTreeTVC.m
//  OCRuntime
//
//  Created by Nicolas Seriot on 7/17/13.
//  Copyright (c) 2013 Nicolas Seriot. All rights reserved.
//

#import "RTBTreeTVC.h"
#import "AllClasses.h"
#import "RTBClassCell.h"
#import "ClassStub.h"
#import "RTBClassDisplayVC.h"
#import "RTBInfoVC.h"

@interface RTBTreeTVC ()

@end

@implementation RTBTreeTVC

- (RTBClassDisplayVC *)classDisplayVC {
	if(_classDisplayVC == nil) {
		self.classDisplayVC = [[RTBClassDisplayVC alloc] initWithNibName:@"ClassDisplayVC" bundle:nil];
	}
	return _classDisplayVC;
}

- (IBAction)showInfo:(id)sender {
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    RTBInfoVC *infoVC = (RTBInfoVC *)[sb instantiateViewControllerWithIdentifier:@"RTBInfoVC"];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:infoVC];
	[self presentViewController:navigationController animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.allClasses = [AllClasses sharedInstance];
	if(!_isSubLevel) {
		self.classStubs = [_allClasses rootClassStubs:ClassStubClass];
        self.protocolStubs = [_allClasses rootClassStubs:ClassStubProtocol];
//		self.title = @"Tree";
		self.navigationItem.title = @"Root Classes";
	}
}

- (void)viewDidUnload {
	self.classDisplayVC = nil;
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
	if(!_isSubLevel) {
		self.classStubs = [_allClasses rootClassStubs:ClassStubAll]; // classes might have changed because of dynamic loading
	}
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)showHeader:(id)sender {
    NSLog(@"-- showHeader:%@", sender);
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return [_classStubs count];
    else
        return [_protocolStubs count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return @"Classes";
    else
        return @"Protocols";
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    RTBClassCell *cell = (RTBClassCell *)[tableView dequeueReusableCellWithIdentifier:@"RTBClassCell"];
    
	// Set up the cell
    ClassStub *cs;
    if (indexPath.section == 0)
        cs = [_classStubs objectAtIndex:indexPath.row];
    else
        cs = [_protocolStubs objectAtIndex:indexPath.row];
    
//    cell.imageView.image = [UIImage imageNamed:@"header.png"];
//    cell.button.imageView.image = [UIImage imageNamed:@"header.png"];
    cell.classStub = cs;
    //cell.className = cs.stubClassname;
	cell.accessoryType = [[cs subclassesStubs] count] > 0 ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ClassStub *cs;
    if (indexPath.section == 0)
        cs = [_classStubs objectAtIndex:indexPath.row];
    else
        cs = [_protocolStubs objectAtIndex:indexPath.row];
	
	if([[cs subclassesStubs] count] == 0) return;
	
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    RTBTreeTVC *tvc = (RTBTreeTVC *)[sb instantiateViewControllerWithIdentifier:@"RTBTreeTVC"];
    tvc.isSubLevel = YES;
    
    NSMutableArray *classes = [NSMutableArray array];
    NSMutableArray *protocols = [NSMutableArray array];
    for (ClassStub *sub in [cs subclassesStubs]) {
        if (sub.isProtocol)
            [protocols addObject:sub];
        else
            [classes addObject:sub];
    }
	tvc.classStubs = classes;
    tvc.protocolStubs = protocols;
    
	tvc.title = cs.stubClassname;
	[self.navigationController pushViewController:tvc animated:YES];
}

#pragma mark - Navigation

//// In a story board-based application, you will often want to do a little preparation before navigation
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    // Get the new view controller using [segue destinationViewController].
//    // Pass the selected object to the new view controller.
//}

@end
