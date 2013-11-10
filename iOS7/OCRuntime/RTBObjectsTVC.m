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

// Shmoopi's Addition
#import "UIAlertView+Blocks.h"

@interface RTBObjectsTVC () {
    NSMutableArray *paramsToAdd, *paramsToRemove;
}

@end

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
            if (m.count == 1) {
                m = [NSArray arrayWithObject:[NSString stringWithFormat:@"%@%@", [m objectAtIndex:0], @"+ (id)alloc;\n"]];
            }
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
	
	// (sometimes fails to get the description)
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
	
    RTBMethodCell *cell = (RTBMethodCell *)[tableView dequeueReusableCellWithIdentifier:@"RTBMethodCell"];
    
    if (!cell) {
        cell = [[RTBMethodCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"RTBMethodCell"];
    }
    
	// Set up the cell
	NSString *method = [_methods objectAtIndex:indexPath.row];
	cell.textLabel.text = [method substringToIndex:[method length]-1]; // remove terminating ';'
	BOOL hasParameters = [method rangeOfString:@":"].location != NSNotFound;
	cell.textLabel.textColor = [UIColor blackColor];
	cell.accessoryType = hasParameters ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
    // Get the method name to highlight different methods
    NSRange range = [method rangeOfString:@")"]; // return type
    
    // Verify the location of the )
    if(range.location == NSNotFound) return cell;
	
    // Get the return type
	NSString *returnType = [method substringWithRange:NSMakeRange(3, range.location-3)];
    
    range = NSMakeRange(range.location+1, [method length]-range.location-2);
	method = [method substringWithRange:range];
    
    // Check which method type it is
    if ([method isEqualToString:@"alloc"]) {
        // Show blue
        cell.textLabel.textColor = [UIColor blueColor];
    } else if ([returnType hasPrefix:@"void"]  && !hasParameters && ([method isEqualToString:@".cxx_destruct"] || [method isEqualToString:@"dealloc"])) {
        // Show orange
        cell.textLabel.textColor = [UIColor orangeColor];
    }
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if(indexPath.row > ([_methods count]-1) ) return;
	
	NSString *method = [_methods objectAtIndex:indexPath.row];

	BOOL hasParameters = [method rangeOfString:@":"].location != NSNotFound;

    // Check if the method has parameters
	if (hasParameters) {
        // We have some parameters to fill!
        
        NSMutableArray *params = [[NSMutableArray alloc] init];
        
        // Get all instances of the parameters we'd like to fill
        NSUInteger length = [method length];
        NSRange range = NSMakeRange(0, length);
        while (range.location != NSNotFound) {
            range = [method rangeOfString:@":" options:NSCaseInsensitiveSearch range:range];
            if (range.location != NSNotFound) {
                range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
                
                // Make a string of the arg number
                NSString *argNumber = [NSString stringWithFormat:@"arg%d", params.count + 1];
                
                // Check to see if we have a space or a semi colon to separate the arguments
                if ([method rangeOfString:argNumber options:NSCaseInsensitiveSearch range:range].location == NSNotFound) {
                    // Didn't find the arg
                    [params addObject:@"Unknown Argument"];
                    
                } else {
                    // Create a substring that can be used from that
                    NSRange toSlash = NSMakeRange(range.location, ([method rangeOfString:argNumber options:NSCaseInsensitiveSearch range:range].location - range.location) + argNumber.length);
                    NSString *subStringfromBingo = [method substringWithRange:toSlash];
                    
                    // Add the parameters
                    [params addObject:subStringfromBingo];
                }
            }
        }
        
        for (NSString *objects in [params reverseObjectEnumerator]) {
            // Need to fill in the parameters to run the argument
            [UIAlertView rtb_displayAlertWithTitle:objects
                                       message:method
                               leftButtonTitle:@"Cancel"
                              leftButtonAction:^{
                                  // Add nil parameter to the parameters array
                                  
                                  // If this is the first object, clear the array
                                  if ([params.firstObject isEqualToString:objects]) {
                                      paramsToAdd = nil;
                                      paramsToRemove = nil;
                                  }
                                  
                                  // Verify the paramsArray
                                  if (paramsToAdd == nil) {
                                      paramsToAdd = [[NSMutableArray alloc] init];
                                  }
                                  
                                  // Verify the paramsRemoveArray
                                  if (paramsToRemove == nil) {
                                      paramsToRemove = [[NSMutableArray alloc] init];
                                  }
                                  
                                  // Add the objects to the params
                                  [paramsToAdd addObject:@""];
                                  [paramsToRemove addObject:objects];
                              }
                              rightButtonTitle:@"Enter"
                             rightButtonAction:^(NSString *output){
                                 // Add this parameter to the parameters array
                                 
                                 // If this is the first object, clear the array
                                 if ([params.firstObject isEqualToString:objects]) {
                                     paramsToAdd = nil;
                                     paramsToRemove = nil;
                                 }
                                 
                                 // Verify the paramsArray
                                 if (paramsToAdd == nil) {
                                     paramsToAdd = [[NSMutableArray alloc] init];
                                 }
                                 
                                 // Verify the paramsRemoveArray
                                 if (paramsToRemove == nil) {
                                     paramsToRemove = [[NSMutableArray alloc] init];
                                 }
                                 
                                 // Verify the output
                                 if (output.length < 1 || output == nil || [output isEqualToString:@"nil"] || [output isEqualToString:@"NULL"] || [output isEqualToString:@""] || [output isEqualToString:@"null"] || [output isEqualToString:@"0"]) {
                                     // Pass nil
                                     output = @"";
                                 }
                                 
                                 // Create the output based on the type
                                 NSUInteger bracketEnd = [objects rangeOfString:@")" options:NSCaseInsensitiveSearch].location;
                                 NSRange typeRange = NSMakeRange(1, bracketEnd - 1);
                                 NSString *typeParam = [objects substringWithRange:typeRange];
                                 
                                 // int
                                 if ([typeParam isEqualToString:@"int"]) {
                                    [paramsToAdd addObject:[NSNumber numberWithInt:[output intValue]]];
                                 }
                                 // Bool
                                 else if ([typeParam isEqualToString:@"BOOL"]) {
                                     [paramsToAdd addObject:[NSNumber numberWithBool:[output boolValue]]];
                                 }
                                 // Otherwise
                                 else {
                                     // Add the objects to the params
                                     [paramsToAdd addObject:output];
                                 }
                                 
                                 // Add the removable param
                                 [paramsToRemove addObject:objects];
                                 
                                 // Check if this is the last parameter in the method
                                 if ([params.lastObject isEqualToString:objects]) {
                                     // Yes
                                     // Pass the parameters in the array and run them through the obj
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         // On main thread
                                         [self performFunction:method withObjects:paramsToAdd removing:paramsToRemove];
                                     });
                                 }
                             }];
        }
        
        return;
    }
	
	NSRange range = [method rangeOfString:@")"]; // return type
	
	if(range.location == NSNotFound) return;
	
	NSString *t = [method substringWithRange:NSMakeRange(3, range.location-3)];
	
	range = NSMakeRange(range.location+1, [method length]-range.location-2);
	
	method = [method substringWithRange:range];
	
	if([method isEqualToString:@"dealloc"]) {
		[self.navigationController popViewControllerAnimated:YES];
        return;
	}

	RTBObjectsTVC *ovc = [[RTBObjectsTVC alloc] init];
	
	SEL selector = NSSelectorFromString(method);
	
	if(![_object respondsToSelector:selector]) {
		return;
	}
    
	if([t hasPrefix:@"struct"]) return;

	id o = nil;
    
    NSParameterAssert(selector != NULL);
    NSParameterAssert([_object respondsToSelector:selector]);
    
    NSMethodSignature* methodSig = [_object methodSignatureForSelector:selector];
    if(methodSig == nil) {
        NSLog(@"Invalid Method Signature for class: %@ and selector: %@", _object, NSStringFromSelector(selector));
        return;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    
    // Check to see if it's alloc
    if ([method isEqualToString:@"alloc"]) {
        // Alloc and init the class
        
        o = [_object performSelector:selector];
        
        id theOb = o;
        
        // Verify we can init it
        if ([o respondsToSelector:NSSelectorFromString(@"init")]) {
            
            theOb = [o performSelector:NSSelectorFromString(@"init")];
            
        }
        
        ovc.object = theOb;
        
        [self.navigationController pushViewController:ovc animated:YES];
        
        return;
    }
    
    // Figure out the return type for the selector
    const char* retType = [methodSig methodReturnType];
    
    // Do a try and catch block to prevent the app from crashing
    @try {
        // Allow the object to perform the selector if it's of certain types
        if(strcmp(retType, @encode(id)) == 0) {
            
            o = [_object performSelector:selector];
            
        } else if (strcmp(retType, @encode(BOOL)) == 0) {
            // BOOL
            BOOL b = (BOOL)[_object performSelector:selector];
            o = [NSNumber numberWithBool:b];
        } else if (strcmp(retType, @encode(void)) == 0) {
            [_object performSelector:selector];
        } else if (strcmp(retType, @encode(int)) == 0) {
            int i = (int)[_object performSelector:selector];
            o = [NSNumber numberWithInt:i];
        } else {
            NSLog(@"-[%@ performSelector:@selector(%@)] shouldn't be used. The selector doesn't return an object or void", _object, NSStringFromSelector(selector));
            return;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception!  Broke this:  %@", exception);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
														message:[exception description]
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
    }
    
#pragma clang diagnostic pop

    // Verify the output is good
    if (o == NULL || o == nil) {
        // o is empty
        NSLog(@"Output is empty");
        o = @"NULL";
    }
    
    /*
	if([_object respondsToSelector:selector]) {
        o = [_object performSelector:selector];
    }
     
	@try {
        
	} @catch (NSException * e) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[e name]
														message:[e reason]
													   delegate:nil 
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil]; 
		[alert show]; 
	} @finally {
		
	}
    */
	
	if(![t isEqualToString:@"id"]) {
		if([t isEqualToString:@"NSInteger"] || [t isEqualToString:@"NSUInteger"] || [t hasSuffix:@"int"]) {
			o = [NSString stringWithFormat:@"%d", (int)o];
		} else if([t isEqualToString:@"double"] || [t isEqualToString:@"float"]) {
			o = [NSString stringWithFormat:@"%f", o];
		} else if([t isEqualToString:@"BOOL"]) {
			o = ([o boolValue]) ? @"YES" : @"NO";
		} else if ([t isEqualToString:@"void"]) {
            o = @"Completed";
        } else {
			o = [NSString stringWithFormat:@"%d",(int) o]; // default
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

- (void)performFunction:(NSString *)method withObjects:(NSMutableArray *)parameters removing:(NSMutableArray *)removing {
    NSRange range = [method rangeOfString:@")"]; // return type
	
	if(range.location == NSNotFound) return;
	
	NSString *t = [method substringWithRange:NSMakeRange(3, range.location-3)];
	
	range = NSMakeRange(range.location+1, [method length]-range.location-2);
	
	method = [method substringWithRange:range];
	
	if([method isEqualToString:@"dealloc"]) {
		[self.navigationController popViewControllerAnimated:YES];
        return;
	}
    
    // Remove all the args and return parameters from the method
    for (NSString *removables in removing) {
        method = [method stringByReplacingOccurrencesOfString:removables withString:@""];
    }
    // Remove all the strings from the method
    method = [method stringByReplacingOccurrencesOfString:@" " withString:@""];
    
	RTBObjectsTVC *ovc = [[RTBObjectsTVC alloc] init];
	
	SEL selector = NSSelectorFromString(method);
	
	if(![_object respondsToSelector:selector]) {
		return;
	}
    
	if([t hasPrefix:@"struct"]) return;
    
	id o = nil;
    
    NSParameterAssert(selector != NULL);
    NSParameterAssert([_object respondsToSelector:selector]);
    
    NSMethodSignature* methodSig = [_object methodSignatureForSelector:selector];
    if(methodSig == nil) {
        NSLog(@"Invalid Method Signature for class: %@ and selector: %@", _object, NSStringFromSelector(selector));
        return;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    
    // Check to see if it's alloc
    if ([method isEqualToString:@"alloc"]) {
        // Alloc and init the class
        o = [_object performSelector:selector];
        
        id theOb = o;
        
        // Verify we can init it
        if ([o respondsToSelector:NSSelectorFromString(@"init")]) {
            theOb = [o performSelector:NSSelectorFromString(@"init")];
        }
        
        ovc.object = theOb;
        
        [self.navigationController pushViewController:ovc animated:YES];
        
        return;
    }

#pragma clang diagnostic pop

    // Figure out the return type for the selector
    const char* retType = [methodSig methodReturnType];
    
    // Do a try and catch block to prevent the app from crashing
    @try {
        // Allow the object to perform the selector if it's of certain types
        if(strcmp(retType, @encode(id)) == 0) {
            // id
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[_object methodSignatureForSelector:selector]];
            [inv setSelector:selector];
            [inv setTarget:_object];
            
            for (int x = 0;x < parameters.count;x++) {
                // Determine the type of input
                if ([[removing objectAtIndex:x] rangeOfString:@"BOOL"].location != NSNotFound) {
                    // BOOL
                    BOOL obj;
                    if ([[parameters objectAtIndex:x] isEqualToString:@""]) {
                        obj = false;
                    } else if ([[parameters objectAtIndex:x] isEqualToString:@"true"]) {
                        obj = true;
                    } else if ([[parameters objectAtIndex:x] isEqualToString:@"false"]) {
                        obj = false;
                    } else if ([[parameters objectAtIndex:x] isEqualToString:@"yes"]) {
                        obj = false;
                    } else if ([[parameters objectAtIndex:x] isEqualToString:@"no"]) {
                        obj = false;
                    }  else {
                        obj = [[parameters objectAtIndex:x] boolValue];
                    }
                    [inv setArgument:&obj atIndex:(x + 2)];
                } else if ([[removing objectAtIndex:x] rangeOfString:@"int"].location != NSNotFound) {
                    // int
                    int obj = [[parameters objectAtIndex:x] integerValue];
                    [inv setArgument:&obj atIndex:(x + 2)];
                } else if ([[removing objectAtIndex:x] rangeOfString:@"id"].location != NSNotFound) {
                    // id
                    id obj;
                    if ([[parameters objectAtIndex:x] isEqualToString:@""]) {
                        obj = nil;
                    } else {
                        obj = [parameters objectAtIndex:x];
                    }
                    [inv setArgument:&obj atIndex:(x + 2)];
                } else {
                    // Something else
                    id obj;
                    if ([[parameters objectAtIndex:x] isEqualToString:@""]) {
                        obj = nil;
                    } else {
                        obj = [parameters objectAtIndex:x];
                    }
                    [inv setArgument:&obj atIndex:(x + 2)];
                }
            }
            
            [inv retainArguments];
            
            id result;
            [inv invoke];
            [inv getReturnValue:&result];
            if (result) {
                o = result;
            }
        } else if (strcmp(retType, @encode(BOOL)) == 0) {
            // BOOL
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[_object methodSignatureForSelector:selector]];
            [inv setSelector:selector];
            [inv setTarget:_object];
            
            for (int x = 0;x < parameters.count;x++) {
                // Determine the type of input
                if ([[removing objectAtIndex:x] rangeOfString:@"BOOL"].location != NSNotFound) {
                    // BOOL
                    BOOL obj;
                    if ([[parameters objectAtIndex:x] isEqualToString:@""]) {
                        obj = false;
                    } else if ([[parameters objectAtIndex:x] isEqualToString:@"true"]) {
                        obj = true;
                    } else if ([[parameters objectAtIndex:x] isEqualToString:@"false"]) {
                        obj = false;
                    } else if ([[parameters objectAtIndex:x] isEqualToString:@"yes"]) {
                        obj = false;
                    } else if ([[parameters objectAtIndex:x] isEqualToString:@"no"]) {
                        obj = false;
                    }  else {
                        obj = [[parameters objectAtIndex:x] boolValue];
                    }
                    [inv setArgument:&obj atIndex:(x + 2)];
                } else if ([[removing objectAtIndex:x] rangeOfString:@"int"].location != NSNotFound) {
                    // int
                    int obj = [[parameters objectAtIndex:x] integerValue];
                    [inv setArgument:&obj atIndex:(x + 2)];
                } else if ([[removing objectAtIndex:x] rangeOfString:@"id"].location != NSNotFound) {
                    // id
                    id obj;
                    if ([[parameters objectAtIndex:x] isEqualToString:@""]) {
                        obj = nil;
                    } else {
                        obj = [parameters objectAtIndex:x];
                    }
                    [inv setArgument:&obj atIndex:(x + 2)];
                } else {
                    // Something else
                    id obj;
                    if ([[parameters objectAtIndex:x] isEqualToString:@""]) {
                        obj = nil;
                    } else {
                        obj = [parameters objectAtIndex:x];
                    }
                    [inv setArgument:&obj atIndex:(x + 2)];
                }
            }
            
            [inv retainArguments];
            
            id result;
            [inv invoke];
            [inv getReturnValue:&result];
            if (result) {
                BOOL b = (BOOL)result;
                o = [NSNumber numberWithBool:b];
            }
        } else if (strcmp(retType, @encode(void)) == 0) {
            // void
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[_object methodSignatureForSelector:selector]];
            [inv setSelector:selector];
            [inv setTarget:_object];
            
            for (int x = 0;x < parameters.count;x++) {
                // Determine the type of input
                if ([[removing objectAtIndex:x] rangeOfString:@"BOOL"].location != NSNotFound) {
                    // BOOL
                    BOOL obj = [[parameters objectAtIndex:x] boolValue];
                    [inv setArgument:&obj atIndex:(x + 2)];
                } else if ([[removing objectAtIndex:x] rangeOfString:@"int"].location != NSNotFound) {
                    // int
                    int obj = [[parameters objectAtIndex:x] integerValue];
                    [inv setArgument:&obj atIndex:(x + 2)];
                } else if ([[removing objectAtIndex:x] rangeOfString:@"id"].location != NSNotFound) {
                    // id
                    id obj;
                    if ([[parameters objectAtIndex:x] isEqualToString:@""]) {
                        obj = nil;
                    } else {
                        obj = [parameters objectAtIndex:x];
                    }
                    [inv setArgument:&obj atIndex:(x + 2)];
                } else {
                    // Something else
                    id obj;
                    if ([[parameters objectAtIndex:x] isEqualToString:@""]) {
                        obj = nil;
                    } else {
                        obj = [parameters objectAtIndex:x];
                    }
                    [inv setArgument:&obj atIndex:(x + 2)];
                }
            }
            
            [inv retainArguments];
            [inv invoke];
        } else if (strcmp(retType, @encode(int)) == 0) {
            // int
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[_object methodSignatureForSelector:selector]];
            [inv setSelector:selector];
            [inv setTarget:_object];
            
            for (int x = 0;x < parameters.count;x++) {
                // Determine the type of input
                if ([[removing objectAtIndex:x] rangeOfString:@"BOOL"].location != NSNotFound) {
                    // BOOL
                    BOOL obj;
                    if ([[parameters objectAtIndex:x] isEqualToString:@""]) {
                        obj = false;
                    } else if ([[parameters objectAtIndex:x] isEqualToString:@"true"]) {
                        obj = true;
                    } else if ([[parameters objectAtIndex:x] isEqualToString:@"false"]) {
                        obj = false;
                    } else if ([[parameters objectAtIndex:x] isEqualToString:@"yes"]) {
                        obj = false;
                    } else if ([[parameters objectAtIndex:x] isEqualToString:@"no"]) {
                        obj = false;
                    }  else {
                        obj = [[parameters objectAtIndex:x] boolValue];
                    }
                    [inv setArgument:&obj atIndex:(x + 2)];
                } else if ([[removing objectAtIndex:x] rangeOfString:@"int"].location != NSNotFound) {
                    // int
                    int obj = [[parameters objectAtIndex:x] integerValue];
                    [inv setArgument:&obj atIndex:(x + 2)];
                } else if ([[removing objectAtIndex:x] rangeOfString:@"id"].location != NSNotFound) {
                    // id
                    id obj;
                    if ([[parameters objectAtIndex:x] isEqualToString:@""]) {
                        obj = nil;
                    } else {
                        obj = [parameters objectAtIndex:x];
                    }
                    [inv setArgument:&obj atIndex:(x + 2)];
                } else {
                    // Something else
                    id obj;
                    if ([[parameters objectAtIndex:x] isEqualToString:@""]) {
                        obj = nil;
                    } else {
                        obj = [parameters objectAtIndex:x];
                    }
                    [inv setArgument:&obj atIndex:(x + 2)];
                }
            }
            
            [inv retainArguments];
            
            CFTypeRef result;
            [inv invoke];
            [inv getReturnValue:&result];
            if (result) {
                CFRetain(result);
                int i = (int)result;
                o = [NSNumber numberWithInt:i];
            }
        } else {
            NSLog(@"-[%@ performSelector:@selector(%@)] shouldn't be used. The selector doesn't return an object or void", _object, NSStringFromSelector(selector));
            return;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception!  Broke this:  %@", exception);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
														message:[exception description]
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
    }
    
    // Verify the output is good
    if (o == NULL || o == nil) {
        // o is empty
        NSLog(@"Output is empty");
        o = @"NULL";
    }
    
    /*
     if([_object respondsToSelector:selector]) {
     o = [_object performSelector:selector];
     }
     
     @try {
     
     } @catch (NSException * e) {
     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[e name]
     message:[e reason]
     delegate:nil
     cancelButtonTitle:@"OK"
     otherButtonTitles:nil];
     [alert show];
     } @finally {
     
     }
     */
	
	if(![t isEqualToString:@"id"]) {
		if([t isEqualToString:@"NSInteger"] || [t isEqualToString:@"NSUInteger"] || [t hasSuffix:@"int"]) {
			o = [NSString stringWithFormat:@"%d", (int)o];
		} else if([t isEqualToString:@"double"] || [t isEqualToString:@"float"]) {
			o = [NSString stringWithFormat:@"%f", o];
		} else if([t isEqualToString:@"BOOL"]) {
			o = ([o boolValue]) ? @"YES" : @"NO";
		} else if ([t isEqualToString:@"void"]) {
            o = @"Completed";
        } else {
			o = [NSString stringWithFormat:@"%d", (int)o]; // default
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
