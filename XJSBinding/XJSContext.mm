//
//  XJSContext.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-7.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSContext_Private.h"

#import "jsapi.h"
#import "XLCAssertion.h"

#import "NSError+XJSError.h"
#import "NSObject+XJSValueConvert.h"

#import "XJSRuntime_Private.h"
#import "XJSValue_Private.h"
#import "XJSBinding.h"

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
    XILOG(@"%s:%u:%s", report->filename ? report->filename : "<no filename>", (unsigned int) report->lineno, message);
    [[XJSContext contextForJSContext:cx] addError:[NSError errorWithXJSDomainAndFileName:@(report->filename ?: "") lineNumber:report->lineno message:@(message)]];
}

@implementation XJSContext
{
    JSCompartment *_compartment;
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
        
        __weak __typeof__(self) weakSelf = self;
        
        @synchronized(_runtime) {
            _context = JS_NewContext(runtime.runtime, 8192);
            JS_SetOptions(_context, JSOPTION_VAROBJFIX);
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
            XASSERT(_globalObject != NULL, @"fail to create gloabl object");
            
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
        
        JS_RemoveObjectRoot(_context, &_globalObject);
        
        JS_DestroyContext(_context);
    }
    
    @synchronized(contextDict) {
        [contextDict removeObjectForKey:[NSValue valueWithPointer:_context]];
    }
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
    return [self evaluateString:script fileName:nil lineNumber:0 error:error];
}

- (XJSValue *)evaluateString:(NSString *)script fileName:(NSString *)filename lineNumber:(NSUInteger)lineno error:(NSError **)error
{

    jsval outVal;
    [self pushErrorStack];
    
    BOOL ok;
    
    @synchronized(_runtime) {
        ok = JS_EvaluateScript(_context, _globalObject, [script UTF8String], (unsigned)[script length], [filename UTF8String], (unsigned)lineno, &outVal);
    }
    
    if (error) {
        *error = [self error];
    }
    
    XJSValue *value = ok ? [[XJSValue alloc] initWithContext:self value:outVal] : nil;
    [self popErrorStack];
    
    return value;
}

- (XJSValue *)evaluateScriptFile:(NSString *)path error:(NSError **)error
{
    return [self evaluateScriptFile:path encoding:NSUTF8StringEncoding error:error];
}

- (XJSValue *)evaluateScriptFile:(NSString *)path encoding:(NSStringEncoding)enc error:(NSError **)error
{
    NSString *script = [NSString stringWithContentsOfFile:path encoding:enc error:error];
    if (!script) {
        return nil;
    }
    return [self evaluateString:script fileName:path lineNumber:0 error:error];
}

#pragma mark -

- (void)createObjCRuntimeWithNamespace:(NSString *)name
{
    // TODO allow empty name - no public namespace created but return a XJSValue
    // TODO save namespace object so it can be used internally
    // TODO allow name to be dot seperated namespace. e.g. myapp.objc
    XASSERT_NOTNULL(name);
    _globalNamespace = [name copy];
    XJSBindingInit(name, _context, _globalObject);
}

@end

#pragma mark - SubscriptSupport

@implementation XJSContext(SubscriptSupport)

- (XJSValue *)objectForKeyedSubscript:(NSString *)key   // TODO allow key to be dot seperated namespace. e.g. myapp.value
{
    @synchronized(_runtime) {
        JS::RootedValue outval(_context);
        if (JS_GetProperty(_context, _globalObject, [key UTF8String], &outval)) {
            return [[XJSValue alloc] initWithContext:self value:outval];
        }
    }
    
    return nil;
}

- (void)setObject:(id)object forKeyedSubscript:(NSString *)key  // TODO allow key to be dot seperated namespace. e.g. myapp.value
{
    @synchronized(_runtime) {
        JS::RootedValue inval(_context, XJSToValue(self, object).value);
        JS_SetProperty(_context, _globalObject, [key UTF8String], inval);
    }

}

@end