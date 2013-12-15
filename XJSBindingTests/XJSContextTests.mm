//
//  XJSContextTests.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-9.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "XLCUtils.h"

#import "NSError_XJSErrorConstants.h"

#import "XJSContext_Private.hh"
#import "XJSValue.h"

@interface XJSContextTests : XCTestCase

@end

@implementation XJSContextTests
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

- (void)testInit
{
    __weak XJSContext *weakContext;
    JSContext *jscontext;
    @autoreleasepool {
        XJSContext *context = [[XJSContext alloc] init];
        weakContext = context;
        
        jscontext = context.context;
        
        XCTAssert(jscontext != NULL, @"should have JSContext");
        XCTAssertNotNil(context.runtime, @"should have runtime");
        
        XCTAssertEqual([XJSContext contextForJSContext:jscontext], context, @"should match");
    }
    
    XCTAssertNil(weakContext, @"should not have retain cycle");
    XCTAssertNil([XJSContext contextForJSContext:jscontext], @"should find nothing");
}

- (void)testEvalutateString
{
    NSError *error;
    XJSValue *value = [_context evaluateString:@"1+1" error:&error];
    
    XCTAssertNil(error, @"should have no error");
    XCTAssertEqual([value toInt32], 2, @"1+1 should be 2");
}

- (void)testEvaluateStringWithError
{
    NSError *error;
    XJSValue *value = [_context evaluateString:@"1+" error:&error];
    
    XCTAssertNotNil(error, @"should have error");
    XCTAssertNil(value, @"should have no result");
    
    NSUInteger lineno = [error.userInfo[XJSErrorLineNumberKey] unsignedIntegerValue];
    XCTAssertEqual(lineno, (NSUInteger)0, @"line number should be 0");
    
    NSString *filename = error.userInfo[XJSErrorFileNameKey];
    XCTAssertEqual([filename length], (NSUInteger)0, @"should have no filename");
    
    NSString *message = error.userInfo[XJSErrorMessageKey];
    XCTAssertEqualObjects(message, @"SyntaxError: syntax error", @"should be syntax error");
}

- (void)testEvaluateStringWithError2
{
    NSError *error;
    XJSValue *value = [_context evaluateString:@"\n1+" fileName:@"file" lineNumber:1 error:&error];
    
    XCTAssertNotNil(error, @"should have error");
    XCTAssertNil(value, @"should have no result");
    
    NSUInteger lineno = [error.userInfo[XJSErrorLineNumberKey] unsignedIntegerValue];
    XCTAssertEqual(lineno, (NSUInteger)2, @"line number should be 2");
    
    NSString *filename = error.userInfo[XJSErrorFileNameKey];
    XCTAssertEqualObjects(filename, @"file", @"file name should same");
    
    NSString *message = error.userInfo[XJSErrorMessageKey];
    XCTAssertEqualObjects(message, @"SyntaxError: syntax error", @"should be syntax error");
}

- (void)testEvaluateScriptFile
{
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test.js"];
    [@"1+1" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    
    NSError *error;
    XJSValue *value = [_context evaluateScriptFile:path error:&error];
    
    XCTAssertNil(error, @"should have no error");
    XCTAssertEqual([value toInt32], 2, @"1+1 should be 2");
}

- (void)testEvaluateScriptFileWithError
{
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test.js"];
    [@"\n\n!" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    
    NSError *error;
    XJSValue *value = [_context evaluateScriptFile:path error:&error];
    
    XCTAssertNotNil(error, @"should have error");
    XCTAssertNil(value, @"should have no result");
    
    NSUInteger lineno = [error.userInfo[XJSErrorLineNumberKey] unsignedIntegerValue];
    XCTAssertEqual(lineno, (NSUInteger)2, @"line number should be 2");
    
    NSString *filename = error.userInfo[XJSErrorFileNameKey];
    XCTAssertEqualObjects(filename, path, @"file name should same");
    
    NSString *message = error.userInfo[XJSErrorMessageKey];
    XCTAssertEqualObjects(message, @"SyntaxError: syntax error", @"should be syntax error");

}

- (void)testEvaluateWithScope
{
    XJSValue *scope = [XJSValue valueWithNewObjectInContext:_context];
    
    NSError *error;
    XJSValue *value;
    
    [_context evaluateString:@"var a=1; var b=2;" withScope:scope error:&error];

    value = [_context evaluateString:@"this" withScope:scope error:&error];
    
    XCTAssertNil(error);
    
    XCTAssertEqual(scope[@"a"].toInt32, 1, "should assign to scope");
    XCTAssertEqual(scope[@"b"].toInt32, 2, "should assign to scope");
    XCTAssertTrue(_context[@"a"].isUndefined, "should not touch global scope");
    XCTAssertTrue(_context[@"b"].isUndefined, "should not touch global scope");
    
    _context[@"a"] = @3;
    _context[@"b"] = @4;
    
    value = [_context evaluateString:@"[a, b];" withScope:scope error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(value);
    XCTAssertEqual(value[0].toInt32, 1, "should use value from scope object not global");
    XCTAssertEqual(value[1].toInt32, 2, "should use value from scope object not global");
    
    value = [_context evaluateString:@"[a, b];" withScope:nil error:&error];
    
    XCTAssertNil(error);
    XCTAssertNotNil(value);
    XCTAssertEqual(value[0].toInt32, 3, "should use global scope");
    XCTAssertEqual(value[1].toInt32, 4, "should use global scope");
}

- (void)testKeyedSubscript
{
    XJSValue *value;
    
    value = _context[@"a"];
    XCTAssertNotNil(value);
    XCTAssertTrue(value.isUndefined);
    
    [_context evaluateString:@"a=1" error:NULL];
    
    value = _context[@"a"];
    XCTAssertNotNil(value);
    XCTAssertEqual(value.toInt32, 1);
    
    _context[@"a"] = [XJSValue valueWithInt32:2 inContext:_context];
    
    value = _context[@"a"];
    XCTAssertNotNil(value);
    XCTAssertEqual(value.toInt32, 2);
}

- (void)testKeyedSubscript2
{
    XJSValue *value;
    
    _context[@"a"] = @2;
    
    value = _context[@"a"];
    XCTAssertNotNil(value);
    XCTAssertEqual(value.toInt32, 2);
}

- (void)testKeyedSubscriptGetNamespace
{
    XJSValue *value;
    
    value = _context[@"a.b.c"];
    XCTAssertNotNil(value);
    XCTAssertTrue(value.isUndefined);
    
    value = _context[@"a.b"];
    XCTAssertNotNil(value);
    XCTAssertTrue(value.isUndefined);
    
    value = _context[@"a"];
    XCTAssertNotNil(value);
    XCTAssertTrue(value.isUndefined);
}

- (void)testKeyedSubscriptSetNamespace
{
    XJSValue *value;
    
    _context[@"a.b.c"] = @42;
    
    value = _context[@"a.b.c"];
    XCTAssertNotNil(value);
    XCTAssertEqual(value.toInt32, 42);
    
    value = _context[@"a.b"];
    XCTAssertNotNil(value);
    XCTAssertFalse(value.isPrimitive);
    XCTAssertEqual(value[@"c"].toInt32, 42);
    
    value = _context[@"a"];
    XCTAssertNotNil(value);
    XCTAssertFalse(value.isPrimitive);
    XCTAssertEqual(value[@"b"][@"c"].toInt32, 42);
    
    _context[@"a.a"] = @"test";
    
    value = _context[@"a.b.c"];
    XCTAssertNotNil(value);
    XCTAssertEqual(value.toInt32, 42);
    
    value = _context[@"a.a"];
    XCTAssertNotNil(value);
    XCTAssertEqualObjects(value.toString, @"test");
    
    value = _context[@"a"];
    XCTAssertNotNil(value);
    XCTAssertFalse(value.isPrimitive);
    XCTAssertEqual(value[@"b"][@"c"].toInt32, 42);
    XCTAssertEqualObjects(value[@"a"].toString, @"test");
}

- (void)testCreateObjCRuntimeWithNamespace
{
    [_context createObjCRuntimeWithNamespace:@"a.b.c"];
    XJSValue *value = _context[@"a.b.c.NSObject"];
    XCTAssertNotNil(value);
    XCTAssertTrue(value.isObject);
    XCTAssertEqualObjects(value.toObject, [NSObject class]);
}

@end
