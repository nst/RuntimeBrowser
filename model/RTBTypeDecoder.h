/* 

ClassDisplay.h created by eepstein on Sun 17-Mar-2002

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

@interface RTBTypeDecoder : NSObject {
    NSMutableDictionary *namedStructs;
    const char* ivT; // the currently-processed Ivar type string
    int structDepth;
    int structPart;
    BOOL currentWarning;
    BOOL methodWarning;
    BOOL showUnhandledWarning;
    BOOL showFunctionSignatureNote;
}

@property (nonatomic, retain) NSMutableSet *refdClasses;
@property (nonatomic, retain) NSMutableDictionary *namedStructs;
@property (nonatomic) BOOL showCommentForBlocks;

+ (NSString *)decodeType:(NSString *)encodedType flat:(BOOL)flat;
+ (NSArray *)decodeTypes:(NSString *)encodedType flat:(BOOL)flat;

// for tests
- (NSDictionary *)flatCTypeDeclForEncType:(const char*)encType;
- (NSDictionary *)ivarCTypeDeclForEncType:(const char*)encType;

@end
