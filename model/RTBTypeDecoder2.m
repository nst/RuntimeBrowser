//
//  RTBTypeDecoded2.m
//  runtime_cli
//
//  Created by Nicolas Seriot on 23/05/15.
//
//

#import "RTBTypeDecoder2.h"

@implementation RTBTypeDecoder2

- (instancetype)init {
    self = [super init];
    self.simpeTypesDictionary = @{@"@":@"id",
                                  @"#":@"Class",
                                  @":":@"SEL",
                                  @"c":@"BOOL", // char
                                  @"C":@"unsigned char",
                                  @"s":@"short",
                                  @"S":@"unsigned short",
                                  @"i":@"int",
                                  @"I":@"unsigned int",
                                  @"l":@"long",
                                  @"L":@"unsigned long",
                                  @"q":@"long long",
                                  @"Q":@"unsigned long long",
                                  @"f":@"float",
                                  @"d":@"double",
                                  @"B":@"bool",
                                  @"v":@"void",
                                  @"*":@"char*"};
    return self;
}

+ (NSInteger)indexOfClosingQuoteForString:(NSString *)s {

    NSInteger firstQuoteIndex = NSNotFound;
    
    for(NSUInteger i = 0; i < [s length]; i++) {
        unichar u = [s characterAtIndex:i];
        if(u == '"') {
            if(firstQuoteIndex == NSNotFound) {
                firstQuoteIndex = i;
            } else {
                return i;
            }
        }
    }
    
    return NSNotFound;
}

+ (NSInteger)indexOfClosingCharForString:(NSString *)s openingChar:(unichar)open closingChar:(unichar)close {
    NSUInteger depth = 0;
    
    for(NSUInteger i = 0; i < [s length]; i++) {
        unichar u = [s characterAtIndex:i];
        if(u == open) depth += 1;
        if(u == close) depth -= 1;
        if(depth == 0) return i;
    }
    
    return NSNotFound;
}

+ (NSString *)nameBeforeEqualInString:(NSString *)s {

    NSUInteger indexOfEqual = NSNotFound;
    
    for(NSUInteger i = 0; i < [s length]; i++) {
        unichar u = [s characterAtIndex:i];
        if(isalpha((int)u) == NO && u != '<' && u != '>') {
            if( u == '=' ) {
                indexOfEqual = i;
                break;
            }
        }
    }
    
    if(indexOfEqual == NSNotFound) return nil;

    return [s substringToIndex:indexOfEqual];
}

- (NSDictionary *)decodeArray:(NSString *)encodedType {
    NSInteger closeIndex = [[self class] indexOfClosingCharForString:encodedType
                                                         openingChar:'['
                                                         closingChar:']'];
    
    if(closeIndex == NSNotFound) {
        return @{@"kind":@"ERROR",
                 @"encodedType":encodedType};
    }
    
    NSString *tail = [encodedType substringWithRange:NSMakeRange(1, [encodedType length] - 2)];
    
    NSMutableString *ms = [NSMutableString string];
    for(NSUInteger i = 0; i < [tail length]; i++) {
        unichar c = [tail characterAtIndex:i];
        if(isdigit(c) == NO) break;
        [ms appendFormat:@"%C", c];
    }
    
    NSDictionary *type = [self decodeType:[tail substringFromIndex:[ms length]]];
    
    return @{@"kind":@"ARRAY",
             @"count":ms,
             @"encodedType":type,
             @"tail":type[@"tail"]};
}

- (NSDictionary *)decodeSimpleType:(NSString *)encodedType {
    NSAssert([encodedType length] > 0, @"");
    NSString *firstCharacter = [encodedType substringToIndex:1];
    return @{@"kind":@"SIMPLE_TYPE",
             @"decodedType":_simpeTypesDictionary[firstCharacter],
             @"tail":[encodedType substringFromIndex:1]};
}

- (NSDictionary *)decodeStruct:(NSString *)encodedType {
    
    //NSLog(@"**** %@", encodedType); // {CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}
    
    NSInteger closeIndex = [[self class] indexOfClosingCharForString:encodedType
                                                         openingChar:'{'
                                                         closingChar:'}'];
    
    if(closeIndex == NSNotFound) {
        return @{@"kind":@"ERROR",
                 @"encodedType":encodedType};
    }
    
    NSString *s = [encodedType substringWithRange:NSMakeRange(1, closeIndex-1)]; // CGPoint="x"d"y"d
    
    NSString *name = [[self class] nameBeforeEqualInString:s]; // CGPoint

    NSString *longTail = [encodedType substringFromIndex:closeIndex+1];
    
    NSUInteger equalSignLength = name ? 1 : 0;
    NSUInteger rangeLocation = [name length] + equalSignLength; // {asd=
    NSUInteger rangeLength = [s length] - rangeLocation;
    NSString *structTail = [s substringWithRange:NSMakeRange(rangeLocation, rangeLength)]; // "origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}
    
    NSLog(@"- %@", structTail);
    
    NSMutableArray *typesInStruct = [NSMutableArray array];
    
    while([structTail length] > 0) {
        NSDictionary *type = [self decodeType:structTail];
        if(structTail == nil) {
            NSAssert(structTail, @"cannot decode %@", structTail);
        }
        [typesInStruct addObject:type];
        structTail = type[@"tail"];
    }
    
    return @{@"kind":@"STRUCT",
             @"encodedTypes":typesInStruct,
             @"name":(name ? name : @""),
             @"tail":longTail};
}

//- (NSDictionary *)decodeStruct:(NSString *)encodedType {
//    NSInteger closeIndex = [[self class] indexOfClosingCharForString:encodedType
//                                                         openingChar:'{'
//                                                         closingChar:'}'];
//    
//    if(closeIndex == NSNotFound) {
//        return @{@"kind":@"ERROR",
//                 @"encodedType":encodedType};
//    }
//    
//    NSString *s = [encodedType substringWithRange:NSMakeRange(1, closeIndex-1)];
//    NSString *name = [[self class] nameBeforeEqualInString:s];
//    NSUInteger equalLength = name ? 1 : 0;
//    NSUInteger rangeLocation = 1 + [name length] + equalLength; // {asd=
//    NSUInteger rangeLength = [encodedType length] - rangeLocation - 1;
//    NSString *tail = [encodedType substringWithRange:NSMakeRange(rangeLocation, rangeLength)];
//    
//    NSMutableArray *typesInStruct = [NSMutableArray array];
//    
//    while([tail length] > 0) {
//        NSDictionary *type = [self decodeType:tail];
//        [typesInStruct addObject:type];
//        tail = type[@"tail"];
//    }
//    
//    return @{@"kind":@"STRUCT",
//             @"encodedTypes":typesInStruct,
//             @"name":(name ? name : @""),
//             @"tail":tail};
//}


- (NSDictionary *)decodePointer:(NSString *)encodedType {
    NSString *s = [encodedType substringFromIndex:1];
    NSDictionary *type = [self decodeType:s];
    return @{@"kind":@"POINTER",
             @"encodedType":type,
             @"tail":type[@"tail"]};
}

- (NSDictionary *)decodeName:(NSString *)encodedType {

    NSInteger closeIndex = [[self class] indexOfClosingQuoteForString:encodedType];
        
        if(closeIndex == NSNotFound) {
            return @{@"kind":@"ERROR",
                     @"encodedType":encodedType};
        }
        
        NSString *name = [encodedType substringWithRange:NSMakeRange(1, closeIndex-1)];

    NSString *tail = [encodedType substringFromIndex:closeIndex+1];
    
    return @{@"kind":@"NAME",
             @"name":(name ? name : @""),
             @"tail":tail};

}

- (NSDictionary *)decodeType:(NSString *)encodedType {
    
    NSString *firstCharacter = [encodedType substringToIndex:1];
    
    if([firstCharacter isEqualToString:@"^"]) {
        return [self decodePointer:encodedType];
    } else if([firstCharacter isEqualToString:@"{"]) {
        return [self decodeStruct:encodedType];
    } else if([firstCharacter isEqualToString:@"["]) {
        return [self decodeArray:encodedType];
    } else if ([firstCharacter isEqualToString:@"\""]) {
        return [self decodeName:encodedType];
    } else if (_simpeTypesDictionary[firstCharacter]) {
        return [self decodeSimpleType:encodedType];
    } else {
        return [self decodeName:[NSString stringWithFormat:@"\"%@\"", encodedType]];
    }
    
    NSAssert(NO, @"cannot decode type %@", encodedType);

    return nil;
}

+ (NSString *)descriptionForTypeDictionary:(NSDictionary *)d {
    
    if([d[@"kind"] isEqualToString:@"POINTER"]) {
        return [NSString stringWithFormat:@"%@*", [self descriptionForTypeDictionary:d[@"encodedType"]]];
    } else if ([d[@"kind"] isEqualToString:@"SIMPLE_TYPE"]) {
        
        NSString *tail = d[@"tail"];
        NSString *decodedType = d[@"decodedType"];
        
        if([decodedType isEqualToString:@"id"] && [tail hasPrefix:@"\""]) {
            RTBTypeDecoder2 *decoded = [[RTBTypeDecoder2 alloc] init];
            NSString *name = [decoded decodeType:tail][@"name"];
            return [NSString stringWithFormat:@"%@ *", name];
        }
        
        return d[@"decodedType"];
    } else if ([d[@"kind"] isEqualToString:@"STRUCT"]) {
        NSMutableString *ms = [NSMutableString string];
        [ms appendString:@"struct "];
        if([d[@"name"] length] > 0) [ms appendFormat:@"%@ ", d[@"name"]];
        [ms appendString:@"{ "];
        NSArray *encodedTypes = d[@"encodedTypes"];
        [encodedTypes enumerateObjectsUsingBlock:^(NSDictionary *encodedTypeDictionary, NSUInteger idx, BOOL *stop) {
            NSString *typeDescription = [self descriptionForTypeDictionary:encodedTypeDictionary];
            [ms appendFormat:@"%@ x%lu; ", typeDescription, idx+1];
        }];
        [ms appendString:@"}"];
        return ms;
    } else if ([d[@"kind"] isEqualToString:@"ARRAY"]) {
        return [NSString stringWithFormat:@"%@ x[%@];", [self descriptionForTypeDictionary:d[@"encodedType"]], d[@"count"]];
    } else if ([d[@"kind"] isEqualToString:@"NAME"]) {
        return d[@"name"];
    }
    NSAssert(NO, @"unhandled kind: %@", d[@"kind"]);
    return nil;
}

+ (NSString *)decodeType:(NSString *)encodedType flat:(BOOL)flat {
    RTBTypeDecoder2 *td = [[RTBTypeDecoder2 alloc] init];
    
    NSDictionary *d = [td decodeType:encodedType];
    
    NSAssert(d, @"empty response from decodeType");
    
    return [RTBTypeDecoder2 descriptionForTypeDictionary:d];
}

+ (NSArray *)decodeTypes:(NSString *)encodedType flat:(BOOL)flat {
    RTBTypeDecoder2 *td = [[RTBTypeDecoder2 alloc] init];
    
    NSMutableArray *ma = [NSMutableArray array];
    
    do {
        NSDictionary *d = [td decodeType:encodedType];

        NSString *s = [RTBTypeDecoder2 descriptionForTypeDictionary:d];
        
        [ma addObject:s];
        
        encodedType = d[@"tail"];
        
    } while ([encodedType length] > 0);
    
    return ma;
}

@end
