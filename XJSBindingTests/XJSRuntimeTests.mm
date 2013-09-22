//
//  XJSRuntimeTests.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-8.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "XLCUtils.h"

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
        
        XCTAssertNotEqual(runtime.runtime, NULL, @"should be assigned to a JSRuntime");
    }
    
    XCTAssertNil(weakRuntime, @"should not have retain cycle");
}

- (void)testPerformBlock
{
    XJSRuntime *runtime = [[XJSRuntime alloc] init];
    
    __block int executed = 0;
    
    [runtime performBlock:^{
        executed++;
    }];
    
    XCTAssertEqual(executed, 1, @"should perform block once");
}

- (void)testPerformBlockNested
{
    __weak XJSRuntime *weakRuntime;
    
    __block int executed = 0;
    
    @autoreleasepool {
        XJSRuntime *runtime = [[XJSRuntime alloc] init];
        weakRuntime = runtime;
        
        [runtime performBlock:^{
            [runtime performBlock:^{
                [runtime performBlock:^{
                    [runtime performBlock:^{
                        executed++;
                    }];
                }];
            }];
        }];
        XCTAssertEqual(executed, 1, @"should perform block once");
    }

    XCTAssertNil(weakRuntime, @"should not have retain cycle");
    
}

@end
