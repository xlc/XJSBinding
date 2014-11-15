//
//  XJSReflectTests.m
//  XJSBinding
//
//  Created by Xiliang Chen on 14/11/15.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "XJSContext.h"
#import "XJSValue.h"

@interface XJSReflectTests : XCTestCase

@end

@implementation XJSReflectTests {
    XJSContext *_context;
}

- (void)setUp {
    [super setUp];
    
    _context = [[XJSContext alloc] init];
    [_context createModuleManager];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testRequireReflect {
    
    XCTAssert(_context[@"Reflect"].isUndefined);
    
    NSError *err = nil;
    [_context evaluateString:@"var r = require('xjs/reflect')" error:&err];
    
    XCTAssertNil(err);
    
    XCTAssertFalse(_context[@"r"].isPrimitive);
    XCTAssert(_context[@"r"][@"parse"].isCallable);
    
    XCTAssert(_context[@"Reflect"].isUndefined);
}

@end
