//
//  XJSContextTests.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-9.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "XLCUtils.h"

#import "XJSContext_Private.h"

@interface XJSContextTests : XCTestCase

@end

@implementation XJSContextTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
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
    XJSContext *context = [[XJSContext alloc] init];
    
    NSError *error;
    XJSValue *value = [context evaluateString:@"1+1" error:&error];
    
    XCTAssertNil(error, @"should have no error");
    XCTAssertNotNil(value, @"should have value");
}

@end
