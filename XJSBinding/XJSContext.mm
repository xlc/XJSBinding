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

#import "XJSRuntime_Private.h"

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
    NSString *errorString = [NSString stringWithFormat:@"%s:%u:%s", report->filename ? report->filename : "<no filename="">", (unsigned int) report->lineno, message];
    XWLOG(@"%@", errorString);
    [contextDict[[NSValue valueWithPointer:cx]] setErrorMessage:errorString];
}

@implementation XJSContext

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
        id context = block();
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
        
        __weak __typeof__(self) weakSelf = self;
        
        [_runtime performBlockAndWait:^{
            _context = JS_NewContext(runtime.runtime, 8192);
            
            @synchronized(contextDict) {
                contextDict[[NSValue valueWithPointer:_context]] = [^() { return weakSelf; } copy]; // weak ref value
            }
            
            JS_SetOptions(_context, JSOPTION_VAROBJFIX);
            JS_SetVersion(_context, JSVERSION_LATEST);
            JS_SetErrorReporter(_context, reportError);
            
            JSAutoRequest ar(_context);
            JSObject *global = JS_NewGlobalObject(_context, &global_class, NULL);
            XASSERT(global != NULL, @"fail to create gloabl object");
            
            JSAutoCompartment ac(_context, global);
            JS_SetGlobalObject(_context, global);
            
            JS_InitStandardClasses(_context, global);
        }];
    }
    return self;
}

- (void)dealloc
{
    [_runtime performBlockAndWait:^{
        JS_DestroyContext(_context);
    }];
    
    @synchronized(contextDict) {
        [contextDict removeObjectForKey:[NSValue valueWithPointer:_context]];
    }
}

@end
