//
//  XJSAdopterTests.m
//  XJSBinding
//
//  Created by Xiliang Chen on 14-1-8.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "XJSAdopter.h"
#import "XJSValue.h"
#import "XJSContext.h"

@interface NSObject (XJSAdopterTests)
- (id)XJSAdopterTests_test:(id)obj;
@end

@implementation NSObject (XJSAdopterTests)
- (id)XJSAdopterTests_test:(id)obj { return obj; }
@end

@protocol XJSAdopterTestProtocol <NSObject>

@optional
- (void)voidMethod;
- (BOOL)boolMethod;
- (double)doubleMethod;
- (id)objectMethod;

- (id)objectMethodWithObject:(id)obj;
- (void)voidMethodWithBool:(BOOL)b char:(char)c int:(int)i uint64:(uint64_t)ui64 float:(float)f double:(double)d object:(id)o;
- (BOOL)boolMethodWithBool:(BOOL)b char:(char)c int:(int)i uint64:(uint64_t)ui64 float:(float)f double:(double)d object:(id)o;
- (id)objectMethodWithBool:(BOOL)b char:(char)c int:(int)i uint64:(uint64_t)ui64 float:(float)f double:(double)d object:(id)o;

@end

@protocol XJSAdopterTestProtocol2 <NSObject>
@end

@interface XJSAdopterTestClass : NSObject <XJSAdopterTestProtocol> @end
@implementation XJSAdopterTestClass @end

@interface XJSAdopterTests : XCTestCase

@end

@implementation XJSAdopterTests
{
    XJSContext *_context;
    XJSValue *_value;
}

- (void)setUp
{
    [super setUp];
    
    _context = [[XJSContext alloc] init];
    _value = [XJSValue valueWithNewObjectInContext:_context];
}

- (void)tearDown
{
    _value = nil;
    _context = nil;
    
    [super tearDown];
}

- (void)testProtocolAdopter
{
    id adopter = [XJSAdopter adopterForProtocol:@protocol(XJSAdopterTestProtocol) withValue:_value];
    
    _value[@"voidMethod"] = [_context evaluateString:@"f=function(){}" error:NULL];
    _value[@"objectMethodWithObject"] = [_context evaluateString:@"f=function(o){return o;}" error:NULL];
    
    XCTAssertTrue([adopter respondsToSelector:@selector(voidMethod)]);
    XCTAssertFalse([adopter respondsToSelector:@selector(boolMethod)]);
    XCTAssertTrue([adopter respondsToSelector:@selector(objectMethodWithObject:)]);
    
    XCTAssertTrue([adopter conformsToProtocol:@protocol(XJSAdopterTestProtocol)]);
    XCTAssertTrue([adopter conformsToProtocol:@protocol(NSObject)]);
    XCTAssertFalse([adopter conformsToProtocol:@protocol(XJSAdopterTestProtocol2)]);
    
    XCTAssertTrue([adopter isKindOfClass:[NSObject class]]);
    XCTAssertFalse([adopter isMemberOfClass:[NSObject class]]);
    XCTAssertFalse([adopter isKindOfClass:[XJSAdopter class]]);
    XCTAssertFalse([adopter isKindOfClass:[XJSAdopterTestClass class]]);
    
    XCTAssertEqualObjects([adopter methodSignatureForSelector:@selector(voidMethod)], [NSMethodSignature signatureWithObjCTypes:"v@:"]);
    
    XCTAssertEqualObjects([adopter superclass], [NSObject class]);
    XCTAssertEqual([adopter self], adopter);
    
    XCTAssertTrue([[adopter description] isKindOfClass:[NSString class]]);
    XCTAssertTrue([[adopter debugDescription] isKindOfClass:[NSString class]]);
    
    XCTAssertEqualObjects([adopter performSelector:@selector(voidMethod)], nil);
    XCTAssertEqualObjects([adopter performSelector:@selector(objectMethodWithObject:) withObject:@"abc"], @"abc");
    XCTAssertEqualObjects([adopter performSelector:@selector(objectMethodWithObject:) withObject:@"test" withObject:nil], @"test");
    
    XCTAssertTrue([adopter isProxy]);
}

- (void)testProtocolCategoryOnNSObject
{
    id adopter = [XJSAdopter adopterForProtocol:@protocol(XJSAdopterTestProtocol) withValue:_value];
    XCTAssertEqualObjects([adopter XJSAdopterTests_test:self], self);
}

- (void)testClassAdopter
{
    id adopter = [XJSAdopter adopterForClass:[XJSAdopterTestClass class] withValue:_value];
    
    _value[@"voidMethod"] = [_context evaluateString:@"f=function(){}" error:NULL];
    _value[@"objectMethodWithObject"] = [_context evaluateString:@"f=function(o){return o;}" error:NULL];
    
    XCTAssertTrue([adopter respondsToSelector:@selector(voidMethod)]);
    XCTAssertFalse([adopter respondsToSelector:@selector(boolMethod)]);
    XCTAssertTrue([adopter respondsToSelector:@selector(objectMethodWithObject:)]);
    
    XCTAssertTrue([adopter conformsToProtocol:@protocol(XJSAdopterTestProtocol)]);
    XCTAssertTrue([adopter conformsToProtocol:@protocol(NSObject)]);
    XCTAssertFalse([adopter conformsToProtocol:@protocol(XJSAdopterTestProtocol2)]);
    
    XCTAssertTrue([adopter isKindOfClass:[NSObject class]]);
    XCTAssertFalse([adopter isMemberOfClass:[NSObject class]]);
    XCTAssertFalse([adopter isKindOfClass:[XJSAdopter class]]);
    XCTAssertTrue([adopter isKindOfClass:[XJSAdopterTestClass class]]);
    
    XCTAssertEqualObjects([adopter methodSignatureForSelector:@selector(voidMethod)], [NSMethodSignature signatureWithObjCTypes:"v@:"]);
    
    XCTAssertEqualObjects([adopter class], [XJSAdopterTestClass class]);
    XCTAssertEqualObjects([adopter superclass], [XJSAdopterTestClass superclass]);
    XCTAssertEqual([adopter self], adopter);
    
    NSLog(@"%@", [adopter debugDescription]);
    XCTAssertTrue([[adopter description] isKindOfClass:[NSString class]]);
    XCTAssertTrue([[adopter debugDescription] isKindOfClass:[NSString class]]);
    
    XCTAssertEqualObjects([adopter performSelector:@selector(voidMethod)], nil);
    XCTAssertEqualObjects([adopter performSelector:@selector(objectMethodWithObject:) withObject:@"abc"], @"abc");
    XCTAssertEqualObjects([adopter performSelector:@selector(objectMethodWithObject:) withObject:@"test" withObject:nil], @"test");
    
    XCTAssertTrue([adopter isProxy]);
}

- (void)testClassCategoryOnNSObject
{
    id adopter = [XJSAdopter adopterForClass:[XJSAdopterTestClass class] withValue:_value];
    
    _value[@"XJSAdopterTests_test"] = [_context evaluateString:@"f=function(o){return o;}" error:NULL];
    
    XCTAssertEqualObjects([adopter XJSAdopterTests_test:nil], nil);
}

- (void)_testVoidMethod:(id)adopter
{
    _value[@"voidMethod"] = [_context evaluateString:@"f=function(){count++;}" error:NULL];
    
    _context[@"count"] = @0;
    
    [adopter voidMethod];
    XCTAssertEqual(_context[@"count"].toInt32, 1);
    
    [adopter voidMethod];
    XCTAssertEqual(_context[@"count"].toInt32, 2);
}

- (void)testProtocolVoidMethod
{
    [self _testVoidMethod:[XJSAdopter adopterForProtocol:@protocol(XJSAdopterTestProtocol) withValue:_value]];
}

- (void)testClassVoidMethod
{
    [self _testVoidMethod:[XJSAdopter adopterForClass:[XJSAdopterTestClass class] withValue:_value]];
}

- (void)_testBoolMethod:(id)adopter
{
    _value[@"boolMethod"] = [_context evaluateString:@"f=function(){return count++ == 0;}" error:NULL];
    
    _context[@"count"] = @0;
    
    BOOL ret = [adopter boolMethod];
    XCTAssertEqual(_context[@"count"].toInt32, 1);
    XCTAssertTrue(ret);
    
    ret = [adopter boolMethod];
    XCTAssertEqual(_context[@"count"].toInt32, 2);
    XCTAssertFalse(ret);
}

- (void)testProtocolBoolMethod
{
    [self _testBoolMethod:[XJSAdopter adopterForProtocol:@protocol(XJSAdopterTestProtocol) withValue:_value]];
}

- (void)testClassBoolMethod
{
    [self _testBoolMethod:[XJSAdopter adopterForClass:[XJSAdopterTestClass class] withValue:_value]];
}

- (void)_testDoubleMethod:(id)adopter
{
    _value[@"doubleMethod"] = [_context evaluateString:@"f=function(){return count++ + 0.5;}" error:NULL];
    
    _context[@"count"] = @0;
    
    double ret = [adopter doubleMethod];
    XCTAssertEqual(_context[@"count"].toInt32, 1);
    XCTAssertEqual(ret, 0.5);
    
    ret = [adopter doubleMethod];
    XCTAssertEqual(_context[@"count"].toInt32, 2);
    XCTAssertEqual(ret, 1.5);
}

- (void)testProtocolDoubleMethod
{
    [self _testDoubleMethod:[XJSAdopter adopterForProtocol:@protocol(XJSAdopterTestProtocol) withValue:_value]];
}

- (void)testClassDoubleMethod
{
    [self _testDoubleMethod:[XJSAdopter adopterForClass:[XJSAdopterTestClass class] withValue:_value]];
}

- (void)_testObjectMethod:(id)adopter
{
    _value[@"objectMethod"] = [_context evaluateString:@"f=function(){return count++;}" error:NULL];
    
    _context[@"count"] = @0;
    
    id ret = [adopter objectMethod];
    XCTAssertEqual(_context[@"count"].toInt32, 1);
    XCTAssertEqualObjects(ret, @0);
    
    ret = [adopter objectMethod];
    XCTAssertEqual(_context[@"count"].toInt32, 2);
    XCTAssertEqualObjects(ret, @1);
}

- (void)testProtocolObjectMethod
{
    [self _testObjectMethod:[XJSAdopter adopterForProtocol:@protocol(XJSAdopterTestProtocol) withValue:_value]];
}

- (void)testClassObjectMethod
{
    [self _testObjectMethod:[XJSAdopter adopterForClass:[XJSAdopterTestClass class] withValue:_value]];
}

- (void)_testObjectMethodWithObject:(id)adopter
{
    _value[@"objectMethodWithObject"] = [_context evaluateString:@"f=function(obj){count++; return obj.toString();}" error:NULL];
    
    _context[@"count"] = @0;
    
    id ret = [adopter objectMethodWithObject:@42];
    XCTAssertEqual(_context[@"count"].toInt32, 1);
    XCTAssertEqualObjects(ret, @"42");
    
    ret = [adopter objectMethodWithObject:@43];
    XCTAssertEqual(_context[@"count"].toInt32, 2);
    XCTAssertEqualObjects(ret, @"43");
}

- (void)testProtocolObjectMethodWithObject
{
    [self _testObjectMethodWithObject:[XJSAdopter adopterForProtocol:@protocol(XJSAdopterTestProtocol) withValue:_value]];
}

- (void)testClassObjectMethodWithObject
{
    [self _testObjectMethodWithObject:[XJSAdopter adopterForClass:[XJSAdopterTestClass class] withValue:_value]];
}

- (void)_testVoidMethodWithArgs:(id)adopter
{
    _value[@"voidMethodWithBool_char_int_uint64_float_double_object"] = [_context evaluateString:@"f=function(){count++;args = arguments;}" error:NULL];
    
    _context[@"count"] = @0;
    
    [adopter voidMethodWithBool:YES char:'c' int:42 uint64:1ul << 42 float:0.5 double:0.25 object:@"test"];
    XCTAssertEqual(_context[@"count"].toInt32, 1);
    XCTAssertEqualObjects(_context[@"args"].toArray, (@[@YES, @'c', @42, @(1ul << 42), @0.5f, @0.25, @"test"]));

    [adopter voidMethodWithBool:NO char:'d' int:43 uint64:1ul << 43 float:0.25 double:0.125 object:@"str"];
    XCTAssertEqualObjects(_context[@"args"].toArray, (@[@NO, @'d', @43, @(1ul << 43), @0.25f, @0.125, @"str"]));
    XCTAssertEqual(_context[@"count"].toInt32, 2);
}

- (void)testProtocolVoidMethodWithArgs
{
    [self _testVoidMethodWithArgs:[XJSAdopter adopterForProtocol:@protocol(XJSAdopterTestProtocol) withValue:_value]];
}

- (void)testClassVoidMethodWithArgs
{
    [self _testVoidMethodWithArgs:[XJSAdopter adopterForClass:[XJSAdopterTestClass class] withValue:_value]];
}

- (void)_testBoolMethodWithArgs:(id)adopter
{
    _value[@"boolMethodWithBool_char_int_uint64_float_double_object"] = [_context evaluateString:@"f=function(b){count++;args = arguments;return b;}" error:NULL];
    
    _context[@"count"] = @0;
    
    BOOL ret = [adopter boolMethodWithBool:YES char:'c' int:42 uint64:1ul << 42 float:0.5 double:0.25 object:@"test"];
    XCTAssertEqual(_context[@"count"].toInt32, 1);
    XCTAssertEqualObjects(_context[@"args"].toArray, (@[@YES, @'c', @42, @(1ul << 42), @0.5f, @0.25, @"test"]));
    XCTAssertTrue(ret);
    
    ret = [adopter boolMethodWithBool:NO char:'d' int:43 uint64:1ul << 43 float:0.25 double:0.125 object:nil];
    XCTAssertEqualObjects(_context[@"args"].toArray, (@[@NO, @'d', @43, @(1ul << 43), @0.25f, @0.125, [NSNull null]]));
    XCTAssertEqual(_context[@"count"].toInt32, 2);
    XCTAssertFalse(ret);
}

- (void)testProtocolBoolMethodWithArgs
{
    [self _testBoolMethodWithArgs:[XJSAdopter adopterForProtocol:@protocol(XJSAdopterTestProtocol) withValue:_value]];
}

- (void)testClassBoolMethodWithArgs
{
    [self _testBoolMethodWithArgs:[XJSAdopter adopterForClass:[XJSAdopterTestClass class] withValue:_value]];
}

- (void)_testObjectMethodWithArgs:(id)adopter
{
    _value[@"objectMethodWithBool_char_int_uint64_float_double_object"] = [_context evaluateString:@"f=function(b, c, i, u, f, d, o){count++;args = arguments;return o;}" error:NULL];
    
    _context[@"count"] = @0;
    
    id ret = [adopter objectMethodWithBool:YES char:'c' int:42 uint64:1ul << 42 float:0.5 double:0.25 object:@"test"];
    XCTAssertEqual(_context[@"count"].toInt32, 1);
    XCTAssertEqualObjects(_context[@"args"].toArray, (@[@YES, @'c', @42, @(1ul << 42), @0.5f, @0.25, @"test"]));
    XCTAssertEqualObjects(ret, @"test");
    
    ret = [adopter objectMethodWithBool:NO char:'d' int:43 uint64:1ul << 43 float:0.25 double:0.125 object:nil];
    XCTAssertEqualObjects(_context[@"args"].toArray, (@[@NO, @'d', @43, @(1ul << 43), @0.25f, @0.125, [NSNull null]]));
    XCTAssertEqual(_context[@"count"].toInt32, 2);
    XCTAssertNil(ret);
}

- (void)testProtocolObjectMethodWithArgs
{
    [self _testObjectMethodWithArgs:[XJSAdopter adopterForProtocol:@protocol(XJSAdopterTestProtocol) withValue:_value]];
}

- (void)testClassObjectMethodWithArgs
{
    [self _testObjectMethodWithArgs:[XJSAdopter adopterForClass:[XJSAdopterTestClass class] withValue:_value]];
}

@end
