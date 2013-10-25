//
//  XJSWeakMapTests.mm
//  XJSBinding
//
//  Created by Xiliang Chen on 13-10-19.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "jsapi.h"
#import "jsfriendapi.h"
#import "XJSConvert.h"

#import "XJSContext_Private.h"
#import "XJSWeakMap.h"
#import "XJSValue_Private.h"
#import "XJSRuntime_Private.h"

@interface XJSWeakMapTests : XCTestCase

@end

@implementation XJSWeakMapTests
{
    XJSContext *_context;
    XJSWeakMap *_map;
}

- (void)setUp
{
    [super setUp];
    
    _context = [[XJSContext alloc] init];
    _map = [[XJSWeakMap alloc] initWithContext:_context];
}

- (void)tearDown
{
    _context = nil;
    
    [super tearDown];
}

- (void)testSetAndGet
{
    XJSValue *val = [XJSValue valueWithNewObjectInContext:_context];
    XJSValue *key = [XJSValue valueWithNewObjectInContext:_context];
    
    _map[key] = val;
    
    XCTAssertEqualObjects([_map allKeys][0], key);
    XCTAssertTrue([val isStrictlyEqualToValue:_map[key]]);
    
    XJSValue *val2 = [XJSValue valueWithNewObjectInContext:_context];
    _map[key] = val2;
    
    XCTAssertEqualObjects([_map allKeys][0], key);
    XCTAssertTrue([val2 isStrictlyEqualToValue:_map[key]]);
    
    [_map removeObjectForKey:key];
    XCTAssertEqual([_map allKeys][@"length"].toInt32, 0);
    XCTAssertTrue(_map[key].isUndefined);
}

- (void)testRemoveAll
{
    XJSValue *val = [XJSValue valueWithNewObjectInContext:_context];
    XJSValue *key = [XJSValue valueWithNewObjectInContext:_context];
    
    _map[key] = val;
    
    XJSValue *val2 = [XJSValue valueWithNewObjectInContext:_context];
    XJSValue *key2 = [XJSValue valueWithNewObjectInContext:_context];
    
    _map[key2] = val2;
    
    XCTAssertEqual([_map allKeys][@"length"].toInt32, 2);
    XCTAssertTrue([val isStrictlyEqualToValue:_map[key]]);
    XCTAssertTrue([val2 isStrictlyEqualToValue:_map[key2]]);
    
    [_map removeAllObjects];
    
    XCTAssertEqual([_map allKeys][@"length"].toInt32, 0);
    XCTAssertTrue(_map[key].isUndefined);
    XCTAssertTrue(_map[key2].isUndefined);
}

- (void)testWeakRef
{
    XJSValue *val = [XJSValue valueWithNewObjectInContext:_context];
    
    @autoreleasepool {
        XJSValue *key = [XJSValue valueWithNewObjectInContext:_context];
        
        [_map setObject:val forKey:key];
    }

    @autoreleasepool {
        XCTAssertEqual([_map allKeys][@"length"].toInt32, 1);
    }
    
    [_context.runtime gc];
    
    XCTAssertEqual([_map allKeys][@"length"].toInt32, 0);
    
}

- (void)testWeakRef2
{
    XJSValue *val = [XJSValue valueWithNewObjectInContext:_context];
    
    @autoreleasepool {
        XJSValue *key = [XJSValue valueWithNewObjectInContext:_context];
        
        _map[key] = val;
    }
    
    @autoreleasepool {
        XCTAssertEqual([_map allKeys][@"length"].toInt32, 1);
    }
    
    [_context.runtime gc];
    
    XCTAssertEqual([_map allKeys][@"length"].toInt32, 0);
    
}

@end
