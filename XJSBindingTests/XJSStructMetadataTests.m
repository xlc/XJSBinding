//
//  XJSStructMetadataTests.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-10-26.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "XJSStructMetadata.h"

typedef struct test_struct1 {
    float x;
    double y;
    int z;
} test_struct1;

typedef struct test_struct2 {
    test_struct1 x;
    char y;
    struct {
        long long ll;
        short s;
    } z;
} test_struct2;

typedef struct empty_struct {
    
} empty_struct;

@interface XJSStructMetadataTests : XCTestCase

@end

@implementation XJSStructMetadataTests
{
    XJSStructMetadata *_data;
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    _data = nil;
    
    [super tearDown];
}

- (void)testPlainStruct
{
    _data = [[XJSStructMetadata alloc] initWithEncoding:@(@encode(test_struct1)) fields:@[XJS_CREATE_FIELD(test_struct1, x),
                                                                                          XJS_CREATE_FIELD(test_struct1, y),
                                                                                          XJS_CREATE_FIELD(test_struct1, z)]];
    XCTAssertEqualObjects(_data.name, @"test_struct1");
    XCTAssertEqualObjects(_data.encoding, @(@encode(test_struct1)));
    XCTAssertEqual(_data.fields.count, (NSUInteger)3);
    
    XJSStructField *field;
    field = _data.fields[0];
    XCTAssertEqual(field.offset, offsetof(test_struct1, x));
    XCTAssertEqualObjects(field.name, @"x");
    XCTAssertEqualObjects(field.encoding, @(@encode(float)));
    XCTAssertEqual(field.size, (NSUInteger)sizeof(float));
    
    field = _data.fields[1];
    XCTAssertEqual(field.offset, offsetof(test_struct1, y));
    XCTAssertEqualObjects(field.name, @"y");
    XCTAssertEqualObjects(field.encoding, @(@encode(double)));
    XCTAssertEqual(field.size, (NSUInteger)sizeof(double));
    
    field = _data.fields[2];
    XCTAssertEqual(field.offset, offsetof(test_struct1, z));
    XCTAssertEqualObjects(field.name, @"z");
    XCTAssertEqualObjects(field.encoding, @(@encode(int)));
    XCTAssertEqual(field.size, (NSUInteger)sizeof(int));
}

- (void)testPlainStructDifferentOrder
{
    _data = [[XJSStructMetadata alloc] initWithEncoding:@(@encode(test_struct1)) fields:@[XJS_CREATE_FIELD(test_struct1, z),
                                                                                          XJS_CREATE_FIELD(test_struct1, y),
                                                                                          XJS_CREATE_FIELD(test_struct1, x)]];
    XCTAssertEqualObjects(_data.name, @"test_struct1");
    XCTAssertEqualObjects(_data.encoding, @(@encode(test_struct1)));
    XCTAssertEqual(_data.fields.count, (NSUInteger)3);
    
    XJSStructField *field;
    field = _data.fields[0];
    XCTAssertEqual(field.offset, offsetof(test_struct1, x));
    XCTAssertEqualObjects(field.name, @"x");
    XCTAssertEqualObjects(field.encoding, @(@encode(float)));
    XCTAssertEqual(field.size, (NSUInteger)sizeof(float));
    
    field = _data.fields[1];
    XCTAssertEqual(field.offset, offsetof(test_struct1, y));
    XCTAssertEqualObjects(field.name, @"y");
    XCTAssertEqualObjects(field.encoding, @(@encode(double)));
    XCTAssertEqual(field.size, (NSUInteger)sizeof(double));
    
    field = _data.fields[2];
    XCTAssertEqual(field.offset, offsetof(test_struct1, z));
    XCTAssertEqualObjects(field.name, @"z");
    XCTAssertEqualObjects(field.encoding, @(@encode(int)));
    XCTAssertEqual(field.size, (NSUInteger)sizeof(int));
}

- (void)testEmptyStruct
{
    _data = [[XJSStructMetadata alloc] initWithEncoding:@(@encode(empty_struct)) fields:@[]];
    
    XCTAssertEqualObjects(_data.name, @"empty_struct");
    XCTAssertEqualObjects(_data.encoding, @(@encode(empty_struct)));
    XCTAssertEqual(_data.fields.count, (NSUInteger)0);
}

- (void)testComplexStruct
{
    test_struct2 dummy;
    
    _data = [[XJSStructMetadata alloc] initWithEncoding:@(@encode(test_struct2)) fields:@[XJS_CREATE_FIELD(test_struct2, x),
                                                                                          XJS_CREATE_FIELD(test_struct2, y),
                                                                                          XJS_CREATE_FIELD(test_struct2, z)]];
    XCTAssertEqualObjects(_data.name, @"test_struct2");
    XCTAssertEqualObjects(_data.encoding, @(@encode(test_struct2)));
    XCTAssertEqual(_data.fields.count, (NSUInteger)3);
    
    XJSStructField *field;
    field = _data.fields[0];
    XCTAssertEqual(field.offset, offsetof(test_struct2, x));
    XCTAssertEqualObjects(field.name, @"x");
    XCTAssertEqualObjects(field.encoding, @(@encode(test_struct1)));
    XCTAssertEqual(field.size, (NSUInteger)sizeof(test_struct1));
    
    field = _data.fields[1];
    XCTAssertEqual(field.offset, offsetof(test_struct2, y));
    XCTAssertEqualObjects(field.name, @"y");
    XCTAssertEqualObjects(field.encoding, @(@encode(char)));
    XCTAssertEqual(field.size, (NSUInteger)sizeof(char));
    
    field = _data.fields[2];
    XCTAssertEqual(field.offset, offsetof(test_struct2, z));
    XCTAssertEqualObjects(field.name, @"z");
    XCTAssertEqualObjects(field.encoding, @(@encode(struct {long long ll;short s;})));
    XCTAssertEqual(field.size, (NSUInteger)sizeof(dummy.z));
}

- (void)testAddMetadata
{
    test_struct2 dummy;
    
    [XJSStructMetadata addMetadataWithEncoding:@(@encode(test_struct2)) fields:@[XJS_CREATE_FIELD(test_struct2, x),
                                                                                 XJS_CREATE_FIELD(test_struct2, y),
                                                                                 XJS_CREATE_FIELD(test_struct2, z)]];
    _data = [XJSStructMetadata metadataForEncoding:@(@encode(test_struct2))];
    XCTAssertNotNil(_data);
    
    XCTAssertEqualObjects(_data.name, @"test_struct2");
    XCTAssertEqualObjects(_data.encoding, @(@encode(test_struct2)));
    XCTAssertEqual(_data.fields.count, (NSUInteger)3);
    
    XJSStructField *field;
    field = _data.fields[0];
    XCTAssertEqual(field.offset, offsetof(test_struct2, x));
    XCTAssertEqualObjects(field.name, @"x");
    XCTAssertEqualObjects(field.encoding, @(@encode(test_struct1)));
    XCTAssertEqual(field.size, (NSUInteger)sizeof(test_struct1));
    
    field = _data.fields[1];
    XCTAssertEqual(field.offset, offsetof(test_struct2, y));
    XCTAssertEqualObjects(field.name, @"y");
    XCTAssertEqualObjects(field.encoding, @(@encode(char)));
    XCTAssertEqual(field.size, (NSUInteger)sizeof(char));
    
    field = _data.fields[2];
    XCTAssertEqual(field.offset, offsetof(test_struct2, z));
    XCTAssertEqualObjects(field.name, @"z");
    XCTAssertEqualObjects(field.encoding, @(@encode(struct {long long ll;short s;})));
    XCTAssertEqual(field.size, (NSUInteger)sizeof(dummy.z));
}

@end
