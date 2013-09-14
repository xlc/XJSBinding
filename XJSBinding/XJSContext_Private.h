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
    JSObject *_globalObject;
}

@property (assign, readonly) JSContext *context;

+ (XJSContext *)contextForJSContext:(JSContext *)jscontext;

- (void)pushErrorStack;
- (void)popErrorStack;
- (void)addError:(NSError *)error;
- (NSError *)error;

@end
