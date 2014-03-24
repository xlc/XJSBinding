//
//  XJSValueConvertTests.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-27.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CoreGraphics/CoreGraphics.h>

#import "NSObject+XJSValueConvert.h"

#import "XJSContext.h"
#import "XJSValue.h"

@interface XJSValueConvertTests : XCTestCase

@end

@implementation XJSValueConvertTests
{
    XJSContext *_context;
    XJSValue *_value;
    BOOL _hasError;
}

- (void)setUp
{
    _context = [[XJSContext alloc] init];
    [_context createObjCRuntimeWithNamespace:@"objc"];
}

- (void)tearDown
{
    _context = nil;
    _value = nil;
}

- (void)testNumber
{
    NSNumber *num;
    
    num = @YES;
    _value = [num xjs_toValueInContext:_context];
    XCTAssertEqual(_value.toBool, YES);
    
    num = @123;
    _value = [num xjs_toValueInContext:_context];
    XCTAssertEqual(_value.toInt32, 123);
    
    num = @123.5;
    _value = [num xjs_toValueInContext:_context];
    XCTAssertEqual(_value.toDouble, 123.5);
    
    num = @(UINT32_MAX);
    _value = [num xjs_toValueInContext:_context];
    XCTAssertEqual(_value.toUInt32, UINT32_MAX);
}

- (void)testString
{
    NSString *str;
    
    str = @"123";
    _value = [str xjs_toValueInContext:_context];
    XCTAssertEqualObjects(_value.toString, str);
    
    str = @"";
    _value = [str xjs_toValueInContext:_context];
    XCTAssertEqualObjects(_value.toString, str);
    
    str = [NSMutableString stringWithFormat:@"%d", 1];
    _value = [str xjs_toValueInContext:_context];
    XCTAssertEqualObjects(_value.toString, @"1");
}

- (void)testNull
{
    XCTAssertTrue([[NSNull null] xjs_toValueInContext:_context].isNull);
}

- (void)testDate
{
    NSDate *date;
    
    date = [NSDate date];
    _value = [date xjs_toValueInContext:_context];
    XCTAssertEqualWithAccuracy(_value.toDate.timeIntervalSince1970, date.timeIntervalSince1970, 0.001);
    
    date = [NSDate dateWithTimeIntervalSinceNow:100];
    _value = [date xjs_toValueInContext:_context];
    XCTAssertEqualWithAccuracy(_value.toDate.timeIntervalSince1970, date.timeIntervalSince1970, 0.001);
    
    date = [NSDate dateWithTimeIntervalSince1970:0];
    _value = [date xjs_toValueInContext:_context];
    XCTAssertEqualWithAccuracy(_value.toDate.timeIntervalSince1970, date.timeIntervalSince1970, 0.001);
    
    date = [NSDate dateWithTimeIntervalSince1970:-100];
    _value = [date xjs_toValueInContext:_context];
    XCTAssertEqualWithAccuracy(_value.toDate.timeIntervalSince1970, date.timeIntervalSince1970, 0.001);
}

- (void)testObject
{
    id obj = [NSObject new];
    _value = [obj xjs_toValueInContext:_context];
    XCTAssertNotNil(_value);
    
    XCTAssertTrue(_value.isObject);
    XCTAssertEqualObjects(_value.toObject, obj);
}

- (void)testArray
{
    NSArray *array;
    
    array = @[];
    _value = [array xjs_toValueInContext:_context];
    XCTAssertNotNil(_value);
    XCTAssertFalse(_value.isPrimitive, "should be jsobject");
    XCTAssertFalse(_value.isObject, "should be native array object, not objc object");
    XCTAssertEqual(_value[@"length"].toInt32, 0);
    XCTAssertEqualObjects(_value.toArray, array);
    
    array = @[@1, @"test"];
    _value = [array xjs_toValueInContext:_context];
    XCTAssertNotNil(_value);
    XCTAssertFalse(_value.isPrimitive, "should be jsobject");
    XCTAssertFalse(_value.isObject, "should be native array object, not objc object");
    XCTAssertEqual(_value[@"length"].toInt32, 2);
    XCTAssertEqualObjects(_value.toArray, array);
    
    array = [NSMutableArray arrayWithObjects:@1, @"test", nil];
    _value = [array xjs_toValueInContext:_context];
    XCTAssertNotNil(_value);
    XCTAssertFalse(_value.isPrimitive, "should be jsobject");
    XCTAssertFalse(_value.isObject, "should be native array object, not objc object");
    XCTAssertEqual(_value[@"length"].toInt32, 2);
    XCTAssertEqualObjects(_value.toArray, array);
}

- (void)testStruct
{
    NSValue *value;
    
    CGPoint p = {1,2};
    value = [NSValue valueWithBytes:&p objCType:@encode(CGPoint)];
    _value = [value xjs_toValueInContext:_context];
    XCTAssertNotNil(_value);
    XCTAssertFalse(_value.isPrimitive);
    
    CGPoint p2 = {};
    [[_value toValueOfType:@encode(CGPoint)] getValue:&p2];
    XCTAssertEqualObjects([NSValue valueWithBytes:(const void *)&p objCType:@encode(CGPoint)], [NSValue valueWithBytes:(const void *)&p2 objCType:@encode(CGPoint)]);
    
    CGRect rect = {{1,2},{3,4}};
    value = [NSValue valueWithBytes:&rect objCType:@encode(CGRect)];
    _value = [value xjs_toValueInContext:_context];
    XCTAssertNotNil(_value);
    XCTAssertFalse(_value.isPrimitive);
    
    CGRect rect2 = {};
    [[_value toValueOfType:@encode(CGRect)] getValue:&rect2];
    XCTAssertEqualObjects([NSValue valueWithBytes:(const void *)&rect objCType:@encode(CGRect)], [NSValue valueWithBytes:(const void *)&rect2 objCType:@encode(CGRect)]);
}

- (void)testDictionary
{
    NSDictionary *dict;
    
    dict = @{};
    _value = [dict xjs_toValueInContext:_context];
    XCTAssertNotNil(_value);
    XCTAssertFalse(_value.isPrimitive, "is object");
    XCTAssertFalse(_value.isObject, "is native object");
    XCTAssertEqualObjects(_value.description, @"({})", "empty object");
    
    dict = @{@"a" : @'b', @2 : @"test"};
    _value = [dict xjs_toValueInContext:_context];
    XCTAssertNotNil(_value);
    XCTAssertFalse(_value.isPrimitive, "is object");
    XCTAssertFalse(_value.isObject, "is native object");
    XCTAssertEqual(_value[@"a"].toInt32, (int)'b');
    XCTAssertEqualObjects(_value[@"2"].toString, @"test");
    
    dict = @{@"arr" : @[@1, @3, @4], @"dict" : @{@1 : @2}};
    _value = [dict xjs_toValueInContext:_context];
    XCTAssertNotNil(_value);
    XCTAssertFalse(_value.isPrimitive, "is object");
    XCTAssertFalse(_value.isObject, "is native object");
    XCTAssertEqualObjects(_value[@"arr"].toArray, (@[@1, @3, @4]));
    XCTAssertEqualObjects(_value[@"dict"].toDictionary, (@{@"1" : @2}));
}

@end
