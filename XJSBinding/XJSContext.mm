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

#import "XJSRuntime_Private.h"
#import "XJSValue_Private.h"

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
        
        [_runtime performBlockAndWait:^{
            _context = JS_NewContext(runtime.runtime, 8192);
            
            @synchronized(contextDict) {
                contextDict[[NSValue valueWithPointer:_context]] = [^() { return weakSelf; } copy]; // weak ref value
            }
            
            JS_SetOptions(_context, JSOPTION_VAROBJFIX);
            JS_SetVersion(_context, JSVERSION_LATEST);
            JS_SetErrorReporter(_context, reportError);
            
            JSAutoRequest ar(_context);
            _globalObject = JS_NewGlobalObject(_context, &global_class, NULL);
            XASSERT(_globalObject != NULL, @"fail to create gloabl object");
            
            JSAutoCompartment ac(_context, _globalObject);
            JS_SetGlobalObject(_context, _globalObject);
            
            JS_InitStandardClasses(_context, _globalObject);
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

#pragma mark -

- (void)gcIfNeed
{
    [self.runtime performBlock:^{
        JS_MaybeGC(self.context);
    }];
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

- (void)evaluateString:(NSString *)script completionHandler:(void(^)(XJSValue *value, NSError *error))handler
{
    [self evaluateString:script fileName:nil lineNumber:0 completionHandler:handler];
}

- (void)evaluateString:(NSString *)script fileName:(NSString *)filename lineNumber:(NSUInteger)lineno completionHandler:(void(^)(XJSValue *value, NSError *error))handler
{
    [self.runtime performBlock:^{
        jsval outVal;
        [self pushErrorStack];
        BOOL ok = JS_EvaluateScript(self.context, _globalObject, [script UTF8String], (unsigned)[script length], [filename UTF8String], (unsigned)lineno, &outVal);
        NSError *error = [self error];
        if (handler) {
            XJSValue *value = ok ? [[XJSValue alloc] initWithContext:self value:outVal] : nil;
            handler(value, error);
        }
        [self popErrorStack];
    }];
}

- (void)evaluateScriptFile:(NSString *)path completionHandler:(void(^)(XJSValue *value, NSError *error))handler
{
    [self evaluateScriptFile:path encoding:NSUTF8StringEncoding completionHandler:handler];
}

- (void)evaluateScriptFile:(NSString *)path encoding:(NSStringEncoding)enc completionHandler:(void(^)(XJSValue *value, NSError *error))handler
{
    NSError *error;
    NSString *script = [NSString stringWithContentsOfFile:path encoding:enc error:&error];
    if (!script) {
        if (handler) {
            handler(nil, error);
        }
    } else {
        [self evaluateString:script fileName:path lineNumber:1 completionHandler:handler];
    }
}


- (XJSValue *)evaluateString:(NSString *)script error:(NSError **)error
{
    return [self evaluateString:script fileName:nil lineNumber:0 error:error];
}

- (XJSValue *)evaluateString:(NSString *)script fileName:(NSString *)filename lineNumber:(NSUInteger)lineno error:(NSError **)outError
{
    __block XJSValue *retVal;
    __block NSError *retErr;
    
    NSConditionLock *lock;
    if (![self.runtime isRuntimeThread]) {
        lock = [[NSConditionLock alloc] initWithCondition:0];
    }
    
    [self evaluateString:script fileName:filename lineNumber:lineno completionHandler:^(XJSValue *value, NSError *error) {
        retVal = value;
        retErr = error;
        
        [lock lock];
        [lock unlockWithCondition:1];
    }];
    
    [lock lockWhenCondition:1];
    [lock unlock];
    
    if (outError) {
        *outError = retErr;
    }
    
    return retVal;
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

@end
