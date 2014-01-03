//
//  XJSModuleManager.mm
//  XJSBinding
//
//  Created by Xiliang Chen on 13-12-12.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSModuleManager.h"

#import <XLCUtils/XLCUtils.h>
#import "jsapi.h"

#import "XJSValue_Private.hh"
#import "XJSContext_Private.hh"
#import "XJSValueWeakRef.h"
#import "NSObject+XJSValueConvert.h"

@interface XJSModuleManager ()

- (NSString *)resolveModuleId:(NSString *)moduleId; // to absolute module id
- (NSString *)scriptFromModuleId:(NSString *)moduleId;
- (XJSValue *)resolveModule:(id)obj moduleId:(NSString *)moduleId;

@end

static NSMutableDictionary *globalModules;

@implementation XJSModuleManager
{
    NSString *(^_scriptProvider)(NSString *path);
    NSMutableDictionary *_modules;
    NSMutableArray *_stack;
    XJSValueWeakRef *_require; // XJSModuleManager cannot hold strong ref to XJSContext
}

#pragma mark -

+ (void)initialize
{
    if (self == [XJSModuleManager class]) {
        globalModules = [NSMutableDictionary dictionary];
    }
}

+ (void)provideValue:(XJSValue *)exports forModuleId:(NSString *)moduleId
{
    XASSERT(globalModules[moduleId] == nil, @"module already exists for id: %@, module: %@", moduleId, globalModules[moduleId]);
    XASSERT([moduleId length] != 0, @"empty moduleId");
    @synchronized(globalModules) {
        globalModules[moduleId] = exports;
    }
}

+ (void)provideScript:(NSString *)script forModuleId:(NSString *)moduleId
{
    [self provideBlock:^BOOL(XJSValue *require, XJSValue *exports, XJSValue *module) {
        if ([script length] == 0) {
            return YES;
        }
        XJSValue *scope = [XJSValue valueWithNewObjectInContext:require.context];
        scope[@"require"] = require;
        scope[@"exports"] = exports;
        scope[@"module"] = module;
        return !![require.context evaluateString:script withScope:scope fileName:moduleId lineNumber:0 error:NULL];
    } forModuleId:moduleId];
}

+ (void)provideBlock:(BOOL(^)(XJSValue *require, XJSValue *exports, XJSValue *module))block forModuleId:(NSString *)moduleId
{
    XASSERT(globalModules[moduleId] == nil, @"module already exists for id: %@, module: %@", moduleId, globalModules[moduleId]);
    XASSERT([moduleId length] != 0, @"empty moduleId");
    @synchronized(globalModules) {
        globalModules[moduleId] = block;
    }
}

#pragma mark -

- (id)initWithContext:(XJSContext *)context scriptProvider:(NSString *(^)(NSString *path))scriptProvider
{
    XASSERT_NOTNULL(scriptProvider);
    
    self = [super init];
    if (self) {
        _context = context;
        _scriptProvider = scriptProvider;
        _modules = [NSMutableDictionary dictionary];
        _stack = [NSMutableArray array];
        _paths = [NSArray array];
    }
    return self;
}

#pragma mark -

static JSBool XJSRequireFunc(JSContext *cx, unsigned argc, JS::Value *vp)
{
    auto args = JS::CallArgsFromVp(argc, vp);
    
    JSString *jsstr;
    if (!JS_ConvertArguments(cx, argc, args.array(), "S", &jsstr)) {
        return JS_FALSE;
    }
    
    JSAutoByteString str;
    
    NSString *moduleId = @(str.encodeUtf8(cx, jsstr));
    
    XJSModuleManager *manager = [XJSContext contextForJSContext:cx].moduleManager;
    
    XJSValue *val = [manager requireModule:moduleId];
    if (val) {
        args.rval().set(val.value);
        
        return JS_TRUE;
    } else {
        if (!JS_IsExceptionPending(cx)) {   // avoid override old exception
            JS_ReportError(cx, "Fail to load module %s", [moduleId UTF8String]);
        }
        
        return JS_FALSE;
    }
}

static JSBool XJSGetPaths(JSContext *cx, JS::Handle<JSObject*> obj, JS::Handle<jsid> jid, JS::MutableHandle<JS::Value> vp)
{
    XJSContext *context = [XJSContext contextForJSContext:cx];
    XJSModuleManager *manager = context.moduleManager;
    
    XJSValue *pathsVal = XJSToValue(context, manager.paths);
    vp.set(pathsVal.value);
    
    return JS_TRUE;
}

static JSBool XJSSetPaths(JSContext *cx, JS::Handle<JSObject*> obj, JS::Handle<jsid> jid, JSBool strict, JS::MutableHandle<JS::Value> vp)
{
    if (!vp.isObjectOrNull()) {
        JS_ReportError(cx, "require.paths must be an array of strings");
        return JS_FALSE;
    }
    
    XJSContext *context = [XJSContext contextForJSContext:cx];
    XJSModuleManager *manager = context.moduleManager;
    
    XJSValue *val = [[XJSValue alloc] initWithContext:context value:vp];
    
    if (val.isNullOrUndefined) {
        manager.paths = nil;
        return JS_TRUE;
    }
    
    NSArray *arr = val.toArray;
    if (!arr) {
        JS_ReportError(cx, "require.paths must be an array of strings");
        return JS_FALSE;
    }
    
    NSMutableArray *paths = [NSMutableArray arrayWithCapacity:arr.count];
    
    for (id element in arr) {
        if ([element isKindOfClass:[NSString class]]) {
            [paths addObject:element];
        } else {
            XWLOG("require.paths must be an array of strings. element (%@) ignored.", element);
        }
    }
    
    manager.paths = paths;
    
    return JS_TRUE;
}


- (XJSValue *)require
{
    XJSValue *require = _require.value;
    if (require) {
        return require;
    }
    
    JSFunction *fun = JS_NewFunction(_context.context, XJSRequireFunc, 1, 0, NULL, "require");
    JSObject *obj = JS_GetFunctionObject(fun);
    require = [[XJSValue alloc] initWithContext:_context value:JS::ObjectOrNullValue(obj)];
    
    JS_DefineProperty(_context.context, obj, "paths", JS::NullValue(), XJSGetPaths, XJSSetPaths, JSPROP_PERMANENT | JSPROP_SHARED);
    
    return require;
}

#pragma mark -

- (XJSValue *)requireModule:(NSString *)moduleId
{
    @synchronized(_context.runtime) {
        
        moduleId = [self resolveModuleId:moduleId];
        
        [_stack addObject:moduleId];
        
        id module = _modules[moduleId] ?: [globalModules objectForKey:moduleId];    // globalModules[moduleId] make clang crash...
        if (!module) {
            module = ^BOOL(XJSValue *require, XJSValue *exports, XJSValue *module) {
                NSString *script = [self scriptFromModuleId:moduleId];
                if (script) {   // find script
                    if ([script length] == 0) { // empty script, fine
                        return YES;
                    }
                    XJSValue *scope = [XJSValue valueWithNewObjectInContext:_context];
                    scope[@"require"] = require;
                    scope[@"exports"] = exports;
                    scope[@"module"] = module;
                    return !![_context evaluateString:script withScope:scope fileName:moduleId lineNumber:0 error:NULL];
                }
                return NO;
            };
        }
        
        XJSValue *val = [self resolveModule:module moduleId:moduleId];
        
        [_stack removeLastObject];
        
        return val;
    }
}

- (void)provideValue:(XJSValue *)exports forModuleId:(NSString *)moduleId
{
    XASSERT(_modules[moduleId] == nil, @"module already exists for id: %@, module: %@", moduleId, _modules[moduleId]);
    XASSERT([moduleId length] != 0, @"empty moduleId");
    @synchronized(_context.runtime) {
        _modules[moduleId] = exports;
    }
}

- (void)provideScript:(NSString *)script forModuleId:(NSString *)moduleId
{
    [self provideBlock:^BOOL(XJSValue *require, XJSValue *exports, XJSValue *module) {
        if ([script length] == 0) {
            return YES;
        }
        XJSValue *scope = [XJSValue valueWithNewObjectInContext:_context];
        scope[@"require"] = require;
        scope[@"exports"] = exports;
        scope[@"module"] = module;
        return !![_context evaluateString:script withScope:scope fileName:moduleId lineNumber:0 error:NULL];
    } forModuleId:moduleId];
}

- (void)provideBlock:(BOOL(^)(XJSValue *require, XJSValue *exports, XJSValue *module))block forModuleId:(NSString *)moduleId
{
    XASSERT(_modules[moduleId] == nil, @"module already exists for id: %@, module: %@", moduleId, _modules[moduleId]);
        XASSERT([moduleId length] != 0, @"empty moduleId");
    @synchronized(_context.runtime) {
        _modules[moduleId] = [block copy];
    }
}

#pragma mark -

- (NSString *)resolveModuleId:(NSString *)moduleId
{
    moduleId = [moduleId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if ([moduleId hasPrefix:@"."]) {
        NSString *currentPath = [_stack lastObject];
        if (!currentPath) {
            currentPath = @"";
        }
        
        moduleId = [[currentPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:moduleId];
    }
    
    NSArray *pathComponents = [moduleId pathComponents];
    NSString *path = @"";
    for (NSString *str in pathComponents) {
        if ([str isEqualToString:@"."]) {
            continue;
        }
        if ([str isEqualToString:@".."] && [path length] > 0) {
            path = [path stringByDeletingLastPathComponent];
        } else {
            path = [path stringByAppendingPathComponent:str];
        }
    }
    
    return path;
}

- (XJSValue *)resolveModule:(id)obj moduleId:(NSString *)moduleId
{
    if ([obj isKindOfClass:[XJSValue class]]) {
        return obj;
    }
    
    XJSValue *exports = [XJSValue valueWithNewObjectInContext:_context];
    XJSValue *module = [XJSValue valueWithNewObjectInContext:_context];
    
    _modules[moduleId] = exports;
    
    module[@"id"] = moduleId;
    module[@"exports"] = exports;
    bool success = ((BOOL(^)(XJSValue *, XJSValue *, XJSValue *))obj)(self.require, exports, module);
    if (!success) {
        return nil;
    }
    
    XJSValue *exp = module[@"exports"];
    exports = exp.isNullOrUndefined ? exports : exp;
    _modules[moduleId] = exports;
    
    return exports;
}

- (NSString *)scriptFromModuleId:(NSString *)moduleId
{
    for (NSString *path in self.paths) {
        NSString *script = _scriptProvider([path stringByAppendingPathComponent:moduleId]);
        if (script) {
            return script;
        }
        script = _scriptProvider([path stringByAppendingPathComponent:[moduleId stringByAppendingPathExtension:@"js"]]);
        if (script) {
            return script;
        }
    }
    return nil;
}

@end
