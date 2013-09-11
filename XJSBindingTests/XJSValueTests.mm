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

@implementation XJSValueTests {
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

- (void)testInitWithObject
{
    __weak id weakContext;
    @autoreleasepool {
        [self _setUp];
        weakContext = _context;
        
        JSObject *obj = JS_NewObject(_cx, NULL, NULL, NULL);
        
        XJSValue *value = [[XJSValue alloc] initWithContext:_context JSObject:obj];
        
        XCTAssertEqual(value.object, obj, @"should assign object");
        XCTAssertEqual(value.context, _context, @"context should be same");
        XJSAssertEqualValue(_cx, OBJECT_TO_JSVAL(obj), value.value, @"value should be same");
        
        [self _tearDown];
    }
    
    XCTAssertNil(weakContext, @"should be released");
}

@end
