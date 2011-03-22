/* 
 
 ClassDisplay.m created by eepstein on Sun 17-Mar-2002
 
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

/*
 PENDING:
 - typedefs for struct references
 
 - categories
 
 Can we get the names of all loaded Protocols?  -- it appears to be private.
 
 ----------------
 strip return type.
 advance to first ':' (arg separator -- a CONST)
 LOOP:
 read size (an int)
 parse arg type
 :END
 Insert arg types (no names) into method name.  // use string --> array conversion (break at ':')
 ----------------
 */

#import "ClassDisplay.h"

#if (! TARGET_OS_IPHONE)
#import <objc/objc-runtime.h>
#else
#import <objc/runtime.h>
#import <objc/message.h>
#endif

static NSString *TYPE_LABEL = @"type";
static NSString *MODIFIER_LABEL = @"modifier";

static NSString *IVAR_TAB = @"    ";

#define isTypeSpecifier(fc) (fc=='r'||fc=='n'||fc=='N'||fc=='o'||fc=='O'||fc=='V'||fc=='!')

NSString * argTypeSpecifierForEncoding(char fc) {
	if(fc == 'r') return @"const ";
	if(fc == 'n') return @"in ";
	if(fc == 'N') return @"inout ";
	if(fc == 'o') return @"out ";
	if(fc == 'O') return @"bycopy ";
	if(fc == 'V') return @"oneway ";
	if(fc == '!') return @""; // garbage-collector marked invisible -> ignore
	return nil;
}

NSString *unhandledWarning(BOOL showUnhandledWarning) {
    return (showUnhandledWarning ?
            @"/* RuntimeBrowser encountered an ivar type encoding it does not handle. \n   See Warning(s) below.\n */\n\n" :
            @"");
}

NSString *functionSignatureNote(BOOL showFunctionSignatureNote) {
    return (showFunctionSignatureNote ?
            @"/* RuntimeBrowser encountered one or more ivar type encodings for a function pointer. \n   The runtime does not encode function signature information.  We use a signature of: \n           \"int (*funcName)()\",  where funcName might be null. \n */\n\n" :
            @"");
}

@interface ClassDisplay ()
- (NSString *)parseStructOrUnionEndCh:(char)endCh depth:(int *)depth sPart:(int)sPart inLine:(BOOL)inLine inParam:(BOOL)inParam spaceAfter:(BOOL)spaceAfter;
- (NSDictionary *)typeEncParseObjectRefInStruct:(BOOL)inStruct spaceAfter:(BOOL)spaceAfter;
- (NSDictionary *)cTypeDeclForEncTypeDepth:(int *)depth sPart:(int)sPart inStruct:(BOOL)inStruct inLine:(BOOL)inLine inParam:(BOOL)inParam spaceAfter:(BOOL)spaceAfter;
- (void)setRepresentedClass:(Class)klass;
@end

@implementation ClassDisplay

@synthesize refdClasses;
@synthesize namedStructs;
@synthesize displayPropertiesDefaultValues;

+ (ClassDisplay *)classDisplayWithClass:(Class)klass {
	ClassDisplay *cd = [[self alloc] init];
	[cd setRepresentedClass:klass];
	return [cd autorelease];
}

- (void)setRepresentedClass:(Class)klass {
	representedClass = klass;
}

- (NSDictionary *)typeEncWarning:(NSString *)inParse startingIVT:(const char*)startingIVT origResult:(NSDictionary *)origResult {
    NSString *typeS = [origResult objectForKey:TYPE_LABEL];
    NSString *modifierS = [origResult objectForKey:MODIFIER_LABEL];
	
    typeS = [NSString stringWithFormat:@"/* Warning: unhandled %@encoding: '%s' */ %@", inParse, startingIVT, typeS];
    currentWarning = YES;  // indicated that we've already issued a warning on this pass through the ivar parser.
    methodWarning = showUnhandledWarning = YES;
	
    return [NSDictionary dictionaryWithObjectsAndKeys:typeS, TYPE_LABEL, modifierS, MODIFIER_LABEL, nil];
}

// See the "Definitions of filer types" #define(s) in objc-class.h
- (NSString *)typeForFilerCode:(char)fc spaceAfter:(BOOL)spaceAfter {
    NSString *rs;
	
	/*
     #define _C_ID       '@'
     #define _C_CLASS    '#'
     #define _C_SEL      ':'
     #define _C_CHR      'c'
     #define _C_UCHR     'C'
     #define _C_SHT      's'
     #define _C_USHT     'S'
     #define _C_INT      'i'
     #define _C_UINT     'I'
     #define _C_LNG      'l'
     #define _C_ULNG     'L'
     #define _C_LNG_LNG  'q'
     #define _C_ULNG_LNG 'Q'
     #define _C_FLT      'f'
     #define _C_DBL      'd'
     #define _C_BFLD     'b'
     #define _C_BOOL     'B'
     #define _C_VOID     'v'
     #define _C_UNDEF    '?'
     #define _C_PTR      '^'
     #define _C_CHARPTR  '*'
     #define _C_ATOM     '%'
     #define _C_ARY_B    '['
     #define _C_ARY_E    ']'
     #define _C_UNION_B  '('
     #define _C_UNION_E  ')'
     #define _C_STRUCT_B '{'
     #define _C_STRUCT_E '}'
     #define _C_VECTOR   '!'
     #define _C_CONST    'r'
	 */
	
    switch (fc) {
        case '@' :
            rs = @"id";
            break;
        case '#' :
            rs = @"Class";
            break;
        case ':' :
            rs = @"SEL";
            break;
        case 'c' :
            rs = @"BOOL"; //@"char";
            break;
        case 'C' :
            rs = @"unsigned char";
            break;
        case 's' :
            rs = @"short";
            break;
        case 'S' :
            rs = @"unsigned short";
            break;
        case 'i' :
            rs = @"int";
            break;
        case 'I' :
            rs = @"unsigned int";
            break;
        case 'l' :
            rs = @"long";
            break;
        case 'L' :
            rs = @"unsigned long";
            break;
        case 'q' :
            rs = @"long long";
            break;
        case 'Q' :
            rs = @"unsigned long long";
            break;
        case 'f' :
            rs = @"float";
            break;
        case 'd' :
            rs = @"double";
            break;
        case 'B' :
            rs = @"bool";
            break;
        case 'v' :
            rs = @"void";
            break;
        case '*' :
        case '%' : // _C_ATOM
            rs = @"char *";
            break;
        default :
            if (!currentWarning) {
                currentWarning = YES;
                showUnhandledWarning = YES;
                methodWarning = YES;
                rs = [NSString stringWithFormat:@"/* Warning: Unrecognized filer type: '%c' using 'void*' */ void*", fc];
            } else {
                rs = @"void*";
            }
            break;
    }
	
    if (spaceAfter) {
        switch (fc) {
            case '@' : case '#' : case ':' : case 'c' : case 'C' :
            case 's' : case 'S' : case 'i' : case 'I' : case 'l' : case 'L' : case 'q' : case 'Q' :
            case 'f' : case 'd' : case 'v' :
                rs = [rs stringByAppendingString:@" "];
                break;
        }
    }
	
    return rs;
}

- (NSDictionary *)typeEncParseBitField:(BOOL)spaceAfter {
    /*"
     NeXT: bit field encoding format 'bN', where N is the size, an integer.
     Later GCC: encoding format 'bOtN',  where O (an int) is the offset, t (char) is the type, N (int) is the size.
     "*/
    NSDictionary *result;    
    NSString *typeS = nil;
    NSString *modifierS = nil;
    int sizeModifier;    // size of this bitfield
	
	/* PENDING PENDING
	 position = atoi (type + 1);
	 while (isdigit (*++type));
	 
	 size = atoi (type + 1);
	 
	 startByte = position / BITS_PER_UNIT;
	 endByte = (position + size) / BITS_PER_UNIT;
	 return endByte - startByte;
	 */
	
    // or use:    sizeModifier=atoi(ivT)
    if (sscanf(ivT, "%d", &sizeModifier) == 1) {  // parse the integer
        while (isdigit(*++ivT));       // skip the digits
        modifierS = [NSString stringWithFormat:@" : %d", sizeModifier]; // its a size modifier
        typeS = (spaceAfter ? @"unsigned int " : @"unsigned int"); // bit fields use unsigned int
        result = [NSDictionary dictionaryWithObjectsAndKeys:typeS, TYPE_LABEL, modifierS, MODIFIER_LABEL, nil];
    } else {  // warn about badly formatted FILER type info.
        typeS = (spaceAfter ? @"unsigned int " : @"unsigned int");
        modifierS = @"/* : ? */";
        result = [NSDictionary dictionaryWithObjectsAndKeys:typeS, TYPE_LABEL, modifierS, MODIFIER_LABEL, nil];
        if (!currentWarning)
            result = [self typeEncWarning:@"bit field" startingIVT:(ivT - 1) origResult:result];
        // to skip the rest, or not to skip ...
        // ivT += strlen(ivT);
    }
    return result;
}

- (BOOL)hasClassName {
    // An object pointer (type 'id') includes a
    // named reference iff the following name is quoted.
    // Inside a struct, the quotes would be nested,
    // so we make sure the name is double-quoted before
    // we use it as a class name (e.g., NSObject *) -- otherwise
    // it's the variable name.
    const char *tmp = strchr(ivT+1, '"');
    return ((tmp != NULL) && (*(tmp+1) == '"' || *(tmp+1) =='}'));
}

- (void)advanceIVTPast:(char)endCh {
    /**
     Advance ivT past endCh or, if not found, to the end of ivT.
     This is called after a parse "error" (no endCh at expected location).
     */
    const char* tmp = strchr(ivT, endCh);
    if (tmp ==NULL)
        ivT += strlen(ivT);  // can't find endCh, move to the end of the string.
    else
        ivT = tmp + 1;       // move past endCh
}

- (NSDictionary *)typeEncParseArrayOf:(int *)depth sPart:(int)sPart inLine:(BOOL)inLine inParam:(BOOL)inParam spaceAfter:(BOOL)spaceAfter {
    NSString *typeS = nil;
    NSString *modifierS = nil;
    int sizeModifier;    // size of this array 
	
    if (sscanf(ivT, "%d", &sizeModifier) == 1) {  // Array encoding starts with the size of the array
        NSDictionary *innerTypeInfo;
		
        while (isdigit(*ivT)) ++ivT;      // move past the digits (size)
        innerTypeInfo = [self cTypeDeclForEncTypeDepth:depth sPart:sPart inStruct:NO inLine:inLine inParam:inParam spaceAfter:spaceAfter]; // what TYPE of array
        typeS = [innerTypeInfo objectForKey:TYPE_LABEL];  // get the inner type
        // append a modifier that makes the type into an array of size 'sizeModifier'
        // NOTE: the array itself may be "modified" (e.g., nested arrays),  so append the inner modifier.
        modifierS = [NSString stringWithFormat:@"[%d]%@", sizeModifier, [innerTypeInfo objectForKey:MODIFIER_LABEL]];
    } else {  // no size encoded ... handle bad or unrecognized encodings
        if (!currentWarning) {
            currentWarning = YES;
            methodWarning = showUnhandledWarning = YES;
            typeS = [NSString stringWithFormat:@"/* Warning: unhandled array encoding: '%s' */void*", (ivT - 1)];
            if (spaceAfter) typeS = [typeS stringByAppendingString:@" "];
        } else {
            typeS = (spaceAfter ? @"void* " : @"void*");
        }
        modifierS = @"[ /* ? */ ]"; // size unknown.
    }
	
    return [NSDictionary dictionaryWithObjectsAndKeys:typeS, TYPE_LABEL, modifierS, MODIFIER_LABEL, nil];
}

- (NSDictionary *)typeEncParsePointerTo:(int *)depth sPart:(int)sPart inLine:(BOOL)inLine inParam:(BOOL)inParam spaceAfter:(BOOL)spaceAfter {
	NSString *typeS = nil;
    NSString *modifierS = nil;
	
    if (*ivT == '?') { // function pointer
        ++ivT;
        typeS = @"int (*";
        modifierS = @")()";
        showFunctionSignatureNote = YES;
    } else {
        NSDictionary *innerTypeInfo = [self cTypeDeclForEncTypeDepth:depth sPart:sPart inStruct:NO inLine:inLine inParam:inParam spaceAfter:spaceAfter]; // Get the type
      
        modifierS = [innerTypeInfo objectForKey:MODIFIER_LABEL];  // and it's modifier
        typeS = [[innerTypeInfo objectForKey:TYPE_LABEL] stringByAppendingString:@"*"];  // make type a pointer
    }
	
    return [NSDictionary dictionaryWithObjectsAndKeys:typeS, TYPE_LABEL, modifierS, MODIFIER_LABEL, nil];
}

- (NSDictionary *)flatCTypeDeclForEncType {
    structPart = structDepth = 0; // PENDING ....use global access rather than params?
    return [self cTypeDeclForEncTypeDepth:&structDepth sPart:structPart inStruct:NO inLine:YES inParam:YES spaceAfter:NO];
}

- (NSDictionary *)ivarCTypeDeclForEncType {
    structPart = structDepth = 0;
    return [self cTypeDeclForEncTypeDepth:&structDepth sPart:structPart inStruct:NO inLine:NO inParam:NO spaceAfter:YES];
}

- (NSMutableString *)_parseUnnamedStructOrUnionVarEndCh:(char)endCh depth:(int *)depth sPart:(int)sPart inLine:(BOOL)inLine inParam:(BOOL)inParam {
    NSMutableString *structS = [NSMutableString string];
    NSDictionary *structInfo;
    NSString *partName;
    int i;
	
    //parse each char as an (unnamed) type ... we then need to assign names.
    for (i=1; *ivT != endCh; ++i) {
        //structInfo = cTypeDeclForEncType(depth, i, YES, inLine, inParam, YES);
		structInfo = [self cTypeDeclForEncTypeDepth:depth sPart:i inStruct:YES inLine:inLine inParam:inParam spaceAfter:YES];
		
        // Naming for nested pieces is a bit of a kludge.
        // To support arbitrary nesting w/ unique naming (not required to compile)
        // we'd need an array of sPart[] and increment sPart[depth] and output
        // all sParts in sequence to generate a unique name (based on location)
        if (sPart > 1 || *depth > 1) { // PENDING -- make var (and arg, and category and ...) names a parameter
            partName = [NSString stringWithFormat:@"x_%d_%d_%d", sPart, (*depth)-1, i]; 
        } else {
            partName = [NSString stringWithFormat:@"x%d", i]; // PENDING -- make var names a parameter
        }
        [structS appendString:[structInfo objectForKey:TYPE_LABEL]];
        [structS appendString:partName];
        [structS appendString:[structInfo objectForKey:MODIFIER_LABEL]];
        [structS appendString:@"; "];
    }
	
    return structS;
}

- (NSDictionary *)typeEncParseStructOrUnionWithEncType:(NSString *)encType endCh:(char)endCh depth:(int *)depth sPart:(int)sPart inLine:(BOOL)inLine inParam:(BOOL)inParam spaceAfter:(BOOL)spaceAfter {
	//ivT = "?=i[3f]b128i3b131i2c}"; // http://gcc.gnu.org/onlinedocs/gcc-3.0.4/gcc_7.html#SEC130
    
    NSString *typeS = nil;
    NSString *modifierS = @"";
    char *eqPos = strchr(ivT, '=');
    char *innerSPos = strchr(ivT, '{');
    char *innerUPos = strchr(ivT, '(');
	
    ++(*depth);
    // Check for a definition (after an '=') within this (possibly nested) struct/union (e.g., before endCh).
    // The '=' must come before the end of this struct/union and before the beginning of another.
    if ( eqPos != NULL && eqPos < strchr(ivT, endCh) &&
		(innerUPos==NULL || eqPos < innerUPos) && (innerSPos==NULL || eqPos < innerSPos) ) {
        // struct or union definition provided (parsed by parseStructOrUnion()).
        typeS = [self parseStructOrUnionEndCh:endCh depth:depth sPart:sPart inLine:inLine inParam:inParam spaceAfter:spaceAfter];
    } else {   // named struct or union (name only)
        const char *tmp = strchr(ivT, endCh);
        if (tmp != NULL) {
			
            if (*ivT != '?') {
				
                // need parse union's differently
                if (endCh == ')') {  // Learned this later... no longer a generic Struct/Unin parser. Alas.
                    typeS =  [self _parseUnnamedStructOrUnionVarEndCh:endCh depth:depth sPart:sPart inLine:inLine inParam:inParam];
                    // PENDING curly braces -- add 'em inside func.
                    typeS = [NSString stringWithFormat:@"{ %@} ", typeS];
				} else {
					NSString *s = [NSString stringWithCString:ivT encoding:NSUTF8StringEncoding];
					typeS = [s substringToIndex:tmp-ivT];
                    if (spaceAfter)
                        typeS = [typeS stringByAppendingString:@" {} "];
                    else
                        typeS = [typeS stringByAppendingString:@" {}"];
                }
                
            } else {
                typeS = (spaceAfter ? @"{ /* ? */ } " : @"{ /* ? */ }");
            }
			
            ivT = tmp;
        }
    }
    typeS = [encType stringByAppendingString:typeS];
    --(*depth);
    
    return [NSDictionary dictionaryWithObjectsAndKeys:typeS, TYPE_LABEL, modifierS, MODIFIER_LABEL, nil];
}

- (NSString *)parseStructOrUnionEndCh:(char)endCh depth:(int *)depth sPart:(int)sPart inLine:(BOOL)inLine inParam:(BOOL)inParam spaceAfter:(BOOL)spaceAfter {
	NSDictionary *structInfo;
    NSMutableString *structS;
    NSMutableString *depthS = (NSMutableString *)@"";
    NSString *name = nil;
    NSString *partName = nil;
    NSString *tmpS = nil;
    NSString *fmt1 = (spaceAfter ? @"{ %@%@} " : @"{ %@%@}");    // no space (' ') after decl for parameter)s.
    NSString *fmt2 = (spaceAfter ? @" { %@%@} " : @" { %@%@}");
    int i;
    
    const char *tmp = strchr(ivT, '=');
	
    if (*ivT != '?') {
		NSString *s = [NSString stringWithCString:ivT encoding:NSUTF8StringEncoding];
		name = [s substringToIndex:tmp-ivT]; // get the name
	}
    
    ivT = tmp + 1;
	
    if (*ivT == '"') {
        structS = [NSMutableString string];
        while (*ivT == '"') {
            ++ivT;
            tmp = strchr(ivT, '"');
			
			NSString *s = [NSString stringWithCString:ivT encoding:NSUTF8StringEncoding];
			partName = [s substringToIndex:tmp-ivT]; // get the name
            
            ivT = tmp + 1;
			
            //structInfo = cTypeDeclForEncType(depth, sPart, YES, inLine, inParam, YES);
			structInfo = [self cTypeDeclForEncTypeDepth:depth sPart:sPart inStruct:YES inLine:inLine inParam:inParam spaceAfter:YES];
            
            if (!inLine) {
                depthS = [NSMutableString string];
                for (i=0; i<*depth; ++i)
                    [depthS appendString:IVAR_TAB];
                [structS appendFormat:@"\n%@", IVAR_TAB];
                [structS appendString:depthS];
            } 
            [structS appendString:[structInfo objectForKey:TYPE_LABEL]];
            [structS appendString:partName];
            [structS appendString:[structInfo objectForKey:MODIFIER_LABEL]];
            [structS appendString:@"; "];
        }
        if (!inLine)
            [structS appendString:@"\n"];
    } else {  // usually means inParam == YES
        structS = [self _parseUnnamedStructOrUnionVarEndCh:endCh depth:depth sPart:sPart inLine:inLine inParam:inParam];
    }
	
    // PENDING... wierdness here
    if (name == nil) // do something similar as with the 'namedStructs' (perhaps the same)
        return [NSString stringWithFormat:fmt1, structS, depthS];
    else { // PENDING -- do typedefs and refer to structs by name
        tmpS = [NSString stringWithFormat:@" { %@%@}", structS, depthS];
        [namedStructs setObject:tmpS forKey:name];
    }
    
    return [name stringByAppendingFormat:fmt2, structS, depthS];
}

// uses the global ivT
// SPEED - might be faster to use a mutable dictionary.
// depth -- how deeply nested a struct or union is
// sPart -- which part of an outer struct we're in.
- (NSDictionary *)cTypeDeclForEncTypeDepth:(int *)depth sPart:(int)sPart inStruct:(BOOL)inStruct inLine:(BOOL)inLine inParam:(BOOL)inParam spaceAfter:(BOOL)spaceAfter {
    /*"
     This is the entry point for parsing encoded ivar types.
     "*/
    NSDictionary *result;
    NSString *type = nil;
    NSString *modifier = nil;
    NSString *typeSpec = nil;
    const char *startingIVT = ivT;  // used in "Warning" string
    char closingChar = '\0';        // for array, struct and union (null ('\0') for all else)
    NSString *parsedTypeName = nil; // one of: @"array", @"struct", @"union" or nil
	
    switch (*ivT) {  // what sort of thing are we parsing
        case '!' :   // "weak" pointer specifier (for new Garbage collection...).
            ++ivT; // '!' indicates a runtime (non-declarative) feature, skip it and continue
            //result = cTypeDeclForEncType(depth, sPart, inStruct, inLine, inParam, spaceAfter);
            result = [self cTypeDeclForEncTypeDepth:depth sPart:sPart inStruct:inStruct inLine:inLine inParam:inParam spaceAfter:spaceAfter];
            break;
        case '^' :   // Pointer to another type.
            ++ivT;
            result = [self typeEncParsePointerTo:depth sPart:sPart inLine:inLine inParam:inParam spaceAfter:spaceAfter];
            break;
        case 'b' :   // bit field
            ++ivT;
            result = [self typeEncParseBitField:spaceAfter];
            break;
        case '@' :   // id or named object reference
            ++ivT;
            result = [self typeEncParseObjectRefInStruct:inStruct spaceAfter:spaceAfter];
            break;
        case '[' :   // array
            ++ivT;
            result = [self typeEncParseArrayOf:depth sPart:sPart inLine:inLine inParam:inParam spaceAfter:spaceAfter];

            closingChar = ']';  parsedTypeName = @"array ";
            break;
        case '{' :   // struct
            ++ivT;
            closingChar = '}';  parsedTypeName = @"struct ";
            //result = typeEncParseStructOrUnion(parsedTypeName, closingChar, depth, sPart, inLine, inParam, spaceAfter);
            result = [self typeEncParseStructOrUnionWithEncType:parsedTypeName endCh:closingChar depth:depth sPart:sPart inLine:inLine inParam:inParam spaceAfter:spaceAfter];
            break;
        case '(' :   // union -- version for Yellow Box from WO 4.5, may need fixing.
            ++ivT;
            closingChar = ')';  parsedTypeName = @"union ";
//            result = typeEncParseStructOrUnion(parsedTypeName, closingChar, depth, sPart, inLine, inParam, spaceAfter);
            result = [self typeEncParseStructOrUnionWithEncType:parsedTypeName endCh:closingChar depth:depth sPart:sPart inLine:inLine inParam:inParam spaceAfter:spaceAfter];
            break;
        default :    // a simple type or starts with a type specifier
            while (isTypeSpecifier(*ivT)) {  // prepend type specifier(s)
                if (typeSpec == nil) typeSpec = @"";
                typeSpec = [typeSpec stringByAppendingString:argTypeSpecifierForEncoding(*ivT)];
                // typeSpec = [typeSpec stringByAppendingString:(inParam ? argTypeSpecifierForEnoding(*ivT) : nil)];
                ++ivT;
            }
            if (typeSpec == nil) { // most common case: types are NOT modified by a specifier
                type = [self typeForFilerCode:*ivT spaceAfter:spaceAfter];
                modifier = @"";
                ++ivT;
            } else {
//                result = cTypeDeclForEncType(depth, sPart, inStruct, inLine, inParam, spaceAfter);
                result = [self cTypeDeclForEncTypeDepth:depth sPart:sPart inStruct:inStruct inLine:inLine inParam:inParam spaceAfter:spaceAfter];
                type = [typeSpec stringByAppendingString:[result objectForKey:TYPE_LABEL]];                
                modifier =[result objectForKey:MODIFIER_LABEL];
            }
            result = [NSDictionary dictionaryWithObjectsAndKeys:type, TYPE_LABEL, modifier, MODIFIER_LABEL, nil];
            break;
    }
    if (closingChar != '\0') {
        if (*ivT == closingChar) {  // Properly closed array, struct or union
            ++ivT;
        } else {            // handle bad or unrecognized encodings
            if (!currentWarning) // if we haven't already, include a warning...
                result = [self typeEncWarning:parsedTypeName startingIVT:startingIVT origResult:result];
            [self advanceIVTPast:closingChar];
        }
    }
	
    --depth;
    return result;
}

- (NSString *)atClasses {
    int i, c = [refdClasses count];
    NSEnumerator *enumerator = [refdClasses objectEnumerator];
    NSString *className;
    NSString *atClasses = @"";
	
    if (c > 0) {
        atClasses = @"@class ";
        for (i=0; (className = [enumerator nextObject]); ++i) {
            if (i>0)
                atClasses = [atClasses stringByAppendingString:@", "];
            atClasses = [atClasses stringByAppendingString:className];
        }
        atClasses = [atClasses stringByAppendingString:@";\n\n"];
    }
    return atClasses;
}

- (NSDictionary *)typeEncParseObjectRefInStruct:(BOOL)inStruct spaceAfter:(BOOL)spaceAfter {
    NSString *typeS = nil;
    NSString *modifierS = @"";
    BOOL isUnnamedType = YES;
    const char *tmp;
	
    if ((*ivT == '"') && (!inStruct || [self hasClassName])) {  // '@' followed by '"' implies the class name is supplied.
        ++ivT;  // skip the quote
        tmp = strchr(ivT, '"');  // go to the end of the quoted class name
        if (tmp != NULL) {       // (should never happen) no end quote -- default to type 'id' and hope this is parsed elsewhere
            isUnnamedType = NO;    // NO --> this is a named class (type)
			NSString *s = [NSString stringWithCString:ivT encoding:NSUTF8StringEncoding];
			typeS = [s substringToIndex:tmp-ivT]; // get the name
            [refdClasses addObject:typeS];  // make sure it gets added to the @class ... declaration.
            typeS = [typeS stringByAppendingString:@" *"];  // And, of course, id is a pointer to a class reference.
            ivT = tmp + 1;       // moved to the end of the name and the closing quote
        }
    }
    if (isUnnamedType)
        typeS = (spaceAfter ? @"id " : @"id");
	
    return [NSDictionary dictionaryWithObjectsAndKeys:typeS, TYPE_LABEL, modifierS, MODIFIER_LABEL, nil];
}

- (NSDictionary *)flatCTypeDeclForEncType:(const char*)encType {
	ivT = encType;
	return [self flatCTypeDeclForEncType];
}

- (NSDictionary *)ivarCTypeDeclForEncType:(const char*)encType {
	ivT = encType;
	return [self ivarCTypeDeclForEncType];
}

- (NSArray *)methodLinesWithSign:(char)sign {

	Class metaClass = objc_getMetaClass(class_getName(representedClass)); // where class methods live

	Class klass = (sign == '+') ? metaClass : representedClass;
	
    NSDictionary *cTypeDeclInfo;
    NSUInteger i, j, offset;
    const char *tmp;
	
	NSMutableString *header = [NSMutableString stringWithString:@""];
    
	unsigned int methodListCount;
	Method *methodList = class_copyMethodList(klass, &methodListCount); // FIXME: handle exception here
	
	for ( j = methodListCount; j > 0; j-- ) {
		Method currMethod = (methodList[j-1]);
		ivT = method_getTypeEncoding(currMethod);
		
		methodWarning = currentWarning = NO;
		cTypeDeclInfo = [self flatCTypeDeclForEncType];
		
		[header appendFormat:@"%c (%@%@)", sign, [cTypeDeclInfo objectForKey:TYPE_LABEL], [cTypeDeclInfo objectForKey:MODIFIER_LABEL]];
		
		currentWarning = NO;
		tmp = strchr(ivT, ':');
		if (tmp != NULL)
			ivT = tmp+1;
		else
			ivT += strlen(ivT);
		
		NSString *mName = [NSString stringWithCString:(const char *)method_getName(currMethod) encoding:NSASCIIStringEncoding];
		NSArray *mNameParts = [mName componentsSeparatedByString:@":"];
		if ([mNameParts count] == 1) {
			[header appendString:[mNameParts lastObject]];
		}
		for (i=1; i<[mNameParts count]; ++i) {
			offset = atoi(ivT); // ignored;
			while (isdigit (*++ivT));
			currentWarning = NO;
			cTypeDeclInfo = [self flatCTypeDeclForEncType];
			[header appendFormat:@"%@:(%@%@)arg%d%s",
			 [mNameParts objectAtIndex:i-1],
			 [cTypeDeclInfo objectForKey:TYPE_LABEL],
			 [cTypeDeclInfo objectForKey:MODIFIER_LABEL],
			 i,
			 ((i==([mNameParts count]-1))?"":" ")];
		}
		[header appendString:@";\n"];
		if (methodWarning)
			[header appendFormat:@"     /* Encoded args for previous method: %s */\n\n", method_getTypeEncoding(currMethod)];
		// PENDING -- error parsing unions ... different format than structs ?? 
    }
	
	free(methodList);
	
	return [NSArray arrayWithObject:header];
}

+ (void)thisClassIsPartOfTheRuntimeBrowser {}

- (void)dealloc {
    [refdClasses release];
    [namedStructs release];
	[super dealloc];
}

- (NSString *)propertyDescription:(objc_property_t)p {
	NSString *name = [NSString stringWithCString:property_getName(p) encoding:NSUTF8StringEncoding];
	NSString *attr = [NSString stringWithCString:property_getAttributes(p) encoding:NSUTF8StringEncoding];
	
	NSString *getter = nil;
	NSString *setter = nil;
	NSString *type = nil;
	NSString *memory = nil;
	NSString *rw = nil;
	NSString *comment = nil;
	
	NSArray *comps = [attr componentsSeparatedByString:@","];
	for(NSString *comp in comps) {
		unichar c = [comp characterAtIndex:0];
		NSString *rest = [comp substringFromIndex:1];
		switch (c) {
            // unhandled yet: t<encoding>: Specifies the type using old-style encoding.
			case 'R':
				rw = @"readonly";
				break;
			case 'C':
				memory = @"copy";
				break;				
			case '&':
				memory = @"retain";
				break;
			case 'G':
				getter = rest;
				break;
			case 'S':
				setter = rest;
				break;
			case 'T':
			case 't':
			{
				NSDictionary *d = [self flatCTypeDeclForEncType:[rest cStringUsingEncoding:NSUTF8StringEncoding]];
				type = [NSString stringWithFormat:@"%@ ", [d valueForKey:TYPE_LABEL]];
				break;
			}
			case 'D': // The property is dynamic (@dynamic)
            case 'W': // The property is a weak reference (__weak)
			case 'P': // The property is eligible for garbage collection
			case 'N': // The property is non-atomic (nonatomic)
			case 'V': // oneway
				break;
			default:
				comment = [NSString stringWithFormat:@"/* unknown property attribute: %@ */", comp];
				break;
		}
	}
	
	if(displayPropertiesDefaultValues) {
		if(!memory) memory = @"assign";
		if(!rw) rw = @"readwrite";
	}

	NSMutableString *desc = [NSMutableString stringWithString:@"@property"];
	
	NSMutableArray *at = [[NSMutableArray alloc] init];
	if(getter) [at addObject:[NSString stringWithFormat:@"getter=%@", getter]];
	if(setter) [at addObject:[NSString stringWithFormat:@"setter=%@", setter]];
	if(memory) [at addObject:memory];
	if(rw)     [at addObject:rw];
	
	if([at count] > 0) {
		NSString *attributes = [NSString stringWithFormat:@"(%@)", [at componentsJoinedByString:@","]];
		[desc appendString:attributes];
	}
	[at release];
	
	[desc appendFormat:@" %@%@;", type, name];
	
	if(comment)
		[desc appendFormat:@" %@", comment];
	
	[desc appendString:@"\n"];
	
	return desc;
}

- (NSSet *)ivarsTypeTokens {

    NSMutableSet *ms = [NSMutableSet set];
    
	unsigned int ivarListCount;
	Ivar *ivarList = class_copyIvarList(representedClass, &ivarListCount);
	
    if (ivarList != NULL && (ivarListCount>0)) {
        NSUInteger i;
        for ( i = 0; i < ivarListCount; ++i ) {
            Ivar rtIvar = ivarList[i];
            
            if (rtIvar && ivar_getTypeEncoding(rtIvar)) {
                ivT = ivar_getTypeEncoding(rtIvar);
                
                NSDictionary *cTypeDeclInfo = [self ivarCTypeDeclForEncType];
                NSString *type = [cTypeDeclInfo valueForKey:TYPE_LABEL];
                
                NSArray *components = [type componentsSeparatedByString:@" "];
//                NSLog(@"---- %@", components);
				[ms addObjectsFromArray:components];
            }
        }
    }
	free(ivarList);
    
    return ms;
}

- (NSString *)header {
    NSMutableString *header = [NSMutableString string];
	
    NSInteger i;
	unsigned int protocolListCount;
	
    NSArray *instanceMethods;
    NSArray *classMethods;
	
    showFunctionSignatureNote = NO;
    showUnhandledWarning = NO;
    self.refdClasses = [NSMutableSet set];
    self.namedStructs = [NSMutableDictionary dictionary];
	
    // Start of @interface declaration for this class
    [header appendFormat: @"@interface %s ", class_getName(representedClass)];
	
    // with inheritence
    if (class_getSuperclass(representedClass) != nil)
        [header appendFormat: @": %s ", class_getName(class_getSuperclass(representedClass))];
	
    // conforming to protocols
    Protocol **protocolList = class_copyProtocolList(representedClass, &protocolListCount);
    if (protocolList != NULL && (protocolListCount > 0)) {
        [header appendString: @"<"];
        Protocol *rtProtocol = protocolList[0];
        [header appendFormat:@"%s", (rtProtocol ?  protocol_getName(rtProtocol) : "")];
        for ( i = 1; i < protocolListCount; ++i ) {
            rtProtocol = protocolList[i];
            [header appendFormat:@", %s", (rtProtocol ? protocol_getName(rtProtocol) : "")];
        }
        [header appendString: @">"];
    }
	free(protocolList);
//    [header appendString: @"\n"];
	
    // begin Ivars
    [header appendString: @" {\n"]; 
	
    // Meta-Class has no Ivars.
	
    // instance ivars;
	unsigned int ivarListCount;
	Ivar *ivarList = class_copyIvarList(representedClass, &ivarListCount);
	
    if (ivarList != NULL && (ivarListCount>0)) {
        for ( i = 0; i < ivarListCount; ++i ) {
            Ivar rtIvar = ivarList[i];
            
            if (rtIvar && ivar_getTypeEncoding(rtIvar)) {
                ivT = ivar_getTypeEncoding(rtIvar);
                
                currentWarning = NO;
                NSDictionary *cTypeDeclInfo = [self ivarCTypeDeclForEncType];
                if (*ivT != '\0') {
                    currentWarning = YES;
                    showUnhandledWarning = YES;
                    [header appendFormat:@"\n  /* Unexpected information at end of encoded ivar type: %s */", ivT];
                }
                if (currentWarning)
                    [header appendFormat:@"\n  /* Error parsing encoded ivar type info: %s */\n", ivar_getTypeEncoding(rtIvar)];
				
                [header appendString:IVAR_TAB];
                [header appendString:[cTypeDeclInfo objectForKey:TYPE_LABEL]];
                if (ivar_getName(rtIvar)) // compiler may generate ivar entries with NULL ivar_name (e.g. for anonymous bit fields).
                    [header appendFormat:@"%s", ivar_getName(rtIvar)];
                else
                    [header appendString:@"/* ? */"];
				
                [header appendString:[cTypeDeclInfo objectForKey:MODIFIER_LABEL]];
				
                [header appendString:@";\n"];
                if (currentWarning) [header appendString:@"\n"];
            }
        }
    }
	free(ivarList);
	
    // end Ivars
    [header appendString: @"}\n\n"];
	
	// obj-c 2.0 properties
	unsigned int propertyListCount;
	objc_property_t *propertyList = class_copyPropertyList(representedClass, &propertyListCount);
	NSUInteger p;
    for(p = 0; p < propertyListCount; p++) {
		objc_property_t prop = propertyList[p];
		[header appendString:[self propertyDescription:prop]];
	}
	free(propertyList);
	
	if(propertyListCount > 0)
		[header appendString:@"\n"];
	
    // Class methods
    classMethods = [self methodLinesWithSign:'+'];
    i = [classMethods count];
    if (i>0) {   // The last one in the list contains the original methods implemented by the class.
        [header appendString:[classMethods objectAtIndex:(i-1)]];
        [header appendString: @"\n"];
    }
	
    // Instance methods
    instanceMethods = [self methodLinesWithSign:'-'];
    i = [instanceMethods count];
    if (i>0) {
        [header appendString:[instanceMethods objectAtIndex:(i-1)]];
        [header appendString: @"\n"];
    }
		
    [header appendString: @"@end\n"];
		
    header = [NSString stringWithFormat:@"/* Generated by RuntimeBrowser.\n   Image: %s\n */\n\n%@%@%@%@",
			  class_getImageName(representedClass),
			  unhandledWarning(showUnhandledWarning),
			  functionSignatureNote(showFunctionSignatureNote),
			  [self atClasses],
			  header];
		
    // PENDING -- use refdClasses
    // @class line goes here.
		
    return header;
}

@end
