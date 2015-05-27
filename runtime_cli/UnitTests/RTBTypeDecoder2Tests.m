//
//  RTBTypeDecoder2Tests.m
//  runtime_cli
//
//  Created by Nicolas Seriot on 24/05/15.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "RTBTypeDecoder2.h"

@interface RTBTypeDecoder2Tests : XCTestCase

@end

@implementation RTBTypeDecoder2Tests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testTypeDecoder2IndexOfClosingChar {
    NSInteger i1 = [RTBTypeDecoder2 indexOfClosingCharForString:@"{}" openingChar:'{' closingChar:'}'];
    XCTAssertEqual(i1, 1);
    
    NSInteger i2 = [RTBTypeDecoder2 indexOfClosingCharForString:@"{{}}" openingChar:'{' closingChar:'}'];
    XCTAssertEqual(i2, 3);
    
    NSInteger i3 = [RTBTypeDecoder2 indexOfClosingCharForString:@"" openingChar:'{' closingChar:'}'];
    XCTAssertEqual(i3, NSNotFound);
}

- (void)testTypeDecoder2NameBeforeEqual {
    NSString *s1 = [RTBTypeDecoder2 nameBeforeEqualInString:@"asd=dfg"];
    XCTAssertEqualObjects(s1, @"asd");
    
    NSString *s2 = [RTBTypeDecoder2 nameBeforeEqualInString:@"asd"];
    XCTAssertNil(s2);
    
    NSString *s3 = [RTBTypeDecoder2 nameBeforeEqualInString:@"asd="];
    XCTAssertNil(s3);
}

- (void)testTypeDecoder2DecodeTypePointer {
    RTBTypeDecoder2 *td = [[RTBTypeDecoder2 alloc] init];
    
    NSDictionary *d = [td decodeType:@"^^d"];
    
    XCTAssertEqualObjects([RTBTypeDecoder2 descriptionForTypeDictionary:d], @"double**");
}

- (void)testTypeDecoder2DecodeTypeStruct {
    RTBTypeDecoder2 *td = [[RTBTypeDecoder2 alloc] init];
    
    NSDictionary *d = [td decodeType:@"{asd=d}"];
    
    XCTAssertEqualObjects(d[@"kind"], @"STRUCT");
    
    NSDictionary *d2 = @{@"kind":@"SIMPLE_TYPE", @"decodedType":@"double", @"tail":@""};
    XCTAssertEqualObjects(d[@"encodedTypes"], @[d2]);
    
    NSLog(@"-%@-", [RTBTypeDecoder2 descriptionForTypeDictionary:d]);
    
    XCTAssertEqualObjects([RTBTypeDecoder2 descriptionForTypeDictionary:d], @"struct asd { double x1; }");
}

- (void)testTypeDecoder2DecodeTypeStructWithSeveralFields {
    RTBTypeDecoder2 *td = [[RTBTypeDecoder2 alloc] init];
    
    NSDictionary *d = [td decodeType:@"{asd=d@^I}"];
    XCTAssertEqualObjects(d[@"kind"], @"STRUCT");
    
    XCTAssertEqual([d[@"encodedTypes"] count], 3);
    
    XCTAssertEqualObjects([RTBTypeDecoder2 descriptionForTypeDictionary:d], @"struct asd { double x1; id x2; unsigned int* x3; }");
}

- (void)testTypeDecoder2DecodeTypeStructWithSeveralFieldsAndNoName {
    RTBTypeDecoder2 *td = [[RTBTypeDecoder2 alloc] init];
    
    NSDictionary *d = [td decodeType:@"{d@^I}"];
    XCTAssertEqualObjects(d[@"kind"], @"STRUCT");
    
    XCTAssertEqual([d[@"encodedTypes"] count], 3);
    
    XCTAssertEqualObjects([RTBTypeDecoder2 descriptionForTypeDictionary:d], @"struct { double x1; id x2; unsigned int* x3; }");
}

- (void)testTypeDecoded2DecodeArray {
    RTBTypeDecoder2 *td = [[RTBTypeDecoder2 alloc] init];
    
    NSDictionary *d = [td decodeType:@"[10i]"];
    
    XCTAssertEqualObjects(d[@"kind"], @"ARRAY");
    
    NSLog(@"-%@-", [RTBTypeDecoder2 descriptionForTypeDictionary:d]);
    
    XCTAssertEqualObjects([RTBTypeDecoder2 descriptionForTypeDictionary:d], @"int x[10];");
}

@end
