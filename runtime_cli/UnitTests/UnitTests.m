//
//  UnitTests.m
//  UnitTests
//
//  Created by Nicolas Seriot on 02/04/15.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "RTBTypeDecoder.h"

#define UNIT_TESTS 1

@interface UnitTests : XCTestCase

@end

@implementation UnitTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)assetLinesAreEqual:(NSString *)s1 withString:(NSString *)s2 {
    NSArray *lines1 = [s1 componentsSeparatedByString:@"\n"];
    NSArray *lines2 = [s2 componentsSeparatedByString:@"\n"];
    XCTAssertEqual([lines1 count], [lines2 count], @"");
    
    for(NSUInteger i = 0; i < [lines1 count]; i++) {
        NSString *line1 = [lines1 objectAtIndex:i];
        NSString *line2 = [lines2 objectAtIndex:i];
        //NSLog(@"-> %@", line1);
        XCTAssertEqualObjects(line1, line2, @"");
    }
}

- (NSString *)decodeFlatCType:(char *)c {
    return [RTBTypeDecoder decodeType:[NSString stringWithCString:c encoding:NSUTF8StringEncoding]
                                            flat:YES];
}

- (NSString *)decodeIvarType:(char *)c {
    return [RTBTypeDecoder decodeType:[NSString stringWithCString:c encoding:NSUTF8StringEncoding]
                                            flat:NO];
}

- (NSString *)decodeIvarModifier:(char *)c {
    RTBTypeDecoder *td = [[RTBTypeDecoder alloc] init];
    NSDictionary *d = [td ivarCTypeDeclForEncType:c];
    return [d valueForKey:@"modifier"];
}

- (NSString *)decodeIvarWithName:(NSString *)name type:(char *)c {

    RTBTypeDecoder *td = [[RTBTypeDecoder alloc] init];
    NSDictionary *d = [td ivarCTypeDeclForEncType:c];
    
    NSString *t = [d valueForKey:@"type"];
    NSString *m = [d valueForKey:@"modifier"];
    
    return [NSString stringWithFormat:@"%@%@%@;", t, name, m];
}

- (NSString *)contentsForResource:(NSString *)name ofType:(NSString *)type {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:type];
    NSError *error = nil;
    NSString *s = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if(s == nil) NSLog(@"-- error: %@", error);
    return s;
}

- (void)testBasicTypes {
    XCTAssertEqualObjects([self decodeFlatCType:"c"], @"BOOL", @"");
    XCTAssertEqualObjects([self decodeFlatCType:"C"], @"unsigned char", @"");
    XCTAssertEqualObjects([self decodeFlatCType:"s"], @"short", @"");
    XCTAssertEqualObjects([self decodeFlatCType:"S"], @"unsigned short", @"");
    XCTAssertEqualObjects([self decodeFlatCType:"i"], @"int", @"");
    XCTAssertEqualObjects([self decodeFlatCType:"I"], @"unsigned int", @"");
    XCTAssertEqualObjects([self decodeFlatCType:"l"], @"long", @"");
    XCTAssertEqualObjects([self decodeFlatCType:"L"], @"unsigned long", @"");
    XCTAssertEqualObjects([self decodeFlatCType:"q"], @"long long", @"");
    XCTAssertEqualObjects([self decodeFlatCType:"Q"], @"unsigned long long", @"");
    XCTAssertEqualObjects([self decodeFlatCType:"f"], @"float", @"");
    XCTAssertEqualObjects([self decodeFlatCType:"d"], @"double", @"");
    XCTAssertEqualObjects([self decodeFlatCType:"v"], @"void", @"");
    XCTAssertEqualObjects([self decodeFlatCType:"@"], @"id", @"");
    XCTAssertEqualObjects([self decodeFlatCType:"#"], @"Class", @"");
    XCTAssertEqualObjects([self decodeFlatCType:":"], @"SEL", @"");
    XCTAssertEqualObjects([self decodeFlatCType:"*"], @"char *", @"");
}

- (void)testComplicatedTypes {
    XCTAssertEqualObjects([self decodeFlatCType:"^f"], @"float*", @"");
    XCTAssertEqualObjects([self decodeFlatCType:"^v"], @"void*", @"");
    XCTAssertEqualObjects([self decodeFlatCType:"^@"], @"id*", @"");
    
    XCTAssertEqualObjects([self decodeIvarType:"[10i]"], @"int ", @"");
    XCTAssertEqualObjects([self decodeIvarModifier:"[10i]"], @"[10]", @"");
    
    NSLog(@"------ %@", [self decodeIvarWithName:@"x" type:"{example=@*i}"]);
    
    XCTAssertEqualObjects([self decodeIvarWithName:@"x" type:"[10i]"], @"int x[10];", @"");
    //	STAssertEqualObjects([self decodeIvarWithName:@"x" type:"{?=i[3f]b128i3b131i2c}"], @"struct { int x1; float x2[3]; unsigned int x3 : 128; int x4; /* Warning: Unrecognized filer type: '3' using 'void*' */ void*x5; unsigned int x6 : 131; int x7; void*x8; BOOL x9; } x;' should be equal to 'int x[10];", @"");
    XCTAssertEqualObjects([self decodeIvarWithName:@"x" type:"{example=@*i}"], @"struct example { id x1; char *x2; int x3; } x;", @"");
    XCTAssertEqualObjects([self decodeIvarWithName:@"x" type:"^{example=@*i}"], @"struct example { id x1; char *x2; int x3; } *x;", @"");
    XCTAssertEqualObjects([self decodeIvarWithName:@"x" type:"^^{example}"], @"struct example {} **x;", @"");
}

- (void)testMultiTypes {

    NSString *typesString = @"c32@0:8^{_colordef=II{_rgbquad=b8b8b8b8}}16@\"NSString\"24";

    NSArray *types = [RTBTypeDecoder decodeTypes:typesString flat:YES];

    XCTAssertEqual(5, [types count]);
    
    XCTAssertEqualObjects(types[0], @"BOOL");
    XCTAssertEqualObjects(types[1], @"id");
    XCTAssertEqualObjects(types[2], @"SEL");
    XCTAssertEqualObjects(types[3], @"struct _colordef { unsigned int x1; unsigned int x2; struct _rgbquad { unsigned int x_3_1_1 : 8; unsigned int x_3_1_2 : 8; unsigned int x_3_1_3 : 8; unsigned int x_3_1_4 : 8; } x3; }*");
    XCTAssertEqualObjects(types[4], @"NSString *");
}

- (void)_testExtendedEncodingForBlock {

    // - (void)aaaWithCompletionHandler:(void (^)(NSURLResponse* response, NSData* data, NSError* connectionError))completionHandler;
    NSString *typeString = @"v24@0:8@?<v@?@\"NSURLResponse\"@\"NSData\"@\"NSError\">16";

    NSArray *types = [RTBTypeDecoder decodeTypes:typeString flat:YES];
    
    XCTAssertEqual(4, [types count]);
    
    XCTAssertEqualObjects(types[0], @"void");
    XCTAssertEqualObjects(types[1], @"id");
    XCTAssertEqualObjects(types[2], @"SEL");
    XCTAssertEqualObjects(types[3], @"void (^)(NSURLResponse* arg1, NSData *arg2, NSError* arg3)");
}

- (void)testSELReturnType {
    NSString *typeString = @":16@0:8";
    
    NSArray *types = [RTBTypeDecoder decodeTypes:typeString flat:YES];
    
    XCTAssertEqual(3, [types count]);
    
    XCTAssertEqualObjects(types[0], @"SEL");
    XCTAssertEqualObjects(types[1], @"id");
    XCTAssertEqualObjects(types[2], @"SEL");
}

- (void)_testHeadersLinesNSString {
//    ClassDisplay *cd = [ClassDisplay classDisplayWithClass:[NSString class]];
//    NSString *generatedHeader = [cd header];
//    
//    [generatedHeader writeToFile:@"/tmp/NSString.h" atomically:YES encoding:NSUTF8StringEncoding error:nil];
//    
//    NSString *referenceHeader = [self contentsForResource:@"NSString" ofType:@"h"];
//    
//    [self assetLinesAreEqual:generatedHeader withString:referenceHeader];
}

- (void)_testHeadersLinesCALayer {
//    ClassDisplay *cd = [ClassDisplay classDisplayWithClass:[CALayer class]];
//    NSString *generatedHeader = [cd header];
//    
//    [generatedHeader writeToFile:@"/tmp/CALayer.h" atomically:YES encoding:NSUTF8StringEncoding error:nil];
//    
//    NSString *referenceHeader = [self contentsForResource:@"CALayer" ofType:@"h"];;
//    
//    [self assetLinesAreEqual:generatedHeader withString:referenceHeader];
}

@end

