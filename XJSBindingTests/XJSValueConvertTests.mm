//
//  XJSValueConvertTests.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-27.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

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

@end
