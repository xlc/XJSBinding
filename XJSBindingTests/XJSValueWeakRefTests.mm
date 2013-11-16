//
//  XJSValueWeakRefTests.mm
//  XJSBinding
//
//  Created by Xiliang Chen on 13-10-22.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "XJSValueWeakRef.h"
#import "XJSContext_Private.hh"
#import "XJSValue_Private.hh"
#import "XJSRuntime.h"

@interface XJSValueWeakRefTests : XCTestCase

@end

@implementation XJSValueWeakRefTests
{
    XJSContext *_context;
    XJSValueWeakRef *_ref;
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

- (void)testWeakRef
{
    @autoreleasepool {
        XJSValue *value = [XJSValue valueWithNewObjectInContext:_context];
        _ref = [value weakReference];
        XCTAssertNotNil(_ref);
        
        XCTAssertEqualObjects(_ref.value, value);
    }
    
    [_context.runtime gc];
    
    XCTAssertNil(_ref.value, "should be released");
}

- (void)testRetainedByJSValue
{
    @autoreleasepool {
        
        @autoreleasepool {
            XJSValue *value = [XJSValue valueWithNewObjectInContext:_context];
            
            _ref = [value weakReference];
            XCTAssertNotNil(_ref);
            
            XCTAssertEqualObjects(_ref.value, value);
        }
        
        XCTAssertNotNil(_ref.value, "should not be released");
    }
    
    [_context.runtime gc];
    
    XCTAssertNil(_ref.value, "should be released");
}

@end
