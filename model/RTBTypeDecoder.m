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

#import "RTBTypeDecoder.h"

#if (! TARGET_OS_IPHONE)
#import <objc/objc-runtime.h>
#else
#import <objc/runtime.h>
#import <objc/message.h>
#endif

static NSString *TYPE_LABEL = @"type";
static NSString *MODIFIER_LABEL = @"modifier";

static NSString *IVAR_TAB = @"    ";

// caution, these caches will be accessed by several thread in the same time when using the embedded web server or search from OS X RuntimeBrowser
//static NSMutableDictionary *cachedDecodedTypesForEncodedTypes = nil;
//static NSMutableDictionary *cachedDecodedTypesForEncodedTypesFlat = nil;

#define isTypeSpecifier(fc) (fc=='r'||fc=='R'||fc=='n'||fc=='N'||fc=='o'||fc=='O'||fc=='V'||fc=='A'||fc=='j'||fc=='!')

NSString * rtb_argTypeSpecifierForEncoding(char fc) {
    if(fc == 'r') return @"const ";
    if(fc == 'R') return @"byref ";
    if(fc == 'n') return @"in ";
    if(fc == 'N') return @"inout ";
    if(fc == 'o') return @"out ";
    if(fc == 'O') return @"bycopy ";
    if(fc == 'V') return @"oneway ";
    if(fc == 'A') return @"_Atomic ";
    if(fc == 'j') return @"_Complex ";
    if(fc == '!') return @""; // garbage-collector marked invisible -> ignore
    return nil;
}

NSString *rtb_unhandledWarning(BOOL showUnhandledWarning) {
    return (showUnhandledWarning ?
            @"/* RuntimeBrowser encountered an ivar type encoding it does not handle. \n   See Warning(s) below.\n */\n\n" :
            @"");
}

NSString *rtb_functionSignatureNote(BOOL showFunctionSignatureNote) {
    return (showFunctionSignatureNote ?
            @"/* RuntimeBrowser encountered one or more ivar type encodings for a function pointer. \n   The runtime does not encode function signature information.  We use a signature of: \n           \"int (*funcName)()\",  where funcName might be null. \n */\n\n" :
            @"");
}

@interface RTBTypeDecoder ()
- (NSString *)parseStructOrUnionEndCh:(char)endCh depth:(int *)depth sPart:(int)sPart inLine:(BOOL)inLine inParam:(BOOL)inParam spaceAfter:(BOOL)spaceAfter;
- (NSDictionary *)typeEncParseObjectRefInStruct:(BOOL)inStruct spaceAfter:(BOOL)spaceAfter;
- (NSDictionary *)cTypeDeclForEncTypeDepth:(int *)depth sPart:(int)sPart inStruct:(BOOL)inStruct inLine:(BOOL)inLine inParam:(BOOL)inParam spaceAfter:(BOOL)spaceAfter;
@end

@implementation RTBTypeDecoder

@synthesize namedStructs;

- (void)setIvT:(const char*)s {
    ivT = s;
}

- (const char*)ivT {
    return ivT;
}

+ (NSArray *)decodeTypes:(NSString *)encodedTypes flat:(BOOL)flat {

//    if(cachedDecodedTypesForEncodedTypes == nil) {
//        cachedDecodedTypesForEncodedTypes = [NSMutableDictionary dictionary];
//    }
//    
//    if(cachedDecodedTypesForEncodedTypesFlat == nil) {
//        cachedDecodedTypesForEncodedTypesFlat = [NSMutableDictionary dictionary];
//    }
//    
//    NSMutableDictionary *cacheDictionary = flat ? cachedDecodedTypesForEncodedTypesFlat : cachedDecodedTypesForEncodedTypes;
//    
//    NSArray *cachedDecodedTypes = cacheDictionary[encodedTypes];
//    if(cachedDecodedTypes) return cachedDecodedTypes;
    
    RTBTypeDecoder *typeDecoder = [[self alloc] init];
    typeDecoder.showCommentForBlocks = [[NSUserDefaults standardUserDefaults] boolForKey:@"RTBAddCommentsForBlocks"];
    
    [typeDecoder setIvT:[encodedTypes cStringUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableArray *ma = [NSMutableArray array];
    
    while(YES) {
        @autoreleasepool {
  
        NSDictionary *d = nil;
        
        [typeDecoder skipDigits];

        //printf("--> %s\n", typeDecoder.ivT);
        
        if(strlen(typeDecoder.ivT) == 0) break;
        
        if(flat) {
            d = [typeDecoder flatCTypeDeclForEncType];
        } else {
            d = [typeDecoder ivarCTypeDeclForEncType];
        }

        [ma addObject:d[TYPE_LABEL]];
            
        }
    }
    
//    cacheDictionary[encodedTypes] = ma;
    
    return ma;
}

+ (NSString *)decodeType:(NSString *)encodedType flat:(BOOL)flat {
    
    NSArray *types = [self decodeTypes:encodedType flat:flat];
    if([types count] == 0) {
        NSLog(@"-- no types found in encodedType: %@", encodedType);
        types = @[@"void"];
    }
    NSAssert([types count] > 0, nil);
    NSString *decodedType = types[0];
    
    return decodedType;
}

//OK
- (NSDictionary *)typeEncWarning:(NSString *)inParse startingIVT:(const char*)startingIVT origResult:(NSDictionary *)origResult {
    NSString *typeS = [origResult objectForKey:TYPE_LABEL];
    NSString *modifierS = [origResult objectForKey:MODIFIER_LABEL];
    
    typeS = [NSString stringWithFormat:@"/* Warning: unhandled %@encoding: '%s' */ %@", inParse, startingIVT, typeS];
    currentWarning = YES;  // indicated that we've already issued a warning on this pass through the ivar parser.
    methodWarning = showUnhandledWarning = YES;
    
    return [NSDictionary dictionaryWithObjectsAndKeys:typeS, TYPE_LABEL, modifierS, MODIFIER_LABEL, nil];
}

//OK
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
        case 'D':
            rs = @"long double";
            break;
        case 'B' :
            rs = @"bool";
            break;
        case 'v' :
            rs = @"void";
            break;
        case '*' : // STR
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
            case 'f' : case 'd' : case 'v' : case 'B':
                rs = [rs stringByAppendingString:@" "];
                break;
        }
    }
    
    return rs;
}

//OK
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

//OK
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

//OK
- (void)advanceIVTPast:(char)endCh {
    /**
     Advance ivT past endCh or, if not found, to the end of ivT.
     This is called after a parse "error" (no endCh at expected location).
     */
    const char* tmp = strchr(ivT, endCh);
    if (tmp == NULL)
        ivT += strlen(ivT);  // can't find endCh, move to the end of the string.
    else
        ivT = tmp + 1;       // move past endCh
}

//OK
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

//OK
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

- (void)skipDigits {
    while (strlen(ivT) && isdigit (*ivT)) {
        ivT++;
    };
}

//OK
- (NSDictionary *)flatCTypeDeclForEncType {
    structPart = structDepth = 0; // PENDING ....use global access rather than params?
    return [self cTypeDeclForEncTypeDepth:&structDepth sPart:structPart inStruct:NO inLine:YES inParam:YES spaceAfter:NO];
}

//OK
- (NSDictionary *)ivarCTypeDeclForEncType {
    structPart = structDepth = 0;
    return [self cTypeDeclForEncTypeDepth:&structDepth sPart:structPart inStruct:NO inLine:NO inParam:NO spaceAfter:YES];
}

//OK
- (NSMutableString *)parseUnnamedStructOrUnionVarEndCh:(char)endCh depth:(int *)depth sPart:(int)sPart inLine:(BOOL)inLine inParam:(BOOL)inParam {
    NSMutableString *structS = [NSMutableString string];
    NSDictionary *structInfo;
    NSString *partName;
    int i;
    
    //parse each char as an (unnamed) type ... we then need to assign names.
    for (i=1; *ivT != endCh && *ivT != '\0'; ++i) {
        @autoreleasepool {
            
            //structInfo = cTypeDeclForEncType(depth, i, YES, inLine, inParam, YES);
            structInfo = [self cTypeDeclForEncTypeDepth:depth sPart:i inStruct:YES inLine:inLine inParam:inParam spaceAfter:YES];
            
            // Naming for nested pieces is a bit of a kludge.
            // To support arbitrary nesting w/ unique naming (not required to compile)
            // we'd need an array of sPart[] and increment sPart[depth] and output
            // all sParts in sequence to generate a unique name (based on location)
            
            if ([structS length] > 1024) {
                continue;
            }
            
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
    }
    
    return structS;
}

// OK
- (NSDictionary *)typeEncParseStructOrUnionWithEncType:(NSString *)encType endCh:(char)endCh depth:(int *)depth sPart:(int)sPart inLine:(BOOL)inLine inParam:(BOOL)inParam spaceAfter:(BOOL)spaceAfter {
    //ivT = "?=i[3f]b128i3b131i2c}"; // http://gcc.gnu.org/onlinedocs/gcc-3.0.4/gcc_7.html#SEC130
    
    NSString *typeS = @"";
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
                    typeS =  [self parseUnnamedStructOrUnionVarEndCh:endCh depth:depth sPart:sPart inLine:inLine inParam:inParam];
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
    
    if(typeS != nil) {
        typeS = [encType stringByAppendingString:typeS];
    } else {
        typeS = encType;
    }
    --(*depth);
    
    return [NSDictionary dictionaryWithObjectsAndKeys:typeS, TYPE_LABEL, modifierS, MODIFIER_LABEL, nil];
}

//OK
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
        structS = [self parseUnnamedStructOrUnionVarEndCh:endCh depth:depth sPart:sPart inLine:inLine inParam:inParam];
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

//OK
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
        case '@' :   // id or id? (block) or named object reference
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
                typeSpec = [typeSpec stringByAppendingString:rtb_argTypeSpecifierForEncoding(*ivT)];
                // typeSpec = [typeSpec stringByAppendingString:(inParam ? argTypeSpecifierForEnoding(*ivT) : nil)];
                ++ivT;
            }
            
            if (typeSpec == nil) { // most common case: types are NOT modified by a specifier
                
                type = [self typeForFilerCode:*ivT spaceAfter:spaceAfter];
                modifier = @"";
                ++ivT;
            } else {
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

//OK
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
            //            [refdClasses addObject:typeS];  // make sure it gets added to the @class ... declaration.
            typeS = [typeS stringByAppendingString:@" *"];  // And, of course, id is a pointer to a class reference.
            ivT = tmp + 1;       // moved to the end of the name and the closing quote
        }
    }
    if (isUnnamedType) {
        
        BOOL isBlock = *ivT == '?';
        ivT += isBlock; // only increament ivT if the next character is actually being consumed
        if(isBlock && [[NSUserDefaults standardUserDefaults] boolForKey:@"RTBAddCommentsForBlocks"]) {
            typeS = (spaceAfter ? @"id /* block */ " : @"id /* block */");
        } else {
            typeS = (spaceAfter ? @"id " : @"id");
        }
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:typeS, TYPE_LABEL, modifierS, MODIFIER_LABEL, nil];
}

//OK
- (NSDictionary *)flatCTypeDeclForEncType:(const char*)encType {
    ivT = encType;
    return [self flatCTypeDeclForEncType];
}

//OK
- (NSDictionary *)ivarCTypeDeclForEncType:(const char*)encType {
    ivT = encType;
    return [self ivarCTypeDeclForEncType];
}

@end
