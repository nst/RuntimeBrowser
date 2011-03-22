//
//  UnitTests.m
//  runtime_cli
//
//  Created by Nicolas Seriot on 2/16/11.
//  Copyright 2011 IICT. All rights reserved.
//


#import "UnitTests.h"
#import "ClassDisplay.h"

// TODO: add properties types tests from http://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html

@implementation UnitTests

- (void)assetLinesAreEqual:(NSString *)s1 withString:(NSString *)s2 {
	NSArray *lines1 = [s1 componentsSeparatedByString:@"\n"];
	NSArray *lines2 = [s2 componentsSeparatedByString:@"\n"];
	STAssertEquals([lines1 count], [lines2 count], @"");
	
	for(NSUInteger i = 0; i < [lines1 count]; i++) {
		NSString *line1 = [lines1 objectAtIndex:i];
		NSString *line2 = [lines2 objectAtIndex:i];
		//NSLog(@"-- %@", line1);
		STAssertEqualObjects(line1, line2, @"");
	}
}

- (NSString *)decodeFlatCType:(char *)c {
	ClassDisplay *cd = [[[ClassDisplay alloc] init] autorelease];
	NSDictionary *d = [cd flatCTypeDeclForEncType:c];
	return [d valueForKey:@"type"];
}

- (NSString *)decodeIvarType:(char *)c {
	ClassDisplay *cd = [[[ClassDisplay alloc] init] autorelease];
	NSDictionary *d = [cd ivarCTypeDeclForEncType:c];
	return [d valueForKey:@"type"];
}

- (NSString *)decodeIvarModifier:(char *)c {
	ClassDisplay *cd = [[[ClassDisplay alloc] init] autorelease];
	NSDictionary *d = [cd ivarCTypeDeclForEncType:c];
	return [d valueForKey:@"modifier"];
}

- (NSString *)decodeIvarWithName:(NSString *)name type:(char *)c {
	ClassDisplay *cd = [[[ClassDisplay alloc] init] autorelease];
	NSDictionary *d = [cd ivarCTypeDeclForEncType:c];
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
	STAssertEqualObjects([self decodeFlatCType:"c"], @"BOOL", @"");
	STAssertEqualObjects([self decodeFlatCType:"C"], @"unsigned char", @"");
	STAssertEqualObjects([self decodeFlatCType:"s"], @"short", @"");
	STAssertEqualObjects([self decodeFlatCType:"S"], @"unsigned short", @"");
	STAssertEqualObjects([self decodeFlatCType:"i"], @"int", @"");
	STAssertEqualObjects([self decodeFlatCType:"I"], @"unsigned int", @"");
	STAssertEqualObjects([self decodeFlatCType:"l"], @"long", @"");
	STAssertEqualObjects([self decodeFlatCType:"L"], @"unsigned long", @"");
	STAssertEqualObjects([self decodeFlatCType:"q"], @"long long", @"");
	STAssertEqualObjects([self decodeFlatCType:"Q"], @"unsigned long long", @"");
	STAssertEqualObjects([self decodeFlatCType:"f"], @"float", @"");
	STAssertEqualObjects([self decodeFlatCType:"d"], @"double", @"");
	STAssertEqualObjects([self decodeFlatCType:"v"], @"void", @"");
	STAssertEqualObjects([self decodeFlatCType:"@"], @"id", @"");
	STAssertEqualObjects([self decodeFlatCType:"#"], @"Class", @"");
	STAssertEqualObjects([self decodeFlatCType:":"], @"SEL", @"");
	STAssertEqualObjects([self decodeFlatCType:"*"], @"char *", @"");	
}

- (void)testComplicatedTypes {
	STAssertEqualObjects([self decodeIvarType:"[10i]"], @"int ", @"");
	STAssertEqualObjects([self decodeIvarModifier:"[10i]"], @"[10]", @"");
	
	STAssertEqualObjects([self decodeIvarWithName:@"x" type:"[10i]"], @"int x[10];", @"");	
//	STAssertEqualObjects([self decodeIvarWithName:@"x" type:"{?=i[3f]b128i3b131i2c}"], @"struct { int x1; float x2[3]; unsigned int x3 : 128; int x4; /* Warning: Unrecognized filer type: '3' using 'void*' */ void*x5; unsigned int x6 : 131; int x7; void*x8; BOOL x9; } x;' should be equal to 'int x[10];", @"");	
	STAssertEqualObjects([self decodeIvarWithName:@"x" type:"{example=@*i}"], @"struct example { id x1; char *x2; int x3; } x;", @"");
	STAssertEqualObjects([self decodeIvarWithName:@"x" type:"^{example=@*i}"], @"struct example { id x1; char *x2; int x3; } *x;", @"");
	STAssertEqualObjects([self decodeIvarWithName:@"x" type:"^^{example}"], @"struct example {} **x;", @"");
}

/*
- (void)testHeaderGenerationNSString {
	NSString *generatedHeader = [[ClassDisplay sharedInstance] headerForClass:[NSString class]];
	NSString *referenceHeader = [self contentsForResource:@"NSString" ofType:@"h"];;
	STAssertEqualObjects(generatedHeader, referenceHeader, @"");
}

- (void)testHeaderGenerationCALayer {
	NSString *generatedHeader = [[ClassDisplay sharedInstance] headerForClass:[CALayer class]];
	NSString *referenceHeader = [self contentsForResource:@"CALayer" ofType:@"h"];
	STAssertEqualObjects(generatedHeader, referenceHeader, @"");
}
*/

- (void)testHeadersLinesNSString {
	ClassDisplay *cd = [ClassDisplay classDisplayWithClass:[NSString class]];
	NSString *generatedHeader = [cd header];
	NSString *referenceHeader = [self contentsForResource:@"NSString" ofType:@"h"];
	
	[self assetLinesAreEqual:generatedHeader withString:referenceHeader];
}

- (void)testHeadersLinesCALayer {
	ClassDisplay *cd = [ClassDisplay classDisplayWithClass:[CALayer class]];
	NSString *generatedHeader = [cd header];
	NSString *referenceHeader = [self contentsForResource:@"CALayer" ofType:@"h"];;

//	NSLog(@"-- generatedHeader:%@", generatedHeader);
//	NSLog(@"-- referenceHeader:%@", referenceHeader);

	[self assetLinesAreEqual:generatedHeader withString:referenceHeader];
}

@end
