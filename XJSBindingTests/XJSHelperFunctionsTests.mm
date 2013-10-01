//
//  XJSHelperFunctionsTests.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-30.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <objc/runtime.h>
#import <algorithm>

#import "XJSHelperFunctions.h"

@interface _XJSHelperFunctionsTests_TestClass : NSObject

- (void)methodWithNoArguments;
- (void)methodWithArgument:(id)arg;
- (void)methodWithArgument:(id)arg :(id)arg2;
- (void)methodWithArgument:(id)arg andArgument:(id)arg2;
- (void)methodWithArgument:(id)arg andArgument:(id)arg2 :(id)arg3;

- (void)_methodWithUnderscore;
- (void)__methodWithTwoUnderscores;
- (void)_methodWithUnderscoreAndArgument:(id)arg;
- (void)_methodWithUnderscoreAndArgument:(id)arg andArgument:(id)arg2 :(id)arg3;

- (void)my_method;
- (void)my_methodWithArgument:(id)arg;
- (void)my_methodWithArgument:(id)arg andArgument:(id)arg2;

@end

@implementation _XJSHelperFunctionsTests_TestClass

- (void)methodWithNoArguments; {}
- (void)methodWithArgument:(id)arg; {}
- (void)methodWithArgument:(id)arg :(id)arg2; {}
- (void)methodWithArgument:(id)arg andArgument:(id)arg2; {}
- (void)methodWithArgument:(id)arg andArgument:(id)arg2 :(id)arg3; {}

- (void)_methodWithUnderscore; {}
- (void)__methodWithTwoUnderscores; {}
- (void)_methodWithUnderscoreAndArgument:(id)arg; {}
- (void)_methodWithUnderscoreAndArgument:(id)arg andArgument:(id)arg2; {}
- (void)_methodWithUnderscoreAndArgument:(id)arg andArgument:(id)arg2 :(id)arg3; {}

- (void)my_method; {}
- (void)my_methodWithArgument:(id)arg; {}
- (void)my_methodWithArgument:(id)arg andArgument:(id)arg2; {}

@end

@interface XJSHelperFunctionsTests : XCTestCase

@end

@implementation XJSHelperFunctionsTests
{
    id _obj;
}

- (void)setUp
{
    [super setUp];
    
    _obj = [[_XJSHelperFunctionsTests_TestClass alloc] init];
}

- (void)tearDown
{
    _obj = nil;
    
    [super tearDown];
}

void testSearchMethod(XJSHelperFunctionsTests *self, SEL _cmd, id obj, SEL expectedSel, std::initializer_list<const char *> possibleSelectorNames, std::initializer_list<const char *>shouldNotMatchSelectorNames)
{
    const char *selname = sel_getName(expectedSel);
    auto count = std::count(selname, selname + strlen(selname), ':');
    
    for (auto inputSelName : possibleSelectorNames) {
        SEL result = XJSSearchSelector(obj, inputSelName, count);
        XCTAssertEqualObjects(NSStringFromSelector(result), NSStringFromSelector(expectedSel), @"search selector name: %s", inputSelName);
        
        result = XJSSearchSelector(obj, inputSelName, count+1);
        XCTAssertNotEqualObjects(NSStringFromSelector(result), NSStringFromSelector(expectedSel), @"search selector name with count +1: %s", inputSelName);
        
        if (count != 0) {
            result = XJSSearchSelector(obj, inputSelName, count-1);
            XCTAssertNotEqualObjects(NSStringFromSelector(result), NSStringFromSelector(expectedSel), @"search selector name with count -1: %s", inputSelName);
        }
    }
    
    for (auto inputSelName : shouldNotMatchSelectorNames) {
        SEL result = XJSSearchSelector(obj, inputSelName, count);
        XCTAssertNotEqualObjects(NSStringFromSelector(result), NSStringFromSelector(expectedSel), @"search selector should not match: %s", inputSelName);
    }
}

- (void)testMethodWithNoArguments
{
    testSearchMethod(self, _cmd, _obj, @selector(methodWithNoArguments), {
        "methodWithNoArguments",
    }, {
        "methodWithNoArguments:",
        "methodWithNoArguments_",
    });
}

- (void)testMethodWithOneArgument
{
    testSearchMethod(self, _cmd, _obj, @selector(methodWithArgument:), {
        "methodWithArgument",
        "methodWithArgument:",
        "methodWithArgument_",
    }, {
        "methodWithArgument::",
        "methodWithArgument__",
    });
}

- (void)testMethodWithTwoArguments1
{
    testSearchMethod(self, _cmd, _obj, @selector(methodWithArgument::), {
        "methodWithArgument",
        "methodWithArgument::",
        "methodWithArgument__",
    }, {
        "methodWithArgument:",
        "methodWithArgument_",
        "methodWithArgument:_",
        "methodWithArgument_:",
    });
}

- (void)testMethodWithTwoArguments2
{
    testSearchMethod(self, _cmd, _obj, @selector(methodWithArgument:andArgument:), {
        "methodWithArgument_andArgument",
        "methodWithArgument_andArgument_",
        "methodWithArgument:andArgument:",
    }, {
        "methodWithArgument:andArgument",
        "methodWithArgument:andArgument_",
        "methodWithArgument_andArgument:",
    });
}

- (void)testMethodWithThreeArguments
{
    testSearchMethod(self, _cmd, _obj, @selector(methodWithArgument:andArgument::), {
        "methodWithArgument_andArgument",
        "methodWithArgument_andArgument__",
        "methodWithArgument:andArgument::",
    }, {
        "methodWithArgument:andArgument",
        "methodWithArgument:andArgument_",
        "methodWithArgument:andArgument_:",
        "methodWithArgument:andArgument__",
        "methodWithArgument_andArgument_",
        "methodWithArgument_andArgument::",
    });
}

- (void)testMethodWithUnderscore
{
    testSearchMethod(self, _cmd, _obj, @selector(_methodWithUnderscore), {
        "_methodWithUnderscore",
    }, {
        "methodWithUnderscore",
        "__methodWithUnderscore",
    });
}

- (void)testMethodWithTwoUnderscores
{
    testSearchMethod(self, _cmd, _obj, @selector(__methodWithTwoUnderscores), {
        "__methodWithTwoUnderscores",
    }, {
        "methodWithTwoUnderscores",
        "_methodWithTwoUnderscores",
    });
}

- (void)testMethodWithUnderscoreAndArgument
{
    testSearchMethod(self, _cmd, _obj, @selector(_methodWithUnderscoreAndArgument:), {
        "_methodWithUnderscoreAndArgument",
        "_methodWithUnderscoreAndArgument:",
        "_methodWithUnderscoreAndArgument_",
    }, {
        "methodWithUnderscoreAndArgument:",
        "_methodWithUnderscoreAndArgument__",
    });
}

- (void)testMethodWithUnderscoreAndThreeArguments
{
    testSearchMethod(self, _cmd, _obj, @selector(_methodWithUnderscoreAndArgument:andArgument::), {
        "_methodWithUnderscoreAndArgument_andArgument",
        "_methodWithUnderscoreAndArgument:andArgument::",
        "_methodWithUnderscoreAndArgument_andArgument__",
    }, {
        "_methodWithUnderscoreAndArgument:andArgument:",
        "_methodWithUnderscoreAndArgument:andArgument_",
        "_methodWithUnderscoreAndArgument:andArgument__",
        "_methodWithUnderscoreAndArgument_andArgument_",
        "_methodWithUnderscoreAndArgument_andArgument::",
    });
}

- (void)testMethodWithUnderscoreInside
{
    testSearchMethod(self, _cmd, _obj, @selector(my_method), {
        "my_method",
    }, {
        "my_method_",
    });
}

- (void)testMethodWithUnderscoreInsideWithArgument
{
    testSearchMethod(self, _cmd, _obj, @selector(my_methodWithArgument:), {
        "my_methodWithArgument",
        "my_methodWithArgument_",
        "my_methodWithArgument:",
    }, {
        "my_methodWithArgument__",
    });
}

- (void)testMethodWithUnderscoreInsideWithTwoArguments
{
    testSearchMethod(self, _cmd, _obj, @selector(my_methodWithArgument:andArgument:), {
        "my_methodWithArgument_andArgument",
        "my_methodWithArgument_andArgument_",
        "my_methodWithArgument:andArgument:",
    }, {
        "my_methodWithArgument_andArgument:",
        "my_methodWithArgument_andArgument::",
        "my_methodWithArgument:andArgument",
        "my_methodWithArgument:andArgument_",
    });
}

@end
