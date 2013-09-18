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

#import "XJSRuntimeThread.h"

@implementation XJSRuntime

- (id)init
{
    self = [super init];
    if (self) {
        _thread = [[XJSRuntimeThread alloc] initWithRuntime:self];
        [_thread start];
    }
    return self;
}

- (void)dealloc
{
    [self.thread stop];
}

#pragma mark -

- (void)performBlock:(void (^)(void))block
{
    if (block == nil) {
        return;
    }
    if ([self isRuntimeThread]) {
        block();
    } else {
        [self performSelector:@selector(_performBlock:) onThread:self.thread withObject:block waitUntilDone:NO modes:@[NSRunLoopCommonModes]];
    }
}

- (void)performBlockAndWait:(void (^)(void))block
{
    if (block == nil) {
        return;
    }
    if ([self isRuntimeThread]) {
        block();
    } else {
        [self performSelector:@selector(_performBlock:) onThread:self.thread withObject:block waitUntilDone:YES modes:@[NSRunLoopCommonModes]];
    }
}

- (void)_performBlock:(void (^)(void))block
{
    block();
}

#pragma mark -

- (void)gc
{
    [self performBlock:^{
        JS_GC(self.runtime);
    }];
}

- (BOOL)isRuntimeThread
{
    return [[NSThread currentThread] isEqual:self.thread];
}

@end
