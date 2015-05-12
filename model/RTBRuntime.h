/*
 AllClasses.h created by eepstein on Sat 16-Mar-2002


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

 You should have received a copy of the GNU General Public License
 along with RuntimeBrowser (in a file called "COPYING.txt"); if not,
 write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 Boston, MA  02111-1307  USA

*/

#import <Foundation/Foundation.h>
#import "RTBClass.h"
#import "RTBProtocol.h"

@interface RTBRuntime : NSObject

@property (nonatomic, retain) NSMutableArray *rootClasses;
@property (nonatomic, retain) NSMutableDictionary *allClassStubsByName;
@property (nonatomic, retain) NSMutableDictionary *allClassStubsByImagePath;
@property (nonatomic, retain) NSMutableDictionary *allProtocolsByName;

+ (RTBRuntime *)sharedInstance;

- (RTBClass *)classStubForClassName:(NSString *)classname;
- (NSArray *)sortedClassStubs;
- (void)emptyCachesAndReadAllRuntimeClasses;
- (NSArray *)sortedProtocolStubs;

@end
