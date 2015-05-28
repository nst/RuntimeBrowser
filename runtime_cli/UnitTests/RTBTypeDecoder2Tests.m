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
    XCTAssertNotNil(s3);
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

- (void)testTypeDecoder2DecodePointerOnEmptyStructWithName {
    RTBTypeDecoder2 *td = [[RTBTypeDecoder2 alloc] init];
    
    NSDictionary *d = [td decodeType:@"^{__asl_object_s=}"];
    XCTAssertEqualObjects(d[@"kind"], @"POINTER");
    
    NSDictionary *d2 = d[@"encodedType"];
    XCTAssertEqualObjects(d2[@"name"], @"__asl_object_s");
//    
//    XCTAssertEqualObjects([RTBTypeDecoder2 descriptionForTypeDictionary:d], @"struct { __asl_object_s; }");
}

- (void)testTypeDecoded2DecodeArray {
    RTBTypeDecoder2 *td = [[RTBTypeDecoder2 alloc] init];
    
    NSDictionary *d = [td decodeType:@"[10i]"];
    
    XCTAssertEqualObjects(d[@"kind"], @"ARRAY");
    
    NSLog(@"-%@-", [RTBTypeDecoder2 descriptionForTypeDictionary:d]);
    
    XCTAssertEqualObjects([RTBTypeDecoder2 descriptionForTypeDictionary:d], @"int x[10];");
}

- (void)testComplicatedType1 {
    RTBTypeDecoder2 *td = [[RTBTypeDecoder2 alloc] init];
    
    NSDictionary *d = [td decodeType:@"{TFCGImage=\"fRef\"{TRef<CGImage *, TRetainReleasePolicy<CGImageRef> >=\"fRef\"^{CGImage}}}"]; // OS X "BU_TMSkinnedPushButton"

//    NSLog(@"-- %@", d);
    
    XCTAssertEqualObjects(d[@"kind"], @"STRUCT");
    XCTAssertEqualObjects(d[@"name"], @"TFCGImage");
    
    XCTAssertEqual([d[@"encodedTypes"] count], 2);

    XCTAssertEqualObjects([d[@"encodedTypes"] objectAtIndex:0][@"kind"], @"NAME");
    XCTAssertEqualObjects([d[@"encodedTypes"] objectAtIndex:0][@"name"], @"fRef");

    XCTAssertEqualObjects([d[@"encodedTypes"] objectAtIndex:1][@"kind"], @"STRUCT");
    XCTAssertEqualObjects([d[@"encodedTypes"] objectAtIndex:1][@"name"], @"TRef<CGImage *, TRetainReleasePolicy<CGImageRef> >");

    XCTAssertEqual([[d[@"encodedTypes"] objectAtIndex:1][@"encodedTypes"] count], 2);
    
    XCTAssertEqualObjects([[d[@"encodedTypes"] objectAtIndex:1][@"encodedTypes"] objectAtIndex:0][@"kind"], @"NAME");
    XCTAssertEqualObjects([[d[@"encodedTypes"] objectAtIndex:1][@"encodedTypes"] objectAtIndex:0][@"name"], @"fRef");
    
    XCTAssertEqualObjects([[d[@"encodedTypes"] objectAtIndex:1][@"encodedTypes"] objectAtIndex:1][@"kind"], @"POINTER");
    XCTAssertEqualObjects([[d[@"encodedTypes"] objectAtIndex:1][@"encodedTypes"] objectAtIndex:1][@"encodedType"][@"kind"], @"STRUCT");
    
    NSLog(@"--- %@", [[d[@"encodedTypes"] objectAtIndex:1][@"encodedTypes"] objectAtIndex:1][@"encodedType"]);
    
    XCTAssertEqual([[[d[@"encodedTypes"] objectAtIndex:1][@"encodedTypes"] objectAtIndex:1][@"encodedType"][@"encodedTypes"] count], 1);

    
    /*
     struct TFCGImage {
         struct TRef<CGImage *, TRetainReleasePolicy<CGImageRef> > {
             struct CGImage {} *fRef;
         } fRef;
     } fDisabledImage;
     */
}

- (void)testStructInStruct {
    RTBTypeDecoder2 *td = [[RTBTypeDecoder2 alloc] init];
    
    NSDictionary *d = [td decodeType:@"{CGRect=\"origin\"{CGPoint=\"x\"d\"y\"d}\"size\"{CGSize=\"width\"d\"height\"d}}"]; // OS X "NSLayerContentsFacet"

    //NSLog(@"-- %@", d);
    
    NSArray *encodedTypes = d[@"encodedTypes"];
    
    NSLog(@"-- %@", encodedTypes);
    
    XCTAssertEqual([encodedTypes count], 4);

    XCTAssertEqualObjects([encodedTypes objectAtIndex:0][@"kind"], @"NAME");
    XCTAssertEqualObjects([encodedTypes objectAtIndex:1][@"kind"], @"STRUCT");
    XCTAssertEqualObjects([encodedTypes objectAtIndex:2][@"kind"], @"NAME");
    XCTAssertEqualObjects([encodedTypes objectAtIndex:3][@"kind"], @"STRUCT");

                          
    
    //XCTAssertEqual(d[@""], <#expression2, ...#>)
    
}

@end
