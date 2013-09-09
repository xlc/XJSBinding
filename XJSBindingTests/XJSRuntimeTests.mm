//
//  XJSRuntimeTests.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-8.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "XLCTestUtils.h"

#import "XJSRuntime_Private.h"

@interface XJSRuntimeTests : XCTestCase

@end

@implementation XJSRuntimeTests

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
    __weak XJSRuntime *weakRuntime;
    @autoreleasepool {
        XJSRuntime *runtime = [[XJSRuntime alloc] init];
        weakRuntime = runtime;
        
        XCTAssertNotNil(runtime.thread, @"should have thread");
        XLCAssertTrueBeforeTimeout(runtime.runtime != NULL, 1, @"should be assigned to a JSRuntime");
    }
    
    XCTAssertNil(weakRuntime, @"should not have retain cycle");
}

- (void)testPerformBlock
{
    XJSRuntime *runtime = [[XJSRuntime alloc] init];
    
    __block BOOL executed = NO;
    __block NSThread *executeThread;
    
    [runtime performBlock:^{
        executeThread = [NSThread currentThread];
        executed = YES;
    }];
    
    XLCAssertTrueBeforeTimeout(executed, 1, @"should perform block");
    XCTAssertEqualObjects(executeThread, runtime.thread, @"should be on runtime thread");
}

- (void)testPerformBlockAndWait
{
    XJSRuntime *runtime = [[XJSRuntime alloc] init];
    
    __block BOOL executed = NO;
    __block NSThread *executeThread;
    
    [runtime performBlockAndWait:^{
        [NSThread sleepForTimeInterval:0.01];   // so main thread have to wait for some amount of time
        executeThread = [NSThread currentThread];
        executed = YES;
    }];
    
    XCTAssertTrue(executed, @"should be executed by now");
    XCTAssertEqualObjects(executeThread, runtime.thread, @"should be on runtime thread");
}

@end
