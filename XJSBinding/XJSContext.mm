//
//  XJSContext.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-7.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSContext_Private.hh"

#import <XLCUtils/XLCUtils.h>
#import "jsapi.h"

#import "XJSLogging_Private.h"

#import "NSError+XJSError_Private.h"
#import "NSObject+XJSValueConvert.h"

#import "XJSRuntime_Private.hh"
#import "XJSValue_Private.hh"
#import "XJSRuntimeEntry.hh"
#import "XJSModuleManager.h"

static NSMutableDictionary *contextDict;

static JSClass global_class = {
    "global",
    JSCLASS_NEW_RESOLVE | JSCLASS_GLOBAL_FLAGS,
    JS_PropertyStub,
    JS_DeletePropertyStub,
    JS_PropertyStub,
    JS_StrictPropertyStub,
    JS_EnumerateStub,
    JS_ResolveStub,
    JS_ConvertStub,
    NULL,
    JSCLASS_NO_OPTIONAL_MEMBERS
};

/* The error reporter callback. */
static void reportError(JSContext *cx, const char *message, JSErrorReport *report) {
    XJSLogInfo(@"%s:%u:%s", report->filename ? report->filename : "<no filename>", (unsigned int) report->lineno, message);
    [[XJSContext contextForJSContext:cx] addError:[NSError errorWithXJSDomainAndFileName:@(report->filename ?: "") lineNumber:report->lineno message:@(message)]];
}

@implementation XJSContext
{
    JSCompartment *_compartment;
    JSFunction *_scopeWrapperFunc;
}

+ (void)initialize
{
    if (self == [XJSContext class]) {
        contextDict = [NSMutableDictionary dictionary];
    }
}

+ (XJSContext *)contextForJSContext:(JSContext *)jscontext {
    NSValue *key = [NSValue valueWithPointer:jscontext];
    @synchronized(contextDict) {
        id (^block)(void) = contextDict[key];
        id context = block ? block() : nil;
        if (!context) {
            [contextDict removeObjectForKey:key];
        }
        return context;
    }
}

+ (NSArray *)allContexts
{
    NSMutableArray *contexts = [NSMutableArray array];
    
    @synchronized(contextDict) {
        for (id (^block)(void) in [contextDict allValues]) {
            id cx = block();
            if (cx) {
                [contexts addObject:cx];
            }
        }
    }
    
    return contexts;
}

#pragma mark -

- (id)init {
    return [self initWithRuntime:[[XJSRuntime alloc] init]];
}

- (id)initWithRuntime:(XJSRuntime *)runtime
{
    self = [super init];
    if (self) {
        _runtime = runtime;
        _errorStack = [NSMutableArray array];
        _treatePropertyAsMethod = YES;
        
        __weak __typeof__(self) weakSelf = self;
        
        @synchronized(_runtime) {
            _context = JS_NewContext(runtime.runtime, 8192);
//            JS_SetOptions(_context, JSOPTION_VAROBJFIX);  // no I don't want this "fix"
            JS_SetErrorReporter(_context, reportError);
        }
        
        @synchronized(contextDict) {
            contextDict[[NSValue valueWithPointer:_context]] = [^() { return weakSelf; } copy]; // weak ref value
        }
        
        @synchronized(_runtime) {
            JS::CompartmentOptions options;
            options.setVersion(JSVERSION_LATEST);
            
            JS::RootedObject global(_context, JS_NewGlobalObject(_context, &global_class, NULL, JS::DontFireOnNewGlobalHook, options));
            
            _compartment = JS_EnterCompartment(_context, global);
            
            JS_InitStandardClasses(_context, global);
            
            _globalObject = global;
            XLCAssertNotNullCritical(_globalObject, @"failed to create gloabl object");
            
            JS_AddObjectRoot(_context, &_globalObject);
            
            JS_FireOnNewGlobalObject(_context, global);
        };
    }
    return self;
}

- (void)dealloc
{
    @synchronized(_runtime) {
        JS_LeaveCompartment(_context, _compartment);
        
        if (_runtimeEntryObject) {
            JS_RemoveObjectRoot(_context, &_runtimeEntryObject);
        }
        
        JS_RemoveObjectRoot(_context, &_globalObject);
        
        JS_DestroyContext(_context);
    }
    
    @synchronized(contextDict) {
        [contextDict removeObjectForKey:[NSValue valueWithPointer:_context]];
    }
}

#pragma mark -

- (NSString *)description
{
    return self.name;
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p; runtime = %@; name = %@>", [self class], self, self.runtime, self.name];
}

#pragma mark -

- (void)gcIfNeed
{
    @synchronized(_runtime) {
        JS_MaybeGC(_context);
    };
}

#pragma mark -

- (void)pushErrorStack
{
    [_errorStack addObject:[NSMutableArray array]];
}

- (void)popErrorStack
{
    [_errorStack removeLastObject];
}

- (void)addError:(NSError *)error
{
    if (self.errorHandler) {
        self.errorHandler(self, error);
    }
    [[_errorStack lastObject] addObject:error];
}

- (NSError *)error
{
    NSArray *errors = [_errorStack lastObject];
    if (errors.count == 0) {
        return nil;
    }
    if (errors.count == 1) {
        return [errors lastObject];
    }
    return [NSError errorWithXJSDomainAndDetailedErrors:errors];
}

#pragma mark -

- (XJSValue *)evaluateString:(NSString *)script error:(NSError **)error
{
    return [self evaluateString:script withScope:nil fileName:nil lineNumber:0 error:error];
}

- (XJSValue *)evaluateString:(NSString *)script fileName:(NSString *)filename lineNumber:(NSUInteger)lineno error:(NSError **)error
{

    return [self evaluateString:script withScope:nil fileName:filename lineNumber:lineno error:error];
}

- (XJSValue *)evaluateScriptFile:(NSString *)path error:(NSError **)error
{
    return [self evaluateScriptFile:path withScope:nil error:error];
}

- (XJSValue *)evaluateString:(NSString *)script withScope:(XJSValue *)scope error:(NSError **)error
{
    return [self evaluateString:script withScope:scope fileName:nil lineNumber:0 error:error];
}

- (XJSValue *)evaluateString:(NSString *)script withScope:(XJSValue *)scope fileName:(NSString *)filename lineNumber:(NSUInteger)lineno error:(NSError **)error
{
    jsval outVal;
    [self pushErrorStack];
    
    BOOL ok;
    
    @synchronized(_runtime) {
        BOOL useGlobalScope = !scope || scope.isPrimitive;
        JSObject *scopeObject = useGlobalScope ? _globalObject : scope.value.toObjectOrNull();
        
        ok = JS_EvaluateScript(_context, scopeObject, [script UTF8String], (unsigned)[script length], [filename UTF8String], (unsigned)lineno, &outVal);
    }
    
    if (error) {
        *error = [self error];
    }
    
    XJSValue *value = ok ? [[XJSValue alloc] initWithContext:self value:outVal] : nil;
    [self popErrorStack];
    
    return value;

}

// TODO avoid load whole file into memory
- (XJSValue *)evaluateScriptFile:(NSString *)path withScope:(XJSValue *)scope error:(NSError **)error
{
    NSString *script = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:error];
    if (!script) {
        return nil;
    }
    return [self evaluateString:script withScope:scope fileName:path lineNumber:0 error:error];
}

#pragma mark -

- (BOOL)isStringCompilableUnit:(NSString *)str
{
    @synchronized(_runtime) {
        return JS_BufferIsCompilableUnit(_context, _globalObject, [str UTF8String], str.length);
    }
}

#pragma mark -

- (void)createModuleManager
{
    if (self.moduleManager) {
        return;
    }
    
    self.moduleManager = [[XJSModuleManager alloc] initWithContext:self scriptProvider:^NSString *(NSString *path) {
        return [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    }];
    
    self[@"require"] = self.moduleManager.require;
}

- (void)createObjCRuntimeWithNamespace:(NSString *)name
{
    @synchronized(_runtime) {
        if (!_runtimeEntryObject) {
            _runtimeEntryObject = XJSCreateRuntimeEntry(_context);
            JS_AddObjectRoot(_context, &_runtimeEntryObject);
        }
    }
    
    if ([name length]) {
        self[name] = [[XJSValue alloc] initWithContext:self value:JS::ObjectOrNullValue(_runtimeEntryObject)];
    }
}

@end

#pragma mark - SubscriptSupport

@implementation XJSContext(SubscriptSupport)

- (XJSValue *)objectForKeyedSubscript:(NSString *)key
{
    NSArray *components = [key componentsSeparatedByString:@"."];
    @synchronized(_runtime) {
        JS::RootedObject obj(_context);
        obj.set(_globalObject);
        for (int i = 0; i < components.count - 1; ++i) {
            NSString *path = components[i];
            JS::RootedValue outval(_context);
            if (JS_GetProperty(_context, obj, [path UTF8String], &outval)) {
                if (outval.isObject()) {
                    obj.set(outval.toObjectOrNull());
                } else {
                    return [XJSValue valueWithUndefinedInContext:self];
                }
            } else {
                return nil;
            }
        }
        
        JS::RootedValue val(_context);
        if (JS_GetProperty(_context, obj, [[components lastObject] UTF8String], &val)) {
            return [[XJSValue alloc] initWithContext:self value:val];
        } else {
            return nil;
        }
    }
}

- (void)setObject:(id)object forKeyedSubscript:(NSString *)key
{
    NSArray *components = [key componentsSeparatedByString:@"."];

    @synchronized(_runtime) {
        JS::RootedObject obj(_context);
        obj.set(_globalObject);
        for (int i = 0; i < components.count - 1; ++i) {
            NSString *path = components[i];
            JS::RootedValue outval(_context);
            if (JS_GetProperty(_context, _globalObject, [path UTF8String], &outval)) {
                if (outval.isNullOrUndefined()) {
                    JS::RootedValue val(_context, JS::ObjectOrNullValue(JS_NewObject(_context, NULL, NULL, NULL)));
                    JS_SetProperty(_context, obj, [path UTF8String], val);
                    obj.set(val.toObjectOrNull());
                } else {
                    obj.set(outval.toObjectOrNull());
                }
            } else {
                return;
            }
        }
        
        JS::RootedValue inval(_context, XJSToValue(self, object).value);
        JS_SetProperty(_context, obj, [[components lastObject] UTF8String], inval);
    }
}

@end