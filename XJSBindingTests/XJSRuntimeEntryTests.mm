//
//  XJSRuntimeEntryTests.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-30.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "XJSContext.h"
#import "XJSValue.h"

@interface XJSRuntimeEntryTests : XCTestCase

@end

@implementation XJSRuntimeEntryTests
{
    XJSContext *_context;
    XJSValue *_objc;
}

- (void)setUp
{
    [super setUp];
    
    _context = [[XJSContext alloc] init];
    [_context createObjCRuntimeWithNamespace:@"objc"];
    _objc = _context[@"objc"];
}

- (void)tearDown
{
    _context = nil;
    
    [super tearDown];
}

- (void)testNamespaceCreate
{
    XCTAssertTrue(!_objc.isPrimitive, @"");
    
    XCTAssertEqualObjects(_objc.toString, @"[object XJSRuntimeEntry]", @"");
}

- (void)testRuntimeEntryCannotSet
{
    _objc[@"_non_exist_"] = @1;
    
    XJSValue *value = _objc[@"_non_exist_"];
    XCTAssertTrue(value.isUndefined, @"");
}

- (void)testRuntimeEntryGet
{
    XJSValue *value = _objc[@"_non_exist_"];
    XCTAssertTrue(value.isUndefined, @"");
    
    value = _objc[@"NSObject"];
    XCTAssertTrue(value.isObject, @"");
    
    XCTAssertEqualObjects(value.toObject, [NSObject class], @"");
}

@end
