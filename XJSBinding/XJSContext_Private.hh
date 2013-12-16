//
//  XJSContext_Private.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-7.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSContext.h"

#import "jsapi.h"

@interface XJSContext ()
{
    NSMutableArray *_errorStack;
}

@property (assign, readonly) JSContext *context;
@property (assign, readonly) JSObject *globalObject;
@property (assign, readonly) JSObject *runtimeEntryObject;

@property (strong) XJSModuleManager *moduleManager; // mainly for test

+ (XJSContext *)contextForJSContext:(JSContext *)jscontext;

- (void)pushErrorStack;
- (void)popErrorStack;
- (void)addError:(NSError *)error;
- (NSError *)error;

@end
