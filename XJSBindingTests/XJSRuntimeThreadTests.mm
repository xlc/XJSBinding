//
//  XJSRuntimeThreadTests.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-8.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "OCMock.h"
#import "XLCTestUtils.h"

#import "XJSRuntimeThread.h"
#import "XJSRuntime_Private.h"

@interface XJSRuntimeThreadTests : XCTestCase

@end

@implementation XJSRuntimeThreadTests

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
    __weak id weakRuntime;
    XJSRuntimeThread *strongThread;
    
    @autoreleasepool {
        id runtime = [OCMockObject mockForClass:[XJSRuntime class]];
        weakRuntime = runtime;
        
        [[[runtime expect] andDo:^(NSInvocation *invocation) {
            void *arg1 = NULL;
            [invocation getArgument:&arg1 atIndex:2];
            XCTAssert(arg1 != NULL, @"should not set runtime to NULL");
        }] setRuntime:(JSRuntime *) [OCMArg anyPointer]];
        
        XJSRuntimeThread *thread = [[XJSRuntimeThread alloc] initWithRuntime:runtime];
        strongThread = thread;
        
        XCTAssertFalse([thread isExecuting], @"thread should not be started");
    }
    
    XCTAssertNil(weakRuntime, @"XJSRuntime should not be retained by XJSRuntimeThread");
}

- (void)testCreateJSRuntime
{
    __block BOOL assignOK = NO;
    __block BOOL removeOK = NO;
    
    id runtime = [OCMockObject mockForClass:[XJSRuntime class]];
    
    [[[runtime expect] andDo:^(NSInvocation *invocation) {
        void *arg1 = NULL;
        [invocation getArgument:&arg1 atIndex:2];
        
        if (arg1 != NULL) {
            assignOK = YES;
        }
        
    }] setRuntime:(JSRuntime *) [OCMArg anyPointer]];
    
    [[[runtime expect] andDo:^(NSInvocation *invocation) {
        void *arg1 = NULL;
        [invocation getArgument:&arg1 atIndex:2];
        
        if (arg1 == NULL) {
            removeOK = YES;
        }
        
    }] setRuntime:(JSRuntime *) [OCMArg anyPointer]];
    
    XJSRuntimeThread *thread = [[XJSRuntimeThread alloc] initWithRuntime:runtime];
    
    [thread start];
    
    XLCAssertTrueBeforeTimeout([thread isExecuting], 1, @"thread should be executing");
    XLCAssertTrueBeforeTimeout(assignOK, 1, @"JSRuntime should be created and assigned");
    
    [thread stop];
    
    XLCAssertTrueBeforeTimeout([thread isFinished], 1, @"thread should be finished");
    XCTAssertTrue(removeOK, @"JSRuntime should be destroy and removed");
    
    [runtime verify];
}

@end
