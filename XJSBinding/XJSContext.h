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
@class XJSModuleManager;

@interface XJSContext : NSObject

@property (strong, readonly) XJSRuntime *runtime;
@property (strong, readonly) XJSModuleManager *moduleManager;

@property (strong) void (^errorHandler)(XJSContext *context, NSError *error);

@property (copy) NSString *name;

/**
 * Create a JS context with a new JS runtime
 */
- (id)init;

- (id)initWithRuntime:(XJSRuntime *)runtime;

- (void)createModuleManager;

// call this method to get all the magic of Objective-C binding
- (void)createObjCRuntimeWithNamespace:(NSString *)name;

- (void)gcIfNeed;

- (XJSValue *)evaluateString:(NSString *)script error:(NSError **)error;
- (XJSValue *)evaluateString:(NSString *)script fileName:(NSString *)filename lineNumber:(NSUInteger)lineno error:(NSError **)error;
- (XJSValue *)evaluateScriptFile:(NSString *)path error:(NSError **)error;

// nil scope for global scope
- (XJSValue *)evaluateString:(NSString *)script withScope:(XJSValue *)scope error:(NSError **)error;
- (XJSValue *)evaluateString:(NSString *)script withScope:(XJSValue *)scope fileName:(NSString *)filename lineNumber:(NSUInteger)lineno error:(NSError **)error;
- (XJSValue *)evaluateScriptFile:(NSString *)path withScope:(XJSValue *)scope error:(NSError **)error;

- (BOOL)isStringCompilableUnit:(NSString *)str;

//
////-------
//
//+ (XJSContext *)currentContext;
//

@end

@interface XJSContext(SubscriptSupport)

- (XJSValue *)objectForKeyedSubscript:(NSString *)key;
- (void)setObject:(id)object forKeyedSubscript:(NSString *)key;

@end