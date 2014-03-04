//
//  XJSValueTests.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-11.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CoreGraphics/CoreGraphics.h>

#import "XJSConvert.hh"

#import "XJSValue_Private.hh"
#import "XJSContext_Private.hh"
#import "XJSRuntime.h"

@interface XJSValueTests : XCTestCase

@end

@implementation XJSValueTests
{
    XJSContext *_context;
    XJSValue *_value;
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

template <typename T>
void _assertEqual(id self, T actual, T expected, SEL selToTest)
{
    XCTAssertEqual(actual, expected, @"failed selector: %@", NSStringFromSelector(selToTest));
}

template <typename NSObject>
void _assertEqual(id self, NSObject * actual, NSObject * expected, SEL selToTest)
{
    XCTAssertEqualObjects(actual, expected, @"failed selector: %@", NSStringFromSelector(selToTest));
}

template <typename T, int N>
void _testValueConvert(XJSValueTests *self, SEL _cmd, XJSContext *cx, SEL selToTest, T expected[N])
{
    XJSValue *values[N] =
    {
        // int
        [XJSValue valueWithInt32:0 inContext:cx],
        [XJSValue valueWithInt32:-1 inContext:cx],
        [XJSValue valueWithInt32:INT32_MAX inContext:cx],
        [XJSValue valueWithInt32:INT32_MIN inContext:cx],
        
        // double
        [XJSValue valueWithDouble:0 inContext:cx],
        [XJSValue valueWithDouble:123.45 inContext:cx],
        [XJSValue valueWithDouble:-123.45 inContext:cx],
        [XJSValue valueWithDouble:INT32_MAX inContext:cx],
        [XJSValue valueWithDouble:INT32_MIN inContext:cx],
        
        // string
        [XJSValue valueWithString:@"0" inContext:cx],
        [XJSValue valueWithString:@"-1" inContext:cx],
        [XJSValue valueWithString:@"123.45" inContext:cx],
        [XJSValue valueWithString:@"-123.45" inContext:cx],
        [XJSValue valueWithString:[NSString stringWithFormat:@"%u", INT32_MAX+1] inContext:cx],
        [XJSValue valueWithString:[NSString stringWithFormat:@"%lld", (int64_t)INT32_MIN-1ll] inContext:cx],
        [XJSValue valueWithString:[NSString stringWithFormat:@"%llu", (uint64_t)INT64_MAX+1ull] inContext:cx],
        [XJSValue valueWithString:@"abcd" inContext:cx],
        
        // boolean
        [XJSValue valueWithBool:YES inContext:cx],
        [XJSValue valueWithBool:NO inContext:cx],
        
        // null
        [XJSValue valueWithNullInContext:cx],
        
        // undefined
        [XJSValue valueWithUndefinedInContext:cx]
    };
    
    T (*imp)(id, SEL) = (T (*)(id, SEL))[XJSValue instanceMethodForSelector:selToTest];
    for (int i = 0; i < N; i++) {
        T actual = imp(values[i], selToTest);
        _assertEqual(self, actual, expected[i], selToTest);
    }
}

- (void)testToInt32
{
    int32_t expected[] =
    {
        0,                                  // 0
        -1,                                 // -1
        INT32_MAX,                          // INT32_MAX
        INT32_MIN,                          // INT32_MIN
        0,                                  // 0.0
        123,                                // 123.45
        -123,                               // -123.45
        INT32_MAX,                          // (double)INT32_MAX
        INT32_MIN,                          // (double)INT32_MIN
        0,                                  // "0"
        -1,                                 // "-1"
        123,                                // "123.45"
        -123,                               // "-123.45"
        
        // signed int overflow is undefined behaviour but we know it is using 2's complement...
        INT32_MAX+1,                        // (string)INT32_MAX+1
        INT32_MIN-1,                        // (string)INT32_MIN-1
        static_cast<int32_t>(INT64_MAX+1),  // (string)INT64_MAX+1
        0,                                  // "abcd"
        1,                                  // YES
        0,                                  // NO
        0,                                  // null
        0                                   // undefined
    };
    
    _testValueConvert<int32_t, sizeof(expected)/sizeof(expected[0])>(self, _cmd, _context, @selector(toInt32), expected);
}

- (void)testToUInt32
{
    uint32_t expected[] =
    {
        0,                                  // 0
        static_cast<uint32_t>(-1),          // -1
        INT32_MAX,                          // INT32_MAX
        static_cast<uint32_t>(INT32_MIN),   // INT32_MIN
        0,                                  // 0.0
        123,                                // 123.45
        static_cast<uint32_t>(-123),        // -123.45
        INT32_MAX,                          // (double)INT32_MAX
        static_cast<uint32_t>(INT32_MIN),   // (double)INT32_MIN
        0,                                  // "0"
        static_cast<uint32_t>(-1),          // "-1"
        123,                                // "123.45"
        static_cast<uint32_t>(-123),        // "-123.45"
        static_cast<uint32_t>(INT32_MAX+1), // (string)INT32_MAX+1
        static_cast<uint32_t>(INT32_MIN-1), // (string)INT32_MIN-1
        static_cast<uint32_t>(INT64_MAX+1), // (string)INT64_MAX+1
        0,                                  // "abcd"
        1,                                  // YES
        0,                                  // NO
        0,                                  // null
        0                                   // undefined
    };
    
    _testValueConvert<uint32_t, sizeof(expected)/sizeof(expected[0])>(self, _cmd, _context, @selector(toUInt32), expected);
}

- (void)testToInt64
{
    int64_t expected[] =
    {
        0,                                  // 0
        -1,                                 // -1
        INT32_MAX,                          // INT32_MAX
        INT32_MIN,                          // INT32_MIN
        0,                                  // 0.0
        123,                                // 123.45
        -123,                               // -123.45
        INT32_MAX,                          // (double)INT32_MAX
        INT32_MIN,                          // (double)INT32_MIN
        0,                                  // "0"
        -1,                                 // "-1"
        123,                                // "123.45"
        -123,                               // -123.45
        INT32_MAX+1ll,                      // (string)INT32_MAX+1
        INT32_MIN-1ll,                      // (string)INT32_MIN-1
        INT64_MAX+1ll,                      // (string)INT64_MAX+1
        0,                                  // "abcd"
        1,                                  // YES
        0,                                  // NO
        0,                                  // null
        0                                   // undefined
    };
    
    _testValueConvert<int64_t, sizeof(expected)/sizeof(expected[0])>(self, _cmd, _context, @selector(toInt64), expected);
}

- (void)testToUInt64
{
    uint64_t expected[] =
    {
        0,                                  // 0
        static_cast<uint64_t>(-1),          // -1
        INT32_MAX,                          // INT32_MAX
        static_cast<uint64_t>(INT32_MIN),   // INT32_MIN
        0,                                  // 0.0
        123,                                // 123.45
        static_cast<uint64_t>(-123),        // -123.45
        INT32_MAX,                          // (double)INT32_MAX
        static_cast<uint64_t>(INT32_MIN),   // (double)INT32_MIN
        0,                                  // "0"
        static_cast<uint64_t>(-1),          // "-1"
        123,                                // "123.45"
        static_cast<uint64_t>(-123),        // -123.45
        static_cast<uint64_t>(INT32_MAX+1llu), // (string)INT32_MAX+1
        static_cast<uint64_t>(INT32_MIN-1llu), // (string)INT32_MIN-1
        static_cast<uint64_t>(INT64_MAX+1llu), // (string)INT64_MAX+1
        0,                                  // "abcd"
        1,                                  // YES
        0,                                  // NO
        0,                                  // null
        0                                   // undefined
    };
    
    _testValueConvert<uint64_t, sizeof(expected)/sizeof(expected[0])>(self, _cmd, _context, @selector(toUInt64), expected);
}

- (void)testToDouble
{
    double expected[] =
    {
        0,                                  // 0
        -1,                                 // -1
        INT32_MAX,                          // INT32_MAX
        INT32_MIN,                          // INT32_MIN
        0,                                  // 0.0
        123.45,                             // 123.45
        -123.45,                            // -123.45
        INT32_MAX,                          // (double)INT32_MAX
        INT32_MIN,                          // (double)INT32_MIN
        0,                                  // "0"
        -1,                                 // "-1"
        123.45,                             // "123.45"
        -123.45,                            // "-123.45"
        INT32_MAX+1ll,                      // (string)INT32_MAX+1
        INT32_MIN-1ll,                      // (string)INT32_MIN-1
        static_cast<double>(INT64_MAX+1llu), // (string)INT64_MAX+1
        NAN,                                // "abcd"
        1,                                  // YES
        0,                                  // NO
        0,                                  // null
        NAN                                 // undefined
    };
    
    _testValueConvert<double, sizeof(expected)/sizeof(expected[0])>(self, _cmd, _context, @selector(toDouble), expected);
}

- (void)testToBool
{
    BOOL expected[] =
    {
        NO,                                 // 0
        YES,                                // -1
        YES,                                // INT32_MAX
        YES,                                // INT32_MIN
        NO,                                 // 0.0
        YES,                                // 123.45
        YES,                                // -123.45
        YES,                                // (double)INT32_MAX
        YES,                                // (double)INT32_MIN
        YES,                                // "0"
        YES,                                // "-1"
        YES,                                // "123.45"
        YES,                                // "-123.45"
        YES,                                // (string)INT32_MAX+1
        YES,                                // (string)INT32_MIN-1
        YES,                                // (string)INT64_MAX+1
        YES,                                // "abcd"
        YES,                                // YES
        NO,                                 // NO
        NO,                                 // null
        NO                                  // undefined
    };
    
    _testValueConvert<BOOL, sizeof(expected)/sizeof(expected[0])>(self, _cmd, _context, @selector(toBool), expected);
}

- (void)testToString
{
    NSObject *expected[] =
    {
        @"0",                               // 0
        @"-1",                              // -1
        @"2147483647",                      // INT32_MAX
        @"-2147483648",                     // INT32_MIN
        @"0",                               // 0.0
        @"123.45",                          // 123.45
        @"-123.45",                         // -123.45
        @"2147483647",                      // (double)INT32_MAX
        @"-2147483648",                     // (double)INT32_MIN
        @"0",                               // "0"
        @"-1",                              // "-1"
        @"123.45",                          // "123.45"
        @"-123.45",                         // "-123.45"
        @"2147483648",                      // (string)INT32_MAX+1
        @"-2147483649",                     // (string)INT32_MIN-1
        @"9223372036854775808",             // (string)INT64_MAX+1
        @"abcd",                            // "abcd"
        @"true",                            // YES
        @"false",                           // NO
        @"null",                            // null
        @"undefined"                        // undefined
    };
    
    _testValueConvert<NSObject *, sizeof(expected)/sizeof(expected[0])>(self, _cmd, _context, @selector(toString), expected);
}

- (void)testToObject
{
    NSObject *expected[] =
    {
        @(0),                                 // 0
        @(-1),                                // -1
        @(INT32_MAX),                         // INT32_MAX
        @(INT32_MIN),                         // INT32_MIN
        @(0.0),                               // 0.0
        @(123.45),                            // 123.45
        @(-123.45),                           // -123.45
        @((double)INT32_MAX),                 // (double)INT32_MAX
        @((double)INT32_MIN),                 // (double)INT32_MIN
        @"0",                                 // "0"
        @"-1",                                // "-1"
        @"123.45",                            // "123.45"
        @"-123.45",                           // "-123.45"
        @"2147483648",                        // (string)INT32_MAX+1
        @"-2147483649",                       // (string)INT32_MIN-1
        @"9223372036854775808",               // (string)INT64_MAX+1
        @"abcd",                              // "abcd"
        @YES,                                 // YES
        @NO,                                  // NO
        nil,                                  // null
        nil                                   // undefined
    };
    
    _testValueConvert<NSObject *, sizeof(expected)/sizeof(expected[0])>(self, _cmd, _context, @selector(toObject), expected);
}

- (void)testEqual
{
    XJSValue *value = [XJSValue valueWithInt32:1 inContext:_context];
    XJSValue *value2 = [XJSValue valueWithString:@"1" inContext:_context];
    
    XCTAssertEqualObjects(value, value2, @"isEqual is loosely equal");
}

- (void)testLooselyEqual
{
    XJSValue *value = [XJSValue valueWithInt32:1 inContext:_context];
    XJSValue *value2 = [XJSValue valueWithString:@"1" inContext:_context];
    
    XCTAssertEqualObjects(value, value2, @" 1 == '1' should be true ");
}

- (void)testStrictlyEqual
{
    XJSValue *value = [XJSValue valueWithInt32:1 inContext:_context];
    XJSValue *value2 = [XJSValue valueWithString:@"1" inContext:_context];
    
    XCTAssertFalse([value isStrictlyEqualToValue:value2], @" 1 === '1' should be false");
}

- (void)testKeyedSubscript
{
    _value = [XJSValue valueWithNewObjectInContext:_context];
    
    XCTAssertTrue(_value[@"a"].isUndefined, @"({})['a'] should be undefined");
    
    _value[@"a"] = [XJSValue valueWithString:@"b" inContext:_context];
    
    XCTAssertEqualObjects([_value[@"a"] toString], @"b");
    
    _value[@"a"] = [XJSValue valueWithInt32:1 inContext:_context];
    
    XCTAssertEqual([_value[@"a"] toInt32], 1);
}

- (void)testKeyedSubscript2
{
    _value = [XJSValue valueWithNewObjectInContext:_context];
    
    _value[@"a"] = @"b";
    
    XCTAssertEqualObjects([_value[@"a"] toString], @"b");
    
    _value[@"a"] = @1;
    
    XCTAssertEqual([_value[@"a"] toInt32], 1);
}

- (void)testIndexedSubscript
{
    _value = [XJSValue valueWithNewArrayInContext:_context];
    
    XCTAssertTrue(_value[1].isUndefined, @"([])[1] should be undefined");
    
    _value[1] = [XJSValue valueWithString:@"b" inContext:_context];
    
    XCTAssertEqualObjects([_value[1] toString], @"b");
    
    _value[1] = [XJSValue valueWithInt32:1 inContext:_context];
    
    XCTAssertEqual([_value[1] toInt32], 1);
    
    XCTAssertTrue(_value[0].isUndefined);
    
    XCTAssertEqual([_value[@"length"] toInt32], 2, @"array length should be 2");
}

- (void)testIndexedSubscript2
{
    _value = [XJSValue valueWithNewArrayInContext:_context];
    
    _value[1] = @"b";
    
    XCTAssertEqualObjects([_value[1] toString], @"b");
    
    _value[1] = @1;
    
    XCTAssertEqual([_value[1] toInt32], 1);
    
}

- (void)testIsInstanceOf
{
    XJSValue *object = _context[@"Object"];
    XJSValue *array = _context[@"Array"];
    
    _value = [XJSValue valueWithNewObjectInContext:_context];

    XCTAssertTrue([_value isInstanceOf:object]);
    XCTAssertFalse([_value isInstanceOf:array], @"not array");
    
    _value = [XJSValue valueWithNewArrayInContext:_context];

    XCTAssertTrue([_value isInstanceOf:object]);
    XCTAssertTrue([_value isInstanceOf:array]);
}

- (void)testCallWithArguments
{
    XJSValue *ret;
    
    _value = [_context evaluateString:@"(function () { })" error:NULL];
    ret = [_value callWithArguments:nil];
    XCTAssertNotNil(ret);
    XCTAssertTrue(ret.isUndefined);
    
    _value = [_context evaluateString:@"(function () { return 1; })" error:NULL];
    ret = [_value callWithArguments:nil];
    XCTAssertNotNil(ret);
    XCTAssertEqual(ret.toInt32, 1);
    
    _value = [_context evaluateString:@"(function (a) { return a+1; })" error:NULL];
    ret = [_value callWithArguments:@[@1]];
    XCTAssertNotNil(ret);
    XCTAssertEqual(ret.toInt32, 2);
    
    _value = [_context evaluateString:@"(function (a, b) { return a+b; })" error:NULL];
    ret = [_value callWithArguments:@[@1, @2]];
    XCTAssertNotNil(ret);
    XCTAssertEqual(ret.toInt32, 3);
}

- (void)testConstructWithArguments
{
    XJSValue *ret;
    
    _value = _context[@"Array"];
    
    ret = [_value constructWithArguments:nil];
    XCTAssertNotNil(ret);
    XCTAssertTrue([ret isInstanceOf:_value], @"instanceof Array");
    XCTAssertEqual(ret[@"length"].toInt32, 0, @"array with length 0");
    
    ret = [_value constructWithArguments:@[@5]];
    XCTAssertNotNil(ret);
    XCTAssertTrue([ret isInstanceOf:_value], @"instanceof Array");
    XCTAssertEqual(ret[@"length"].toInt32, 5, @"array with length 0");
    
    ret = [_value constructWithArguments:@[@1, @2, @3, @4]];
    XCTAssertNotNil(ret);
    XCTAssertTrue([ret isInstanceOf:_value], @"instanceof Array");
    XCTAssertEqual(ret[@"length"].toInt32, 4, @"array with length 0");
}

- (void)testInvokeMethod
{
    XJSValue *ret;
    
    _value = [XJSValue valueWithDate:[NSDate dateWithTimeIntervalSince1970:0] inContext:_context];
    
    ret = [_value invokeMethod:@"getTime" withArguments:nil];
    XCTAssertNotNil(ret);
    XCTAssertEqual(ret.toInt32, 0);
    
    ret = [_value invokeMethod:@"setFullYear" withArguments:@[@2000]];
    XCTAssertNotNil(ret);
    
    ret = [_value invokeMethod:@"getFullYear" withArguments:nil];
    XCTAssertNotNil(ret);
    XCTAssertEqual(ret.toInt32, 2000);
}

- (void)testArrayLikeToArray
{
    _value = [XJSValue valueWithNewObjectInContext:_context];
    _value[@"length"] = @5;
    _value[1] = @"1";
    _value[@2] = @"2";
    _value[@"3"] = @"3";
    
    NSArray *arr = _value.toArray;
    XCTAssertNotNil(arr);
    XCTAssertEqual(arr.count, (NSUInteger)5);
    XCTAssertEqualObjects(arr, (@[[NSNull null], @"1", @"2", @"3", [NSNull null]]));
}

- (void)testNotArrayLikeToArray
{
    _value = [XJSValue valueWithNewObjectInContext:_context];
    _value[@"0"] = @"0";
    _value[@"1"] = @"1";
    
    NSArray *arr = _value.toArray;
    XCTAssertNil(arr);
}

- (void)testCreateValueCGPoint
{
    CGPoint p = {1,2.5};
    _value = [XJSValue valueWithNSValue:[NSValue valueWithBytes:&p objCType:@encode(CGPoint)] inContext:_context];
    
    XCTAssertNotNil(_value);
    XCTAssertFalse(_value.isPrimitive);
    XCTAssertEqual(_value[@"x"].toDouble, 1.0);
    XCTAssertEqual(_value[@"y"].toDouble, 2.5);
    
    NSValue *val = [_value toValueOfType:@encode(CGPoint)];
    XCTAssertNotNil(val);
    XCTAssertEqualObjects(@(val.objCType), @(@encode(CGPoint)));
    
    CGPoint p2;
    [val getValue:&p2];
    XCTAssertEqual(p, p2);
}

- (void)testCreateValueCGSize
{
    CGSize p = {1,2.5};
    _value = [XJSValue valueWithNSValue:[NSValue valueWithBytes:&p objCType:@encode(CGSize)] inContext:_context];
    
    XCTAssertNotNil(_value);
    XCTAssertFalse(_value.isPrimitive);
    XCTAssertEqual(_value[@"width"].toDouble, 1.0);
    XCTAssertEqual(_value[@"height"].toDouble, 2.5);
    
    NSValue *val = [_value toValueOfType:@encode(CGSize)];
    XCTAssertNotNil(val);
    XCTAssertEqualObjects(@(val.objCType), @(@encode(CGSize)));
    
    CGSize p2;
    [val getValue:&p2];
    XCTAssertEqual(p, p2);
}

- (void)testCreateValueCGRect
{
    CGRect p = { {1.5, 2.5}, {3.5, 4.5} };
    _value = [XJSValue valueWithNSValue:[NSValue valueWithBytes:&p objCType:@encode(CGRect)] inContext:_context];
    
    XCTAssertNotNil(_value);
    XCTAssertFalse(_value.isPrimitive);
    
    XJSValue *origin = _value[@"origin"];
    XCTAssertNotNil(origin);
    XCTAssertFalse(origin.isPrimitive);
    XCTAssertEqual(origin[@"x"].toDouble, 1.5);
    XCTAssertEqual(origin[@"y"].toDouble, 2.5);
    
    XJSValue *size = _value[@"size"];
    XCTAssertNotNil(size);
    XCTAssertFalse(size.isPrimitive);
    XCTAssertEqual(size[@"width"].toDouble, 3.5);
    XCTAssertEqual(size[@"height"].toDouble, 4.5);
    
    NSValue *val = [_value toValueOfType:@encode(CGRect)];
    XCTAssertNotNil(val);
    XCTAssertEqualObjects(@(val.objCType), @(@encode(CGRect)));
    
    CGRect p2;
    [val getValue:&p2];
    XCTAssertEqual(p, p2);
}

- (CGRect)createRectWithOrigin:(CGPoint)origin andSize:(CGSize)size
{
    return { origin, size };
}

- (void)testCallMethodWithStructType
{
    _value = [XJSValue valueWithObject:self inContext:_context];
    
    CGPoint origin = {1.5, 2};
    CGSize size = {3, 4.5};
    
    XJSValue *ret = [_value invokeMethod:@"createRectWithOrigin_andSize" withArguments:@[[NSValue valueWithBytes:&origin objCType:@encode(CGPoint)],
                                                                                         [NSValue valueWithBytes:&size objCType:@encode(CGSize)]
                                                                                         ]];
    XCTAssertNotNil(ret);
    XCTAssertFalse(ret.isPrimitive);
    
    XJSValue *originVal = ret[@"origin"];
    XCTAssertNotNil(originVal);
    XCTAssertFalse(originVal.isPrimitive);
    XCTAssertEqual(originVal[@"x"].toDouble, 1.5);
    XCTAssertEqual(originVal[@"y"].toDouble, 2.0);
    
    XJSValue *sizeVal = ret[@"size"];
    XCTAssertNotNil(sizeVal);
    XCTAssertFalse(sizeVal.isPrimitive);
    XCTAssertEqual(sizeVal[@"width"].toDouble, 3.0);
    XCTAssertEqual(sizeVal[@"height"].toDouble, 4.5);
    
    NSValue *val = [ret toValueOfType:@encode(CGRect)];
    XCTAssertNotNil(val);
    XCTAssertEqualObjects(@(val.objCType), @(@encode(CGRect)));
    
    CGRect rect;
    [val getValue:&rect];
    XCTAssertEqual(CGRectMake(1.5, 2, 3, 4.5), rect);

}

- (void)testDeleteProperty
{
    _value = [XJSValue valueWithNewObjectInContext:_context];
    
    XCTAssertTrue([_value deleteProperty:@"a"], "delete _value.a === true");
    
    _value[@"a"] = @1;
    
    XCTAssertEqual(_value[@"a"].toInt32, 1, "_value.a === 1");
    XCTAssertTrue([_value deleteProperty:@"b"], "delete _value.b === true");
    XCTAssertEqual(_value[@"a"].toInt32, 1, "_value.a === 1");
    
    XCTAssertTrue([_value deleteProperty:@"a"], "delete _value.a === true");
    XCTAssertTrue(_value[@"a"].isUndefined, "_value.a === undefined");
    XCTAssertTrue([_value deleteProperty:@"a"], "delete _value.a === true");
}

- (void)testDeleteElement
{
    _value = [XJSValue valueWithNewArrayInContext:_context];
    
    XCTAssertTrue([_value deleteElementAtIndex:1], "delete _value[1] === true");
    
    _value[1] = @1;
    
    XCTAssertEqual(_value[1].toInt32, 1, "_value[1] === 1");
    XCTAssertTrue([_value deleteElementAtIndex:2], "delete _value[2] === true");
    XCTAssertEqual(_value[1].toInt32, 1, "_value[1] === 1");
    
    XCTAssertTrue([_value deleteElementAtIndex:1], "delete _value[1] === true");
    XCTAssertTrue(_value[1].isUndefined, "_value[1] === undefined");
    XCTAssertTrue([_value deleteElementAtIndex:1], "delete _value[1] === true");
}

- (void)testObjectToDictionary
{
    _value = [XJSValue valueWithNewObjectInContext:_context];
    
    XCTAssertEqualObjects(_value.toDictionary, @{}, "empty object to empty dict");
    
    _value[1] = @2;
    _value[@"key"] = @"value";
    _value[@"obj"] = [XJSValue valueWithNewObjectInContext:_context];
    
    NSDictionary *expected = @{ @"1" : @2,
                                @"key" : @"value",
                                @"obj" : @{}
                                };
    
    XCTAssertEqualObjects(_value.toDictionary, expected);
}

- (void)testArrayToDictionary
{
    _value = [XJSValue valueWithNewArrayInContext:_context];
    
    _value[0] = @"a";
    _value[2] = @42;
    
    NSDictionary *expected = @{ @"0" : @"a",
                                @"2" : @42
                                };

    XCTAssertEqualObjects(_value.toDictionary, expected);
}

@end
