//
//  XJSClassTests.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-10-2.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <objc/runtime.h>

#import "jsapi.h"

#import "XJSClass.h"
#import "XJSConvert.h"
#import "XJSContext_Private.h"
#import "XJSValue_Private.h"

@interface XJSClassTests : XCTestCase

@end

@implementation XJSClassTests
{
    XJSContext *_context;
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

- (void)testCreateClassObject
{
    id clsobj = [NSObject class];
    
    JSObject *jsobj = XJSCreateJSObject(_context.context, clsobj);
    
    XCTAssertEqualObjects(XJSGetAssosicatedObject(jsobj), clsobj);
    
    NSString *str = XJSConvertJSValueToString(_context.context, JS::ObjectOrNullValue(jsobj));
    
    XCTAssertEqualObjects(str, [clsobj description]);
}

- (void)testCreateInstanceObject
{
    __weak id weakobj;
    @autoreleasepool {
        id obj = [[NSObject alloc] init];
        weakobj = obj;
        
        JSObject *jsobj = XJSCreateJSObject(_context.context, obj);
        
        XCTAssertEqualObjects(XJSGetAssosicatedObject(jsobj), obj);
        
        NSString *str = XJSConvertJSValueToString(_context.context, JS::ObjectOrNullValue(jsobj));
        
        XCTAssertEqualObjects(str, [obj description]);
    }
    
    XCTAssertNotNil(weakobj, @"should be retained by context");
    
    _context = nil; // somehow [_context.runtime gc] does not finalize the js object
    
    XCTAssertNil(weakobj, @"should be released by context");
}

@end

@interface XJSClassCallMethodTests : XCTestCase

@end

@implementation XJSClassCallMethodTests
{
    SEL _invokedSel;
    NSArray *_args;
    
    XJSValue *_val;
}

- (void)voidMethod { _invokedSel = _cmd; }
- (BOOL)boolMethod { _invokedSel = _cmd; return YES; }
- (char)charMethod { _invokedSel = _cmd; return 42; }
- (int)intMethod { _invokedSel = _cmd; return 42; }
- (unsigned)unsignedMethod { _invokedSel = _cmd; return 42; }
- (long long)longlongMethod { _invokedSel = _cmd; return 42; }
- (float)floatMethod { _invokedSel = _cmd; return 42.5; }
- (double)doubleMethod { _invokedSel = _cmd; return 42.5; }
- (id)objectMethod { _invokedSel = _cmd; return self; }
- (Class)classMethod { _invokedSel = _cmd; return [self class]; }
- (SEL)selMethod { _invokedSel = _cmd; return _cmd; }
- (const char *)cstrMethod { _invokedSel = _cmd; return "42"; }

- (void)voidMethodWithBool:(BOOL)b char:(char)c int:(int)i uint32:(uint32_t)ui32 uint64:(uint64_t)ui64 float:(float)f double:(double)d object:(id)o sel:(SEL)s class:(Class)cls cstr:(const char *)cstr
{
    _invokedSel = _cmd;
    _args = @[ @(b),@(c),@(i),@(ui32),@(ui64),@(f),@(d),o,NSStringFromSelector(s),cls,@(cstr) ];
}

- (BOOL)boolMethodWithBool:(BOOL)b char:(char)c int:(int)i uint32:(uint32_t)ui32 uint64:(uint64_t)ui64 float:(float)f double:(double)d object:(id)o sel:(SEL)s class:(Class)cls cstr:(const char *)cstr
{
    _invokedSel = _cmd;
    _args = @[ @(b),@(c),@(i),@(ui32),@(ui64),@(f),@(d),o,NSStringFromSelector(s),cls,@(cstr) ];
    return YES;
}

- (id)objectMethodWithBool:(BOOL)b char:(char)c int:(int)i uint32:(uint32_t)ui32 uint64:(uint64_t)ui64 float:(float)f double:(double)d object:(id)o sel:(SEL)s class:(Class)cls cstr:(const char *)cstr
{
    _invokedSel = _cmd;
    _args = @[ @(b),@(c),@(i),@(ui32),@(ui64),@(f),@(d),o,NSStringFromSelector(s),cls,@(cstr) ];
    return self;
}

- (const char *)cstrMethodWithBool:(BOOL)b char:(char)c int:(int)i uint32:(uint32_t)ui32 uint64:(uint64_t)ui64 float:(float)f double:(double)d object:(id)o sel:(SEL)s class:(Class)cls cstr:(const char *)cstr
{
    _invokedSel = _cmd;
    _args = @[ @(b),@(c),@(i),@(ui32),@(ui64),@(f),@(d),o,NSStringFromSelector(s),cls,@(cstr) ];
    return "42";
}

- (void)setUp
{
    [super setUp];
    
    _val = [XJSValue valueWithObject:self inContext:[[XJSContext alloc] init]];
}

- (void)tearDown
{
    _val = nil;
    
    [super tearDown];
}

- (void)testVoidMethod
{
    SEL sel = @selector(voidMethod);
    XJSValue *ret = [_val invokeMethod:NSStringFromSelector(sel) withArguments:nil];
    XCTAssertNotNil(ret);
    XCTAssertTrue(ret.isUndefined);
    XCTAssertEqual(_invokedSel, sel);
}

- (void)testBoolMethod
{
    SEL sel = @selector(boolMethod);
    XJSValue *ret = [_val invokeMethod:NSStringFromSelector(sel) withArguments:nil];
    XCTAssertNotNil(ret);
    XCTAssertTrue(ret.isBoolean);
    XCTAssertTrue(ret.toBool);
    XCTAssertEqual(_invokedSel, sel);
}

- (void)_testIntegerMethod:(SEL)sel
{
    XJSValue *ret = [_val invokeMethod:NSStringFromSelector(sel) withArguments:nil];
    XCTAssertNotNil(ret);
    XCTAssertTrue(ret.isInt32);
    XCTAssertEqual(ret.toInt32, 42);
    XCTAssertEqual(_invokedSel, sel);
}

- (void)testCharMethod
{
    [self _testIntegerMethod:@selector(charMethod)];
}

- (void)testIntMethod
{
    [self _testIntegerMethod:@selector(intMethod)];
}

- (void)testUnsignedMethod
{
    [self _testIntegerMethod:@selector(unsignedMethod)];
}

- (void)testLongLongMethod
{
    [self _testIntegerMethod:@selector(longlongMethod)];
}

- (void)testFloatMethod
{
    SEL sel = @selector(floatMethod);
    XJSValue *ret = [_val invokeMethod:NSStringFromSelector(sel) withArguments:nil];
    XCTAssertNotNil(ret);
    XCTAssertTrue(ret.isDouble);
    XCTAssertEqual(ret.toDouble, 42.5);
    XCTAssertEqual(_invokedSel, sel);
}

- (void)testDoubleMethod
{
    SEL sel = @selector(doubleMethod);
    XJSValue *ret = [_val invokeMethod:NSStringFromSelector(sel) withArguments:nil];
    XCTAssertNotNil(ret);
    XCTAssertTrue(ret.isDouble);
    XCTAssertEqual(ret.toDouble, 42.5);
    XCTAssertEqual(_invokedSel, sel);
}

- (void)testObjectMethod
{
    SEL sel = @selector(objectMethod);
    XJSValue *ret = [_val invokeMethod:NSStringFromSelector(sel) withArguments:nil];
    XCTAssertNotNil(ret);
    XCTAssertTrue(ret.isObject);
    XCTAssertEqualObjects(ret.toObject, self);
    XCTAssertEqual(_invokedSel, sel);
}

- (void)testClassMethod
{
    SEL sel = @selector(classMethod);
    XJSValue *ret = [_val invokeMethod:NSStringFromSelector(sel) withArguments:nil];
    XCTAssertNotNil(ret);
    XCTAssertTrue(ret.isObject);
    XCTAssertEqualObjects(ret.toObject, [self class]);
    XCTAssertEqual(_invokedSel, sel);
}

- (void)testSelMethod
{
    SEL sel = @selector(selMethod);
    XJSValue *ret = [_val invokeMethod:NSStringFromSelector(sel) withArguments:nil];
    XCTAssertNotNil(ret);
    XCTAssertTrue(ret.isString);
    XCTAssertEqualObjects(ret.toString, NSStringFromSelector(sel));
    XCTAssertEqual(_invokedSel, sel);
}

- (void)testCStrlMethod
{
    SEL sel = @selector(cstrMethod);
    XJSValue *ret = [_val invokeMethod:NSStringFromSelector(sel) withArguments:nil];
    XCTAssertNotNil(ret);
    XCTAssertTrue(ret.isString);
    XCTAssertEqualObjects(ret.toString, @"42");
    XCTAssertEqual(_invokedSel, sel);
}

- (void)testVoidMethodWithArgs
{
    SEL sel = @selector(voidMethodWithBool:char:int:uint32:uint64:float:double:object:sel:class:cstr:);
    NSArray *args = @[@YES, @'a', @-42, @42, @420, @42.5f, @4.25, self, NSStringFromSelector(sel), [self class], @"cstr"];
    XJSValue *ret = [_val invokeMethod:NSStringFromSelector(sel) withArguments:args];
    XCTAssertNotNil(ret);
    XCTAssertTrue(ret.isUndefined);
    XCTAssertEqual(_invokedSel, sel);
    XCTAssertEqualObjects(_args, args);
}

- (void)testBoolMethodWithArgs
{
    SEL sel = @selector(boolMethodWithBool:char:int:uint32:uint64:float:double:object:sel:class:cstr:);
    NSArray *args = @[@YES, @'a', @-42, @42, @420, @42.5f, @4.25, self, NSStringFromSelector(sel), [self class], @"cstr"];
    XJSValue *ret = [_val invokeMethod:NSStringFromSelector(sel) withArguments:args];
    XCTAssertNotNil(ret);
    XCTAssertTrue(ret.isBoolean);
    XCTAssertTrue(ret.toBool);
    XCTAssertEqual(_invokedSel, sel);
    XCTAssertEqualObjects(_args, args);
}

- (void)testObjectMethodWithArgs
{
    SEL sel = @selector(objectMethodWithBool:char:int:uint32:uint64:float:double:object:sel:class:cstr:);
    NSArray *args = @[@YES, @'a', @-42, @42, @420, @42.5f, @4.25, self, NSStringFromSelector(sel), [self class], @"cstr"];
    XJSValue *ret = [_val invokeMethod:NSStringFromSelector(sel) withArguments:args];
    XCTAssertNotNil(ret);
    XCTAssertTrue(ret.isObject);
    XCTAssertEqualObjects(ret.toObject, self);
    XCTAssertEqual(_invokedSel, sel);
    XCTAssertEqualObjects(_args, args);
}

- (void)testCStrMethodWithArgs
{
    SEL sel = @selector(cstrMethodWithBool:char:int:uint32:uint64:float:double:object:sel:class:cstr:);
    NSArray *args = @[@YES, @'a', @-42, @42, @420, @42.5f, @4.25, self, NSStringFromSelector(sel), [self class], @"cstr"];
    XJSValue *ret = [_val invokeMethod:NSStringFromSelector(sel) withArguments:args];
    XCTAssertNotNil(ret);
    XCTAssertTrue(ret.isString);
    XCTAssertEqualObjects(ret.toString, @"42");
    XCTAssertEqual(_invokedSel, sel);
    XCTAssertEqualObjects(_args, args);
}

@end