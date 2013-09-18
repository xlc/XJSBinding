//
//  XJSContextTests.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-9.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "XLCUtils.h"

#import "NSError+XJSError.h"

#import "XJSContext_Private.h"
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
    [@"\n\n!" writeToFile:path atomically:YES encoding:NSUTF16StringEncoding error:NULL];
    
    NSError *error;
    XJSValue *value = [_context evaluateScriptFile:path encoding:NSUTF16StringEncoding error:&error];
    
    XCTAssertNotNil(error, @"should have error");
    XCTAssertNil(value, @"should have no result");
    
    NSUInteger lineno = [error.userInfo[XJSErrorLineNumberKey] unsignedIntegerValue];
    XCTAssertEqual(lineno, (NSUInteger)2, @"line number should be 2");
    
    NSString *filename = error.userInfo[XJSErrorFileNameKey];
    XCTAssertEqualObjects(filename, path, @"file name should same");
    
    NSString *message = error.userInfo[XJSErrorMessageKey];
    XCTAssertEqualObjects(message, @"SyntaxError: syntax error", @"should be syntax error");

}

@end
