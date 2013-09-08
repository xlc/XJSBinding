//
//  XJSRuntimeThread.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-7.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSRuntimeThread.h"

#import "jsapi.h"
#import "XLCAssertion.h"

#import "XJSRuntime_Private.h"

@implementation XJSRuntimeThread
{
    __weak XJSRuntime *_runtime;
    CFRunLoopRef _runloop;
}

- (id)initWithRuntime:(XJSRuntime *)runtime
{
    self = [super init];
    if (self) {
        _runtime = runtime;
    }
    return self;
}

- (void)stop {
    CFRunLoopStop(_runloop);
}

- (void)main
{ @autoreleasepool {
    _runloop = CFRunLoopGetCurrent();
    
    JSRuntime *runtime = JS_NewRuntime(8L * 1024L * 1024L, JS_NO_HELPER_THREADS);
    _runtime.runtime = runtime;
    
    // need to attach something to the runloop to keep it running
    [[NSRunLoop currentRunLoop] addPort:[NSPort port] forMode:NSDefaultRunLoopMode];
    CFRunLoopRun();
    
    // finish remain events
    while (CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.001, YES) == kCFRunLoopRunHandledSource ||
           CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, YES) == kCFRunLoopRunHandledSource);
    
    _runtime.runtime = nil;
    
    JS_DestroyRuntime(runtime);
    
    _runloop = nil;
} }

@end
