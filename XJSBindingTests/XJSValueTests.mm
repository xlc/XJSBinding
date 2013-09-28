//
//  XJSValueTests.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-11.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "XJSTestUtils.h"
#import "XJSConvert.h"

#import "XJSValue_Private.h"
#import "XJSContext_Private.h"
#import "XJSRuntime.h"

@interface XJSValueTests : XCTestCase

@end

@implementation XJSValueTests
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

template <typename T>
void _assertEqual(id self, T actual, T expected, SEL selToTest)
{
    XCTAssertEqual(actual, expected, @"failed selector: %@", NSStringFromSelector(selToTest));
}

// for NSString
template <typename NSString>
void _assertEqual(id self, NSString * actual, NSString * expected, SEL selToTest)
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
#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR // FIXME: cast negative double to int have different result on ios device
        0,                                  // -123.45
#else
        -123,                               // -123.45
#endif
        INT32_MAX,                          // (double)INT32_MAX
        INT32_MIN,                          // (double)INT32_MIN
        0,                                  // "0"
        -1,                                 // "-1"
        123,                                // "123.45"
#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR // FIXME: cast negative double to int have different result on ios device
        0,                                  // -123.45
#else
        -123,                               // -123.45
#endif
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
#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR // FIXME: cast negative double to int have different result on ios device
        static_cast<uint64_t>(-123.45),     // -123.45
#else
        static_cast<uint64_t>(-123),        // -123.45
#endif
        INT32_MAX,                          // (double)INT32_MAX
        static_cast<uint64_t>(INT32_MIN),   // (double)INT32_MIN
        0,                                  // "0"
        static_cast<uint64_t>(-1),          // "-1"
        123,                                // "123.45"
#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR // FIXME: cast negative double to int have different result on ios device
        static_cast<uint64_t>(-123.45),     // -123.45
#else
        static_cast<uint64_t>(-123),        // -123.45
#endif
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
    NSString *expected[] =
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
    
    _testValueConvert<NSString *, sizeof(expected)/sizeof(expected[0])>(self, _cmd, _context, @selector(toString), expected);
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
    
    XCTAssertEqualObjects([_value[@"a"] toString], @"b", @"");
    
    _value[@"a"] = [XJSValue valueWithInt32:1 inContext:_context];
    
    XCTAssertEqual([_value[@"a"] toInt32], 1, @"");
}

- (void)testIndexedSubscript
{
    _value = [XJSValue valueWithNewArrayInContext:_context];
    
    XCTAssertTrue(_value[1].isUndefined, @"([])[1] should be undefined");
    
    _value[1] = [XJSValue valueWithString:@"b" inContext:_context];
    
    XCTAssertEqualObjects([_value[1] toString], @"b", @"");
    
    _value[1] = [XJSValue valueWithInt32:1 inContext:_context];
    
    XCTAssertEqual([_value[1] toInt32], 1, @"");
    
    XCTAssertTrue(_value[0].isUndefined, @"");
    
    XCTAssertEqual([_value[@"length"] toInt32], 2, @"array length should be 2");
}

- (void)testIsInstanceOf
{
    XJSValue *object = [_context evaluateString:@"Object" error:NULL];
    XJSValue *array = [_context evaluateString:@"Array" error:NULL];
    
    _value = [XJSValue valueWithNewObjectInContext:_context];

    XCTAssertTrue([_value isInstanceOf:object], @"");
    XCTAssertFalse([_value isInstanceOf:array], @"not array");
    
    _value = [XJSValue valueWithNewArrayInContext:_context];

    XCTAssertTrue([_value isInstanceOf:object], @"");
    XCTAssertTrue([_value isInstanceOf:array], @"");
}

- (void)testCallWithArguments
{
    XJSValue *ret;
    
    _value = [_context evaluateString:@"(function () { })" error:NULL];
    ret = [_value callWithArguments:nil];
    XCTAssertNotNil(ret, @"");
    XCTAssertTrue(ret.isUndefined, @"");
    
    _value = [_context evaluateString:@"(function () { return 1; })" error:NULL];
    ret = [_value callWithArguments:nil];
    XCTAssertNotNil(ret, @"");
    XCTAssertEqual(ret.toInt32, 1, @"");
    
    _value = [_context evaluateString:@"(function (a) { return a+1; })" error:NULL];
    ret = [_value callWithArguments:@[@1]];
    XCTAssertNotNil(ret, @"");
    XCTAssertEqual(ret.toInt32, 2, @"");
    
    _value = [_context evaluateString:@"(function (a, b) { return a+b; })" error:NULL];
    ret = [_value callWithArguments:@[@1, @2]];
    XCTAssertNotNil(ret, @"");
    XCTAssertEqual(ret.toInt32, 3, @"");
}

- (void)testConstructWithArguments
{
    XJSValue *ret;
    
    _value = [_context evaluateString:@"Array" error:NULL];
    
    ret = [_value constructWithArguments:nil];
    XCTAssertNotNil(ret, @"");
    XCTAssertTrue([ret isInstanceOf:_value], @"instanceof Array");
    XCTAssertEqual(ret[@"length"].toInt32, 0, @"array with length 0");
    
    ret = [_value constructWithArguments:@[@5]];
    XCTAssertNotNil(ret, @"");
    XCTAssertTrue([ret isInstanceOf:_value], @"instanceof Array");
    XCTAssertEqual(ret[@"length"].toInt32, 5, @"array with length 0");
    
    ret = [_value constructWithArguments:@[@1, @2, @3, @4]];
    XCTAssertNotNil(ret, @"");
    XCTAssertTrue([ret isInstanceOf:_value], @"instanceof Array");
    XCTAssertEqual(ret[@"length"].toInt32, 4, @"array with length 0");
}

@end

@interface XJSValueInitTests : XCTestCase

@end

@implementation XJSValueInitTests {
    XJSContext *_context;
    JSContext *_cx;
}

- (void)_setUp
{
    _context = [[XJSContext alloc] init];
    _cx = _context.context;
}

- (void)_tearDown
{
    _cx = NULL;
    _context = nil;
}

- (void)testInitWithValue
{
    __weak id weakContext;
    @autoreleasepool {
        [self _setUp];
        weakContext = _context;
        
        jsval values[] = {
            JSVAL_NULL,
            JSVAL_ZERO,
            JSVAL_ONE,
            JSVAL_FALSE,
            JSVAL_TRUE,
            JSVAL_VOID,
            INT_TO_JSVAL(INT32_MAX),
            INT_TO_JSVAL(INT32_MIN),
            DOUBLE_TO_JSVAL(INFINITY),
            XJSConvertStringToJSValue(_cx, @"test"),
        };
        
        for (int i = 0; i < sizeof(values) / sizeof(values[0]); i++) {
            XJSValue *value = [[XJSValue alloc] initWithContext:_context value:values[i]];
            XCTAssertEqual(value.context, _context, @"context should be same");
            XJSAssertEqualValue(_cx, values[i], value.value, @"value should be same");
        }
        
        [self _tearDown];
    }
    
    XCTAssertNil(weakContext, @"should be released");
}

@end
