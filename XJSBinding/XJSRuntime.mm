//
//  XJSRuntime.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-7.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSRuntime_Private.h"

#import "jsapi.h"
#import "XLCAssertion.h"

@implementation XJSRuntime

- (id)init
{
    self = [super init];
    if (self) {
        // TODO allow to config heap size and stack size
        _runtime = JS_NewRuntime(8L * 1024L * 1024L, JS_NO_HELPER_THREADS);
        JS_SetNativeStackQuota(_runtime, 128 * sizeof(size_t) * 1024);
    }
    return self;
}

- (void)dealloc
{
    JS_DestroyRuntime(_runtime);
}

#pragma mark -

- (void)performBlock:(void (^)(void))block
{
    if (block == nil) {
        return;
    }
    
    @synchronized(self) {
        block();
    }
}

#pragma mark -

- (void)gc
{
    @synchronized(self) {
        JS_GC(self.runtime);
    }
}

@end
