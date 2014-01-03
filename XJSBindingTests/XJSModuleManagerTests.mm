//
//  XJSModuleManagerTests.mm
//  XJSBinding
//
//  Created by Xiliang Chen on 13-12-16.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <deque>

#import "XJSModuleManager.h"
#import "XJSContext_Private.hh"
#import "XJSValue.h"

@interface XJSModuleManagerTests : XCTestCase

@end

@implementation XJSModuleManagerTests
{
    XJSContext *_context;
    XJSModuleManager *_manager;

    // vector can hold nil value
    std::deque<NSString *> _paths;
    std::deque<NSString *> _scripts;
}

- (void)setUp
{
    [super setUp];
    
    _context = [[XJSContext alloc] init];
    
    _manager = [[XJSModuleManager alloc] initWithContext:_context scriptProvider:^NSString *(NSString *path) {
        _paths.push_back(path);
        XCTAssertFalse(_scripts.empty(), "unexpected request to script provider");
        NSString *ret = _scripts.front();
        _scripts.pop_front();
        return ret;
    }];
    
    _context.moduleManager = _manager;
}

- (void)tearDown
{
    XCTAssertTrue(_scripts.empty(), "all provided scripts should be consumed");
    
    _context = nil;
    _manager = nil;
    _paths.clear();
    
    [super tearDown];
}

- (void)testCreate
{
    __weak id weakcontext;
    __weak id weakmanager;
    @autoreleasepool {
        XJSContext *context = [[XJSContext alloc] init];
        
        XCTAssertNil(context.moduleManager, "no module manager at first");
        XCTAssertTrue(context[@"require"].isUndefined, "no require function");
        
        [context createModuleManager];
        XJSModuleManager *manager = context.moduleManager;
        
        XCTAssertNotNil(manager, "should create module manager");
        
        XCTAssertEqualObjects(manager.context, context);
        XCTAssertEqualObjects(context.moduleManager, manager);
        
        XCTAssertTrue(manager.require.isCallable, "should create function require");
        XCTAssertTrue(context[@"require"].isCallable, "should have require function in global scope");
        XCTAssertEqualObjects(context[@"require"][@"name"].toString, @"require", "should have require function in global scope");
        
        XCTAssertNotNil(manager.paths, "should have path array");
        
        weakcontext = context;
        weakmanager = manager;
    }
    
    XCTAssertNil(weakcontext, "should have no retain cycle");
    XCTAssertNil(weakmanager, "should have no retain cycle");
}

- (void)testProvideValue
{
    XJSValue *value = [self createDummyModule];
    
    [_manager provideValue:value forModuleId:@"test"];
    
    XJSValue *module = [_manager requireModule:@"test"];
    [self assertModule:module];
    
    module = [_manager.require callWithArguments:@[@"test"]];
    [self assertModule:module];
}

- (void)testProvideBlock
{
    [_manager provideBlock:^BOOL(XJSValue *require, XJSValue *exports, XJSValue *module) {
        XCTAssertEqualObjects(module[@"id"].toString, @"test", "should have correct module.id");
        exports[@"val"] = @42;
        exports[@"name"] = @"test";
        return YES;
    } forModuleId:@"test"];
    
    XJSValue *module = [_manager requireModule:@"test"];
    [self assertModule:module];
}

- (void)testProvideBlock2
{
    [_manager provideBlock:^BOOL(XJSValue *require, XJSValue *exports, XJSValue *module) {
        XCTAssertEqualObjects(module[@"id"].toString, @"test", "should have correct module.id");
        module[@"exports"] = [self createDummyModule];
        return YES;
    } forModuleId:@"test"];
    
    XJSValue *module = [_manager requireModule:@"test"];
    [self assertModule:module];
}

- (void)testProvideBlockFailed
{
    [_manager provideBlock:^BOOL(XJSValue *require, XJSValue *exports, XJSValue *module) {
        return NO;
    } forModuleId:@"test"];
    
    XJSValue *module = [_manager requireModule:@"test"];
    XCTAssertNil(module, "shoud have no value");
}

- (void)testSearchPathSimple
{
    _manager.paths = @[@"/scripts/test", @"scripts", @"/"];
    
    _scripts = std::deque<NSString *>(6); // nil * 6
    
    XJSValue *module = [_manager requireModule:@"module"];
    XCTAssertNil(module, "should found nothing");
    
    XCTAssertTrue(_scripts.empty(), "should consume all scripts");
    
    NSArray *paths = @[
        @"/scripts/test/module",
        @"/scripts/test/module.js",
        @"scripts/module",
        @"scripts/module.js",
        @"/module",
        @"/module.js",
    ];
    
    [self assertPaths:paths];
}

- (void)testSearchPathWithLevel
{
    _manager.paths = @[@"/scripts/test", @"scripts", @"/"];
    
    _scripts = std::deque<NSString *>(6); // nil * 6
    
    XJSValue *module = [_manager requireModule:@"module/test"];
    XCTAssertNil(module, "should found nothing");
    
    XCTAssertTrue(_scripts.empty(), "should consume all scripts");
    
    NSArray *paths = @[
                       @"/scripts/test/module/test",
                       @"/scripts/test/module/test.js",
                       @"scripts/module/test",
                       @"scripts/module/test.js",
                       @"/module/test",
                       @"/module/test.js",
                       ];
    
    [self assertPaths:paths];
}

- (void)testSearchPathFound
{
    _manager.paths = @[@"/scripts/test", @"scripts", @"/"];
    
    _scripts = std::deque<NSString *>(3); // nil * 3
    _scripts.push_back(@"exports.val=42;exports.name='test'");
    
    XJSValue *module = [_manager requireModule:@"module"];
    [self assertModule:module];
    
    XCTAssertTrue(_scripts.empty(), "should consume all scripts");
    
    NSArray *paths = @[
                       @"/scripts/test/module",
                       @"/scripts/test/module.js",
                       @"scripts/module",
                       @"scripts/module.js",
                       ];
    
    [self assertPaths:paths];
}

- (void)testSearchPathRelateToRoot
{
    _manager.paths = @[@"/scripts/test", @"scripts", @"/"];
    
    _scripts = std::deque<NSString *>(6); // nil * 6
    
    XJSValue *module = [_manager requireModule:@"../module"];
    XCTAssertNil(module, "should found nothing");
    
    XCTAssertTrue(_scripts.empty(), "should consume all scripts");
    
    NSArray *paths = @[
                       @"/scripts/test/../module",
                       @"/scripts/test/../module.js",
                       @"scripts/../module",
                       @"scripts/../module.js",
                       @"/../module",
                       @"/../module.js",
                       ];
    
    [self assertPaths:paths];
}

- (void)testSearchPathRelative
{
    [_manager provideValue:[self createDummyModule] forModuleId:@"scripts/b"];
    
    [_manager provideBlock:^BOOL(XJSValue *require, XJSValue *exports, XJSValue *module) {
        module[@"exports"] = [_manager requireModule:@"./b"];
        return YES;
    } forModuleId:@"scripts/a"];
    
    XJSValue *module = [_manager requireModule:@"scripts/a"];
    [self assertModule:module];
}

- (void)testSearchPathRelative2
{
    [_manager provideValue:[self createDummyModule] forModuleId:@"c/d"];
    
    [_manager provideBlock:^BOOL(XJSValue *require, XJSValue *exports, XJSValue *module) {
        module[@"exports"] = [_manager requireModule:@"../../c/d"];
        return YES;
    } forModuleId:@"scripts/a/b"];
    
    [_manager provideBlock:^BOOL(XJSValue *require, XJSValue *exports, XJSValue *module) {
        module[@"exports"] = [_manager requireModule:@"./scripts/a/b"];
        return YES;
    } forModuleId:@"test"];
    
    XJSValue *module = [_manager requireModule:@"test"];
    [self assertModule:module];
}

- (void)testProvideScript
{
    [_manager provideScript:@"exports.val=42;exports.name='test'" forModuleId:@"test"];
    
    XJSValue *module = [_manager requireModule:@"test"];
    [self assertModule:module];
}

// https://github.com/commonjs/commonjs/tree/master/tests/modules/1.0/cyclic
- (void)testCyclic
{
    _manager.paths = @[@"scripts"];
    
    _scripts.push_back(@"exports.a = function(){ return b; }; var b = require('b');");
    _scripts.push_back(@"var a = require('a'); exports.b = function(){ return a; };");
    
    XJSValue *moduleA = [_manager requireModule:@"a"];
    XJSValue *moduleB = [_manager requireModule:@"b"];
    
    XCTAssertNotNil(moduleA, "should be able to require module a");
    XCTAssertNotNil(moduleB, "should be able to requrie module b");
    
    XCTAssertTrue(moduleA[@"a"].isCallable, "a.a should be a function");
    XCTAssertTrue(moduleB[@"b"].isCallable, "b.b should be a function");
    XCTAssertEqualObjects([moduleA[@"a"] callWithArguments:nil][@"b"], moduleB[@"b"], "a gets b");
    XCTAssertEqualObjects([moduleB[@"b"] callWithArguments:nil][@"a"], moduleA[@"a"], "a gets b");
}

// https://github.com/commonjs/commonjs/tree/master/tests/modules/1.0/determinism
- (void)testDeterminism
{
    [_manager provideScript:@"try {require('a');} catch (ex) { exports.success = true;}" forModuleId:@"submodule/a"];
    [_manager provideScript:@"exports.success = require('submodule/a').success;" forModuleId:@"test"];
    
    XJSValue *module = [_manager requireModule:@"test"];
    XCTAssertTrue(module[@"success"].toBool, "require does not fall back to relative modules when absolutes are not available");
}

// https://github.com/commonjs/commonjs/tree/master/tests/modules/1.0/exactExports
- (void)testExactExports
{
    [_manager provideScript:@"exports.program = function(){ return require('program'); };" forModuleId:@"a"];
    [_manager provideScript:@"var a = require('a'); exports.a = a; exports.exports = exports;" forModuleId:@"program"];
    
    XJSValue *module = [_manager requireModule:@"program"];
    XCTAssertEqualObjects([module[@"a"][@"program"] callWithArguments:nil], module[@"exports"], "exact exports");
}

// https://github.com/commonjs/commonjs/blob/master/tests/modules/1.0/monkeys/a.js
- (void)testMonkeys // Umm...
{
    [_manager provideScript:@"require('program').monkey = 10" forModuleId:@"a"];
    [_manager provideScript:@"var a = require('a')" forModuleId:@"program"];
    
    XJSValue *module = [_manager requireModule:@"program"];
    XCTAssertEqual(module[@"monkey"].toInt32, 10, "monkeys permitted");
}

// https://github.com/commonjs/commonjs/tree/master/tests/modules/1.0/relative
- (void)testRelative
{
    [_manager provideScript:@"exports.foo = require('./b').foo" forModuleId:@"submodule/a"];
    [_manager provideScript:@"exports.foo = {}" forModuleId:@"submodule/b"];
    [_manager provideScript:@"exports.a = require('submodule/a').foo; exports.b = require('submodule/b').foo" forModuleId:@"program"];
    
    XJSValue *module = [_manager requireModule:@"program"];
    XCTAssertEqualObjects(module[@"a"], module[@"b"], "a and b share foo through a relative require");
}

// https://github.com/commonjs/commonjs/tree/master/tests/modules/1.0/transitive
- (void)testTransitive
{
    [_manager provideScript:@"exports.foo = require('b').foo;" forModuleId:@"a"];
    [_manager provideScript:@"exports.foo = require('c').foo;" forModuleId:@"b"];
    [_manager provideScript:@"exports.foo = {val:42};" forModuleId:@"c"];
    
    XJSValue *module = [_manager requireModule:@"a"];
    XCTAssertEqual(module[@"foo"][@"val"].toInt32, 42);
}

- (void)testBuildInModuleObjC
{
    XJSValue *module = [_manager requireModule:@"xjs/objc"];
    XCTAssertNotNil(module);
    
    XCTAssertEqualObjects(module[@"NSObject"].toObject, [NSObject class]);
}

- (void)testBuildInModuleLog
{
    XJSValue *module = [_manager requireModule:@"xjs/log"];
    XCTAssertNotNil(module);
    
    XCTAssertTrue(module.isCallable);
    XCTAssertTrue(module[@"debug"].isCallable);
}

- (void)testGetPaths
{
    XCTAssertEqualObjects(_manager.require[@"paths"].toObject, @[]);
    
    _manager.paths = @[@"1", @"2"];
    XCTAssertEqualObjects(_manager.require[@"paths"].toObject, (@[@"1", @"2"]));
    
    _manager.paths = nil;
    XCTAssertEqualObjects(_manager.require[@"paths"].toObject, nil);
    
    _manager.paths = @[];
    XCTAssertEqualObjects(_manager.require[@"paths"].toObject, @[]);
    
    _manager.paths = @[@"3", @"4"];
    XCTAssertEqualObjects(_manager.require[@"paths"].toObject, (@[@"3", @"4"]));
}

- (void)testSetPaths
{
    XCTAssertEqualObjects(_manager.paths, @[]);
    
    _manager.require[@"paths"] = @[@"1", @"2"];
    XCTAssertEqualObjects(_manager.paths, (@[@"1", @"2"]));

    _manager.require[@"paths"] = nil;
    XCTAssertEqualObjects(_manager.paths, nil);
    
    _manager.require[@"paths"] = @[];
    XCTAssertEqualObjects(_manager.paths, @[]);
    
    _manager.require[@"paths"] = @[@"3", @"4"];
    XCTAssertEqualObjects(_manager.paths, (@[@"3", @"4"]));
}

#pragma mark - helpers

- (XJSValue *)createDummyModule
{
    XJSValue *value = [XJSValue valueWithNewObjectInContext:_context];
    value[@"val"] = @42;
    value[@"name"] = @"test";
    return value;
}

- (void)assertModule:(XJSValue *)module
{
    XCTAssertNotNil(module);
    XCTAssertFalse(module.isPrimitive);
    XCTAssertEqual(module[@"val"].toInt32, 42);
    XCTAssertEqualObjects(module[@"name"].toString, @"test");
}

- (void)assertPaths:(NSArray *)paths
{
    XCTAssertEqual(paths.count, _paths.size(), "size not match");
    for (int i = 0; i < paths.count; ++i) {
        XCTAssertEqualObjects(paths[0], _paths[0]);
    }
}

@end
