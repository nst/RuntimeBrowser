//
//  ObjectWithMethodsViewController.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 11.06.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "RTBObjectsTVC.h"
#import "ClassDisplay.h"
#import "RTBMethodCell.h"

@implementation RTBObjectsTVC

- (void)setObject:(id)o {
	
	//NSLog(@"-- setObject: %@", o);
	
//	[object autorelease];
//	[o retain];
	_object = o;
	
	self.methods = [NSMutableArray array];
	[self.tableView reloadData];

	if(_object == nil) return;
	
	@try {
		NSArray *m = nil;
	
		ClassDisplay *cd = [ClassDisplay classDisplayWithClass:[_object class]];

		if(_object == [_object class]) {
			m = [cd methodLinesWithSign:'+'];
		} else {
			m = [cd methodLinesWithSign:'-'];
		}
		
		self.methods = [NSMutableArray arrayWithArray:[[m lastObject] componentsSeparatedByString:@"\n"]];
		
		if ([[_methods lastObject] isEqualToString:@""]) {
			[_methods removeObjectAtIndex:[_methods count]-1];
		}		
	} @catch (NSException * e) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[e name]
														message:[e reason]
													   delegate:nil 
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil]; 
		[alert show]; 
	} @finally {
		[self.tableView reloadData];
	}	
}

- (void)viewWillAppear:(BOOL)animated {	
	
    [super viewWillAppear:animated];
    
	if(!_object) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No class!" 
														message:@"Open a class header file\nand you'll be able to use it."
													   delegate:nil 
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil]; 
		[alert show]; 
		
		return;
	}
	
	
	self.title = [_object description];
	
	//Class metaCls = object->isa;
    //self.methods = [object rb_classMethods];	
}
/*
- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}
*/

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [_methods count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"MethodCell";
	
	RTBMethodCell *cell = (RTBMethodCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if(cell == nil) {
		cell = (RTBMethodCell *)[[[NSBundle mainBundle] loadNibNamed:@"RTBMethodCell" owner:self options:nil] lastObject];
	}
	
	// Set up the cell
	NSString *method = [_methods objectAtIndex:indexPath.row];
	cell.textLabel.text = [method substringToIndex:[method length]-1]; // remove terminating ';'
	BOOL hasParameters = [method rangeOfString:@":"].location != NSNotFound;
	cell.textLabel.textColor = hasParameters ? [UIColor grayColor] : [UIColor blackColor];
	cell.accessoryType = hasParameters ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if(indexPath.row > ([_methods count]-1) ) return;
	
	NSString *method = [_methods objectAtIndex:indexPath.row];

	BOOL hasParameters = [method rangeOfString:@":"].location != NSNotFound;

	if(hasParameters) return;
	
	NSRange range = [method rangeOfString:@")"]; // return type
	
	if(range.location == NSNotFound) return;
	
	NSString *t = [method substringWithRange:NSMakeRange(3, range.location-3)];
	
	range = NSMakeRange(range.location+1, [method length]-range.location-2);
	
	method = [method substringWithRange:range];
	
	if([method isEqualToString:@"dealloc"]) {
		[self.navigationController popViewControllerAnimated:YES];
	}

	RTBObjectsTVC *ovc = [[RTBObjectsTVC alloc] init];
	
	SEL selector = NSSelectorFromString(method);
	
	if(![_object respondsToSelector:selector]) {
		return;
	}
		
	if([t hasPrefix:@"struct"]) return;

	id o = nil;
	
	@try {
        if([_object respondsToSelector:selector]) {
            o = [_object performSelector:selector];
        }
	} @catch (NSException * e) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[e name]
														message:[e reason]
													   delegate:nil 
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil]; 
		[alert show]; 
	} @finally {
		
	}

	if ([t isEqualToString:@"void"]) return;
	
	if(![t isEqualToString:@"id"]) {
		if([t isEqualToString:@"NSInteger"] || [t isEqualToString:@"NSUInteger"] || [t hasSuffix:@"int"]) {
			o = [NSString stringWithFormat:@"%d", o];			
		} else if([t isEqualToString:@"double"] || [t isEqualToString:@"float"]) {
			o = [NSString stringWithFormat:@"%f", o];			
		} else if([t isEqualToString:@"BOOL"]) {
			o = o ? @"YES" : @"NO";			
		} else {
			o = [NSString stringWithFormat:@"%d", o]; // default
		}
	}		
	
	if([o isKindOfClass:[NSString class]] || [o isKindOfClass:[NSArray class]] || [o isKindOfClass:[NSDictionary class]] || [o isKindOfClass:[NSSet class]]) {
		NSLog(@"-- %@", o);
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" 
														message:[o description] 
													   delegate:nil 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil]; 
		[alert show]; 
		
		return;
	}
	
	ovc.object = o;
	
	[self.navigationController pushViewController:ovc animated:YES];
}

@end
