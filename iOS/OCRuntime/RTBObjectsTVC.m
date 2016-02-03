//
//  ObjectWithMethodsViewController.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 11.06.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "RTBObjectsTVC.h"
#import "RTBMethodCell.h"
#import "RTBRuntimeHeader.h"
#import "UIAlertView+Blocks.h"
#import "RTBMethod.h"
#import "RTBRuntime.h"
#import "RTBClass.h"

@interface RTBObjectsTVC ()

@property (nonatomic, strong) NSMutableArray *methodsSections; // [ { 'ClassName':'xxx', 'Methods':[a,b,c,...] }, { 'ClassName':'ParentClass', 'Methods':[a,x,y] } ]
@property (nonatomic, strong) NSMutableArray *paramsToAdd;
@property (nonatomic, strong) NSMutableArray *paramsToRemove;
@property (nonatomic, strong) id object;

@end

@implementation RTBObjectsTVC

- (void)viewDidLoad {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close:)];
    [super viewDidLoad];
}

- (IBAction)close:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

- (void)setInspectedObject:(id)o {
    
    self.object = o;

    self.methodsSections = [NSMutableArray array];

    if(_object == nil) {
        [self.tableView reloadData];
        return;
    }

    BOOL objectIsAClass = _object == [_object class];

    Class c = [_object class];
    
    do {
        RTBClass *classObject = [[RTBRuntime sharedInstance] classStubForClassName:NSStringFromClass(c)];
        NSArray *methods = [classObject sortedMethodsIsClassMethod:objectIsAClass];
        NSDictionary *d = @{ @"ClassName":NSStringFromClass(c), @"Methods":methods };
        [_methodsSections addObject:d];
        c = class_getSuperclass(c);
    } while (c != NULL);
    
    [self.tableView reloadData];
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
    
    [self setInspectedObject:_object];
    
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

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    NSMutableArray *ma = [NSMutableArray array];
    
    for(int i = 0; i < [_methodsSections count]; i++) {
        [ma addObject:[NSString stringWithFormat:@"%d", i]];
    }
    return ma;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *d = _methodsSections[section];
    return d[@"ClassName"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_methodsSections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *d = _methodsSections[section];
    NSArray *methods = d[@"Methods"];
    return [methods count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    RTBMethodCell *cell = (RTBMethodCell *)[tableView dequeueReusableCellWithIdentifier:@"RTBMethodCell"];
    
    if (!cell) {
        cell = [[RTBMethodCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"RTBMethodCell"];
    }
    
    // Set up the cell
    NSDictionary *d = _methodsSections[indexPath.section];
    NSArray *methods = d[@"Methods"];
    RTBMethod *m = methods[indexPath.row];
    
    cell.method = m;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *d = _methodsSections[indexPath.section];
    NSArray *methods = d[@"Methods"];
    RTBMethod *m = methods[indexPath.row];

    NSString *headerDescription = [m headerDescriptionWithNewlineAfterArgs:YES];
    NSArray *argTypes = [m argumentsTypesDecoded];
    
    BOOL hasParameters = [argTypes count] > 2;
    
    if (hasParameters) {
        
        NSMutableArray *params = [NSMutableArray array];
        
        [argTypes enumerateObjectsUsingBlock:^(NSString *argType, NSUInteger idx, BOOL *stop) {
            
            if (idx <= 1) return; // skip id and SEL

            // eg. "(unsigned long)arg1"
            NSString *s = [NSString stringWithFormat:@"(%@)arg%lu", argType, idx-1];
            [params addObject:s];
        }];
        
        __weak typeof(self) weakSelf = self;
        
        for (NSString *objects in [params reverseObjectEnumerator]) {
            // Need to fill in the parameters to run the argument
            [UIAlertView rtb_displayAlertWithTitle:objects
                                           message:headerDescription
                                   leftButtonTitle:@"Cancel"
                                  leftButtonAction:^{
                                      // Add nil parameter to the parameters array
                                      
                                      __strong typeof(weakSelf) strongSelf = weakSelf;
                                      if(strongSelf == nil) return;
                                      
                                      // If this is the first object, clear the array
                                      if ([params.firstObject isEqualToString:objects]) {
                                          strongSelf.paramsToAdd = nil;
                                          strongSelf.paramsToRemove = nil;
                                      }
                                      
                                      // Verify the paramsArray
                                      if (strongSelf.paramsToAdd == nil) {
                                          strongSelf.paramsToAdd = [[NSMutableArray alloc] init];
                                      }
                                      
                                      // Verify the paramsRemoveArray
                                      if (strongSelf.paramsToRemove == nil) {
                                          strongSelf.paramsToRemove = [[NSMutableArray alloc] init];
                                      }
                                      
                                      // Add the objects to the params
                                      [strongSelf.paramsToAdd addObject:@""];
                                      [strongSelf.paramsToRemove addObject:objects];
                                  }
                                  rightButtonTitle:@"Enter"
                                 rightButtonAction:^(NSString *output){
                                     // Add this parameter to the parameters array
                                     
                                     __strong typeof(weakSelf) strongSelf = weakSelf;
                                     if(strongSelf == nil) return;
                                     
                                     // If this is the first object, clear the array
                                     if ([params.firstObject isEqualToString:objects]) {
                                         strongSelf.paramsToAdd = nil;
                                         strongSelf.paramsToRemove = nil;
                                     }
                                     
                                     // Verify the paramsArray
                                     if (strongSelf.paramsToAdd == nil) {
                                         strongSelf.paramsToAdd = [[NSMutableArray alloc] init];
                                     }
                                     
                                     // Verify the paramsRemoveArray
                                     if (strongSelf.paramsToRemove == nil) {
                                         strongSelf.paramsToRemove = [[NSMutableArray alloc] init];
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
                                         [strongSelf.paramsToAdd addObject:[NSNumber numberWithInt:[output intValue]]];
                                     }
                                     // Bool
                                     else if ([typeParam isEqualToString:@"BOOL"]) {
                                         [strongSelf.paramsToAdd addObject:[NSNumber numberWithBool:[output boolValue]]];
                                     }
                                     // Otherwise
                                     else {
                                         // Add the objects to the params
                                         [strongSelf.paramsToAdd addObject:output];
                                     }
                                     
                                     // Add the removable param
                                     [strongSelf.paramsToRemove addObject:objects];
                                     
                                     // Check if this is the last parameter in the method
                                     if ([params.lastObject isEqualToString:objects]) {
                                         // Yes
                                         // Pass the parameters in the array and run them through the obj
                                         
                                         __weak typeof(strongSelf) weakSelf2 = strongSelf;
                                         
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             // On main thread
                                             
                                             __strong typeof(weakSelf2) strongSelf2 = weakSelf2;
                                             if(strongSelf2 == nil) {
                                                 return;
                                             }
                                         
                                             NSLog(@"-- [%@ %@]", strongSelf, [m selectorString]);
                                             
                                             [strongSelf performMethod:m withParameters:strongSelf.paramsToAdd removing:strongSelf.paramsToRemove];
                                         });
                                     }
                                 }];
        }
        
        return;
    }
    
    NSString *returnTypeDecodedString = [m returnTypeDecoded];
    
    NSString *selectorString = [m selectorString];
    
    if([selectorString isEqualToString:@"dealloc"]) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    SEL selector = [m selector];
    
    if([_object respondsToSelector:selector] == NO) {
        return;
    }
    
    if([returnTypeDecodedString hasPrefix:@"struct"]) return;
    
    id o = nil;
    
    NSParameterAssert(selector != NULL);
    NSParameterAssert([_object respondsToSelector:selector]);
    
    NSMethodSignature *methodSig = [_object methodSignatureForSelector:selector];
    if(methodSig == nil) {
        NSLog(@"Invalid Method Signature for class: %@ and selector: %@", _object, NSStringFromSelector(selector));
        return;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    
    // Check to see if it's alloc
    if ([headerDescription isEqualToString:@"alloc"]) {
        // Alloc and init the class
        
        o = [_object performSelector:selector];
        
        id theOb = o;
        
        // Verify we can init it
        if ([o respondsToSelector:NSSelectorFromString(@"init")]) {
            theOb = [o performSelector:NSSelectorFromString(@"init")];
        }
        
        RTBObjectsTVC *ovc = [[RTBObjectsTVC alloc] initWithStyle:UITableViewStylePlain];
        ovc.object = theOb;
        [self.navigationController pushViewController:ovc animated:YES];
        
        return;
    }
    
    const char* retType = [methodSig methodReturnType];
    
    @try {

        if(strcmp(retType, @encode(id)) == 0) {
            o = [_object performSelector:selector];
        } else {
            
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
            [invocation setTarget:_object];
            [invocation setSelector:selector];
            [invocation invoke];

            if (strcmp(retType, @encode(BOOL)) == 0) {
                BOOL result;
                [invocation getReturnValue:&result];
                o = result ? @"YES" : @"NO";
            } else if (strcmp(retType, @encode(void)) == 0) {
                [_object performSelector:selector];
            } else if (strcmp(retType, @encode(int)) == 0) {
                int result;
                [invocation getReturnValue:&result];
                o = [@(result) description];
            } else if (strcmp(retType, @encode(unsigned int)) == 0) {
                unsigned int result;
                [invocation getReturnValue:&result];
                o = [@(result) description];
            } else if (strcmp(retType, @encode(unsigned long long)) == 0) {
                unsigned long long result;
                [invocation getReturnValue:&result];
                o = [@(result) description];
            } else if (strcmp(retType, @encode(double)) == 0) {
                double result;
                [invocation getReturnValue:&result];
                o = [@(result) description];
            } else if (strcmp(retType, @encode(float)) == 0) {
                float result;
                [invocation getReturnValue:&result];
                o = [@(result) description];
            } else {
                NSLog(@"-[%@ performSelector:@selector(%@)] shouldn't be used. The selector doesn't return an object or void", _object, NSStringFromSelector(selector));
                return;
            }
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
    
    if(![returnTypeDecodedString isEqualToString:@"id"]) {
        if([returnTypeDecodedString isEqualToString:@"NSInteger"] || [returnTypeDecodedString isEqualToString:@"NSUInteger"] || [returnTypeDecodedString hasSuffix:@"int"]) {
//            o = [NSString stringWithFormat:@"%d", (int)o];
        } else if([returnTypeDecodedString isEqualToString:@"double"] || [returnTypeDecodedString isEqualToString:@"float"]) {
//            o = [NSString stringWithFormat:@"%f", o];
        } else if([returnTypeDecodedString isEqualToString:@"BOOL"]) {
//            o = ([o boolValue]) ? @"YES" : @"NO";
        } else if ([returnTypeDecodedString isEqualToString:@"void"]) {
            o = @"Completed";
        } else {
            o = [NSString stringWithFormat:@"%d",(int) o]; // default
        }
    }
    
    if([o isKindOfClass:[NSString class]] || [o isKindOfClass:[NSArray class]] || [o isKindOfClass:[NSDictionary class]] || [o isKindOfClass:[NSSet class]]) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:[o description]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        
        return;
    }
    
    RTBObjectsTVC *ovc = [[RTBObjectsTVC alloc] initWithStyle:UITableViewStylePlain];
    ovc.object = o;
    [self.navigationController pushViewController:ovc animated:YES];
}

- (void)performMethod:(RTBMethod *)m withParameters:(NSMutableArray *)parameters removing:(NSMutableArray *)removing {
    
    NSString *selectorString = [m selectorString];
    
    NSString *returnTypeDecoded = [m returnTypeDecoded];
    if([returnTypeDecoded hasPrefix:@"struct"]) return;

    if([selectorString isEqualToString:@"dealloc"]) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }

    RTBObjectsTVC *ovc = [[RTBObjectsTVC alloc] initWithStyle:UITableViewStylePlain];
    
    SEL selector = NSSelectorFromString([m selectorString]);
    
    if(![_object respondsToSelector:selector]) {
        return;
    }
    
    id o = nil;
    
    NSParameterAssert(selector != NULL);
    NSParameterAssert([_object respondsToSelector:selector]);
    
    NSMethodSignature *methodSig = [_object methodSignatureForSelector:selector];
    if(methodSig == nil) {
        NSLog(@"Invalid Method Signature for class: %@ and selector: %@", _object, NSStringFromSelector(selector));
        return;
    }
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    
    // Check to see if it's alloc
    if ([selectorString isEqualToString:@"alloc"]) {
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
    
    const char* retType = [methodSig methodReturnType];
    
    @try {
        // Allow the object to perform the selector if it's of certain types
        if(strcmp(retType, @encode(id)) == 0) {
            // id
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[_object methodSignatureForSelector:selector]];
            [inv setSelector:selector];
            [inv setTarget:_object];
            
            NSLog(@"-- PARAMETERS: %@", parameters);
            
            for (int x = 0; x < [parameters count]; x++) {
                // Determine the type of input
                if ([[removing objectAtIndex:x] rangeOfString:@"BOOL"].location != NSNotFound) {
                    // BOOL
                    BOOL obj = NO;
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
                    NSInteger obj = [[parameters objectAtIndex:x] integerValue];
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
                    NSInteger obj = [[parameters objectAtIndex:x] integerValue];
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
                    NSInteger obj = [[parameters objectAtIndex:x] integerValue];
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
                    NSInteger obj = [[parameters objectAtIndex:x] integerValue];
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
    
    if(![returnTypeDecoded isEqualToString:@"id"]) {
        if([returnTypeDecoded isEqualToString:@"NSInteger"] || [returnTypeDecoded isEqualToString:@"NSUInteger"] || [returnTypeDecoded hasSuffix:@"int"]) {
            o = [NSString stringWithFormat:@"%d", (int)o];
        } else if([returnTypeDecoded isEqualToString:@"double"] || [returnTypeDecoded isEqualToString:@"float"]) {
            o = [NSString stringWithFormat:@"%f", [o floatValue]];
        } else if([returnTypeDecoded isEqualToString:@"BOOL"]) {
            o = ([o boolValue]) ? @"YES" : @"NO";
        } else if ([returnTypeDecoded isEqualToString:@"void"]) {
            o = @"Completed";
        } else {
            o = [NSString stringWithFormat:@"%d", (int)o]; // default
        }
    }
    
    if([o isKindOfClass:[NSString class]] || [o isKindOfClass:[NSArray class]] || [o isKindOfClass:[NSDictionary class]] || [o isKindOfClass:[NSSet class]]) {
        
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
