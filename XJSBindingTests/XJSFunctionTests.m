//
//  XJSFunctionTests.m
//  XJSBinding
//
//  Created by Xiliang Chen on 14-3-16.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "XJSFunction.h"
#import "XJSValue.h"
#import "XJSContext.h"

@interface XJSFunctionTests : XCTestCase

@end

@implementation XJSFunctionTests
{
    XJSFunction *_func;
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    _func = nil;
    
    [super tearDown];
}

- (void)testFunctionWithBlock
{
    __block int callcount = 0;
    _func = [XJSFunction functionWithBlock:^id(NSArray *args) {
        callcount++;
        return [[args reverseObjectEnumerator] allObjects];
    }];
    
    {
        NSArray *ret = [_func call];
        XCTAssertEqual(ret.count, 0);
        XCTAssertEqual(callcount, 1);
        
        ret = [_func callWithArguments:@[@1, @"test"]];
        XCTAssertEqualObjects(ret, (@[@"test", @1]));
        XCTAssertEqual(callcount, 2);
    }
 
    {
        XJSContext *cx = [[XJSContext alloc] init];
        [cx createObjCRuntimeWithNamespace:nil];
        XJSValue *val = [_func xjs_toValueInContext:cx];
        
        XJSValue *ret = [val call];
        XCTAssertEqual(ret[@"length"].toInt32, 0);
        XCTAssertEqual(callcount, 3);
        
        ret = [val callWithArguments:@[@1, @"test"]];
        XCTAssertEqualObjects(ret.toArray, (@[@"test", @1]));
        XCTAssertEqual(callcount, 4);
        
        XJSFunction *func2 = val.toObject;
        XCTAssertEqualObjects(_func, func2);
    }
    
}

- (void)testFunctionWithValue
{
    XJSContext *cx = [[XJSContext alloc] init];
    
    XJSValue *funcval = [cx evaluateString:@"callcount=0;f=function(){callcount++;return Array.prototype.slice.call(arguments).reverse()}" error:NULL];
    
    _func = [XJSFunction functionWithXJSValue:funcval];
    
    {
        NSArray *ret = [_func call];
        XCTAssertEqual(ret.count, 0);
        XCTAssertEqual(cx[@"callcount"].toInt32, 1);
        
        ret = [_func callWithArguments:@[@1, @"test"]];
        XCTAssertEqualObjects(ret, (@[@"test", @1]));
        XCTAssertEqual(cx[@"callcount"].toInt32, 2);
    }
    
    
    {
        XJSValue *val = [_func xjs_toValueInContext:cx];
        XCTAssertEqualObjects(val, funcval, "should get underlying value back");
        
        XJSValue *ret = [val call];
        XCTAssertEqual(ret[@"length"].toInt32, 0);
        XCTAssertEqual(cx[@"callcount"].toInt32, 3);
        
        ret = [val callWithArguments:@[@1, @"test"]];
        XCTAssertEqualObjects(ret.toArray, (@[@"test", @1]));
        XCTAssertEqual(cx[@"callcount"].toInt32, 4);
        
        XJSFunction *func2 = val.toObject;
        XCTAssertEqualObjects(_func, func2);
    }
}

@end
