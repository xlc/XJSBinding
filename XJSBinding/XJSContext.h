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
@property (strong, readonly) NSString *errorMessage;
@property (strong, readonly) XJSValue *globalObject;

/**
 * Create a JS context with a new JS runtime
 */
- (id)init;

/**
 * JS runtime must be create in the same thread
 */
- (id)initWithRuntime:(XJSRuntime *)runtime;

//- (XJSValue *)evalutateScript:(NSString *)script;
//- (XJSValue *)evalutateScriptAtURL:(NSURL *)url;
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
