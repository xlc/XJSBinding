//
//  XJSClassTests.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-10-2.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <XLCUtils/NSObject+XLCUtilsMemoryDebug.h>

#import "jsapi.h"

#import "XJSClass.hh"
#import "XJSConvert.hh"
#import "XJSContext_Private.hh"
#import "XJSValue_Private.hh"
#import "XJSRuntime.h"

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
    [_context createObjCRuntimeWithNamespace:@"objc"];
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
    // not using the one in setup because it leak reference to global auto release pool which cannot be released inside this method
    _context = [[XJSContext alloc] init];
    
    __weak id weakobj;
    @autoreleasepool {
        [_context createObjCRuntimeWithNamespace:@"objc"];
        
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

- (void)testConstruct
{
    // not using the one in setup because it leak reference to global auto release pool which cannot be released inside this method
    _context = [[XJSContext alloc] init];
    
    __weak id weakobj;
    @autoreleasepool {
        [_context createObjCRuntimeWithNamespace:@"objc"];
        
        Class cls = [NSObject class];
        JSObject *clsobj = XJSCreateJSObject(_context.context, cls);
        JSObject *newobj = JS_New(_context.context, clsobj, 0, NULL);
        id obj = XJSGetAssosicatedObject(newobj);
        weakobj = obj;
        XCTAssertNotNil(obj);
        XCTAssertEqualObjects([obj class], cls);
    }
    
    XCTAssertNotNil(weakobj, @"should be retained by context");
    
    _context = nil; // somehow [_context.runtime gc] does not finalize the js object
    
    XCTAssertNil(weakobj, @"should be released by context");
}

- (void)testConstruct2
{
    // not using the one in setup because it leak reference to global auto release pool which cannot be released inside this method
    _context = [[XJSContext alloc] init];
    
    __weak id weakobj;
    @autoreleasepool {
        [_context createObjCRuntimeWithNamespace:@"objc"];
        
        Class cls = [NSObject class];
        JSObject *clsobj = XJSCreateJSObject(_context.context, cls);
        jsval rval;
        XCTAssertTrue(JS_CallFunctionName(_context.context, clsobj, "alloc", 0, NULL, &rval));
        XCTAssertTrue(rval.isObject());
        id obj = XJSGetAssosicatedObject(rval.toObjectOrNull());
        weakobj = obj;
        XCTAssertNotNil(obj);
        XCTAssertEqualObjects([obj class], cls);
    }
    
    XCTAssertNotNil(weakobj, @"should be retained by context");
    
    _context = nil; // somehow [_context.runtime gc] does not finalize the js object
    
    XCTAssertNil(weakobj, @"should be released by context");
}

- (void)testHasInstance
{
    JSObject *obj = XJSCreateJSObject(_context.context, @1);
    JSObject *cls = XJSCreateJSObject(_context.context, [NSNumber class]);
    JSBool result;
    XCTAssertTrue(JS_HasInstance(_context.context, cls, JS::ObjectOrNullValue(obj), &result));
    XCTAssertTrue(result, "@1 should be instanceof NSNumber");
    
    cls = XJSCreateJSObject(_context.context, [NSValue class]);
    XCTAssertTrue(JS_HasInstance(_context.context, cls, JS::ObjectOrNullValue(obj), &result));
    XCTAssertTrue(result, "@1 should be instanceof NSValue");
    
    cls = XJSCreateJSObject(_context.context, [NSObject class]);
    XCTAssertTrue(JS_HasInstance(_context.context, cls, JS::ObjectOrNullValue(obj), &result));
    XCTAssertTrue(result, "@1 should be instanceof NSObject");
}

- (void)testHasInstance2
{
    JSObject *obj = XJSCreateJSObject(_context.context, @[]);
    JSObject *cls = XJSCreateJSObject(_context.context, [NSNumber class]);
    JSBool result;
    XCTAssertTrue(JS_HasInstance(_context.context, cls, JS::ObjectOrNullValue(obj), &result));
    XCTAssertFalse(result, "@[] should not be instanceof NSNumber");
}

- (void)testHasInstance3
{
    JSObject *obj = XJSCreateJSObject(_context.context, [NSNumber class]);
    JSObject *cls = XJSCreateJSObject(_context.context, [NSObject class]);
    JSBool result;
    XCTAssertTrue(JS_HasInstance(_context.context, cls, JS::ObjectOrNullValue(obj), &result));
    XCTAssertTrue(result, "NSNumber should be instanceof NSObject");
}

- (void)testHasInstance4
{
    JSObject *obj = XJSCreateJSObject(_context.context, [NSObject class]);
    JSObject *cls = XJSCreateJSObject(_context.context, [NSObject class]);
    JSBool result;
    XCTAssertTrue(JS_HasInstance(_context.context, cls, JS::ObjectOrNullValue(obj), &result));
    XCTAssertTrue(result, "NSObject should be instanceof NSObject (itself)");
}

- (void)testConstructor
{
    JSObject *obj = XJSCreateJSObject(_context.context, self);
    JS::RootedValue val(_context.context);
    XCTAssertTrue(JS_GetProperty(_context.context, obj, "constructor", &val));
    XCTAssertTrue(val.isObject());
    id cls = XJSGetAssosicatedObject(val.toObjectOrNull());
    XCTAssertEqualObjects(cls, [self class]);
}

- (void)testInheritObjectProperty
{
    JSObject *obj = XJSCreateJSObject(_context.context, self);
    jsval val;
    XCTAssertTrue(JS_CallFunctionName(_context.context, obj, "toSource", 0, NULL, &val));
    XCTAssertEqualObjects(XJSConvertJSValueToSource(_context.context, val), @"\"({})\"");
}

- (void)testCacheObject
{
    JSObject *obj = XJSGetOrCreateJSObject(_context.context, self);
    JSObject *obj2 = XJSGetOrCreateJSObject(_context.context, self);
    XCTAssert(obj != NULL);
    XCTAssertEqual(obj, obj2);
    
    id nsobj = [NSObject new];
    
    JSObject *obj3 = XJSGetOrCreateJSObject(_context.context, nsobj);
    JSObject *obj4 = XJSGetOrCreateJSObject(_context.context, nsobj);
    XCTAssert(obj3 != NULL);
    XCTAssertEqual(obj3, obj4);
    
    XCTAssertNotEqual(obj, obj3);
}

- (void)testToString
{
    NSMutableString *str = [@"test" mutableCopy];
    JSObject *obj = XJSGetOrCreateJSObject(_context.context, str);
    
    jsval val;
    XCTAssertTrue(JS_CallFunctionName(_context.context, obj, "toString", 0, NULL, &val));
    XCTAssertEqualObjects(XJSConvertJSValueToString(_context.context, val), @"test");
    
    [str appendString:@"test"];
    
    XCTAssertTrue(JS_CallFunctionName(_context.context, obj, "toString", 0, NULL, &val));
    XCTAssertEqualObjects(XJSConvertJSValueToString(_context.context, val), @"testtest");
    
    XCTAssertTrue(JS_CallFunctionName(_context.context, obj, "description", 0, NULL, &val));
    XCTAssertEqualObjects(XJSConvertJSValueToString(_context.context, val), @"testtest");
    
    [str setString:@"abc"];
    
    XCTAssertTrue(JS_CallFunctionName(_context.context, obj, "description", 0, NULL, &val));
    XCTAssertEqualObjects(XJSConvertJSValueToString(_context.context, val), @"abc");
}

- (void)testPrototype
{
    NSMutableString *str = [@"test" mutableCopy];
    
    JS::RootedObject obj(_context.context, XJSGetOrCreateJSObject(_context.context, str));
    JS::RootedObject obj2(_context.context, JS_NewObject(_context.context, NULL, NULL, NULL));
    
    jsval proto = _context[@"Object"][@"prototype"].value;
    JS::RootedObject proto2Obj(_context.context);
    JS_GetPrototype(_context.context, obj, &proto2Obj);
    jsval proto2 = JS::ObjectOrNullValue(proto2Obj);
    
    JSBool equal;
    JS_StrictlyEqual(_context.context, proto, proto2, &equal);
    XCTAssertFalse(equal, "obj.__proto__ !== Object.prototype");
    
    JS::RootedValue val(_context.context);
    XCTAssertTrue(JS_CallFunctionName(_context.context, obj2, "toString", 0, NULL, val.address()));
    XCTAssertEqualObjects(XJSConvertJSValueToString(_context.context, val), @"[object Object]");
}

- (void)testPrototype2
{
    NSMutableString *str = [@"test" mutableCopy];
    NSMutableString *str2 = [@"test2" mutableCopy];
    
    JS::RootedObject obj(_context.context, XJSGetOrCreateJSObject(_context.context, str));
    JS::RootedObject obj2(_context.context, XJSGetOrCreateJSObject(_context.context, str2));
    
    JS::RootedObject protoObj(_context.context);
    JS_GetPrototype(_context.context, obj, &protoObj);
    jsval proto = JS::ObjectOrNullValue(protoObj);
    
    JS::RootedObject protoObj2(_context.context);
    JS_GetPrototype(_context.context, obj2, &protoObj2);
    jsval proto2 = JS::ObjectOrNullValue(protoObj2);
    
    JSBool equal;
    JS_StrictlyEqual(_context.context, proto, proto2, &equal);
    XCTAssertTrue(equal, "obj.__proto__ === obj2.__proto__");
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
- (id)objectMethodWithObject:(id)obj { _invokedSel = _cmd; return obj; }

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

- (void *)pointerMethodWithPointer:(id *)ptr
{
    _invokedSel = _cmd;
    _args = @[ @((NSUInteger)ptr) ];
    return 0;
}

- (void)setUp
{
    [super setUp];
    
    XJSContext *context = [[XJSContext alloc] init];
    [context createObjCRuntimeWithNamespace:@"objc"];
    _val = [XJSValue valueWithObject:self inContext:context];
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

- (void)testObjectMethodWithObject
{
    id obj = [[NSObject alloc] init];
    SEL sel = @selector(objectMethodWithObject:);
    XJSValue *ret = [_val invokeMethod:NSStringFromSelector(sel) withArguments:@[obj]];
    XCTAssertNotNil(ret);
    XCTAssertTrue(ret.isObject);
    XCTAssertEqualObjects(ret.toObject, obj);
    XCTAssertEqual(_invokedSel, sel);
}

- (void)testObjectMethodWithObjectNullArgument
{
    SEL sel = @selector(objectMethodWithObject:);
    XJSValue *ret = [_val invokeMethod:NSStringFromSelector(sel) withArguments:@[[NSNull null]]];
    XCTAssertNotNil(ret);
    XCTAssertTrue(ret.isNull);
    XCTAssertEqual(_invokedSel, sel);
}

- (void)testPointerMethodWithPointer
{
    SEL sel = @selector(pointerMethodWithPointer:);
    XJSValue *ret = [_val invokeMethod:NSStringFromSelector(sel) withArguments:@[[NSNull null]]];
    XCTAssertNotNil(ret);
    XCTAssertTrue(ret.isNull);
    XCTAssertEqual(_invokedSel, sel);
}

@end