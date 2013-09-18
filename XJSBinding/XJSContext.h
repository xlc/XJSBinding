//
//  XJSContext.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-7.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XJSValue;
@class XJSRuntime;

@interface XJSContext : NSObject

@property (strong, readonly) XJSRuntime *runtime;

@property (strong) void (^errorHandler)(XJSContext *context, NSError *error);

/**
 * Create a JS context with a new JS runtime
 */
- (id)init;

/**
 * JS runtime must be create in the same thread
 */
- (id)initWithRuntime:(XJSRuntime *)runtime;

- (void)gcIfNeed;

// handler will be invoked on the caller thread if possible.
// otherwise dispatch queue returned from dispatch_get_current_queue

- (void)evaluateString:(NSString *)script completionHandler:(void(^)(XJSValue *value, NSError *error))handler;
- (void)evaluateString:(NSString *)script fileName:(NSString *)filename lineNumber:(NSUInteger)lineno completionHandler:(void(^)(XJSValue *value, NSError *error))handler;
- (void)evaluateScriptFile:(NSString *)path completionHandler:(void(^)(XJSValue *value, NSError *error))handler;
- (void)evaluateScriptFile:(NSString *)path encoding:(NSStringEncoding)enc completionHandler:(void(^)(XJSValue *value, NSError *error))handler;

- (XJSValue *)evaluateString:(NSString *)script error:(NSError **)error;
- (XJSValue *)evaluateString:(NSString *)script fileName:(NSString *)filename lineNumber:(NSUInteger)lineno error:(NSError **)error;
- (XJSValue *)evaluateScriptFile:(NSString *)path error:(NSError **)error;
- (XJSValue *)evaluateScriptFile:(NSString *)path encoding:(NSStringEncoding)enc error:(NSError **)error;

//
////-------
//
//+ (XJSContext *)currentContext;
//
//+ (XJSContext *)defaultContext;
//+ (void)setDefaultContext:(XJSContext *)context;
//
////-------
//
//// key will be converted to string first
//- (XJSValue *)objectForKeyedSubscript:(id)key;
//- (void)setObject:(id)object forKeyedSubscript:(id)key;

@end
