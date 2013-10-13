//
//  XJSClassTests.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-10-2.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <objc/runtime.h>

#import "jsapi.h"

#import "XJSClass.h"
#import "XJSConvert.h"
#import "XJSContext_Private.h"
#import "XJSValue_Private.h"

@interface XJSClassTests : XCTestCase

@end

@implementation XJSClassTests
{
    XJSContext *_context;
}

- (void)setUp
{
    [super setUp];
    
    _context = [[XJSContext alloc] init];
}

- (void)tearDown
{
    _context = nil;
    
    [super tearDown];
}

- (void)testCreateClassObject
{
    id clsobj = [NSObject class];
    
    JSObject *jsobj = XJSCreateJSObject(_context.context, clsobj);
    
    XCTAssertEqualObjects(XJSGetAssosicatedObject(jsobj), clsobj, @"");
    
    NSString *str = XJSConvertJSValueToString(_context.context, JS::ObjectOrNullValue(jsobj));
    
    XCTAssertEqualObjects(str, @"[object NSObject]", @"");
}

- (void)testCreateInstanceObject
{
    __weak id weakobj;
    @autoreleasepool {
        id obj = [[NSObject alloc] init];
        weakobj = obj;
        
        JSObject *jsobj = XJSCreateJSObject(_context.context, obj);
        
        XCTAssertEqualObjects(XJSGetAssosicatedObject(jsobj), obj, @"");
        
        NSString *str = XJSConvertJSValueToString(_context.context, JS::ObjectOrNullValue(jsobj));
        
        XCTAssertEqualObjects(str, @"[object NSObject]", @"");
    }
    
    XCTAssertNotNil(weakobj, @"should be retained by context");
    
    _context = nil; // somehow [_context.runtime gc] does not finalize the js object
    
    XCTAssertNil(weakobj, @"should be released by context");
}

- (void)testCallMethodNoArgument
{
    id obj = @"test";
    
    JSObject *jsobj = XJSCreateJSObject(_context.context, obj);
    
    XJSValue *val = [[XJSValue alloc] initWithContext:_context value:JS::ObjectOrNullValue(jsobj)];
    
    XJSValue *ret = [val invokeMethod:@"length" withArguments:nil];
    XCTAssertNotNil(ret, @"");
    XCTAssertEqual(ret.toInt32, 4, @"");
    
    ret = [val invokeMethod:@"description" withArguments:nil];
    XCTAssertNotNil(ret, @"");
    XCTAssertEqualObjects(ret.toString, @"test", @"");
}

@end
