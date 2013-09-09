//
//  XLCTestUtils.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-8.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XLCTestUtils.h"

#import <mach/mach_time.h>
#import <objc/runtime.h>
#import <objc/message.h>

BOOL XLCRunloopRunUntil(CFTimeInterval timeout, BOOL (^condition)(void)) {
    static mach_timebase_info_data_t timebaseInfo;
    if ( timebaseInfo.denom == 0 ) {
        mach_timebase_info(&timebaseInfo);
    }
    
    uint64_t timeoutNano = timeout * 1e9;
    
    uint64_t start = mach_absolute_time();
    do {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, YES);
        XLCRunloopRunOnce();
        uint64_t end = mach_absolute_time();
        uint64_t elapsed = end - start;
        uint64_t elapseNano = elapsed * timebaseInfo.numer / timebaseInfo.denom;
        if (elapseNano >= timeoutNano) {
            return NO;
        }
    } while (!condition());
    
    return YES;
}

@implementation NSObject (XLCTestUtilsMemoryDebug)

static void *autoreleaseCountKey = &autoreleaseCountKey;
static void *originalClassKey = &originalClassKey;  // [self class]
static void *originalIsaKey = &originalIsaKey;  // self->isa

static NSString * const classSuffix = @"_XLCTestUtilsMemoryDebug";

- (id)xlc_swizzleRetainRelease {
    
    Class oldcls = object_getClass(self);
    
    if ([[oldcls description] hasSuffix:classSuffix]) { // already swizzled
        return self;
    }
    
    objc_setAssociatedObject(self, originalIsaKey, oldcls, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, originalClassKey, [self class], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    NSString *newClassName = [[oldcls description] stringByAppendingString:@"_XLCTestUtilsMemoryDebug"];
    
    Class newcls = NSClassFromString(newClassName);
    if (!newcls) {
        newcls = objc_allocateClassPair(oldcls, [newClassName UTF8String], 0);
        
        class_addMethod(newcls,
                        @selector(retain),
                        [NSObject instanceMethodForSelector:@selector(xlc_retain)],
                        "@@:");
        
        class_addMethod(newcls,
                        @selector(release),
                        [NSObject instanceMethodForSelector:@selector(xlc_release)],
                        "v@:");
        
        class_addMethod(newcls,
                        @selector(autorelease),
                        [NSObject instanceMethodForSelector:@selector(xlc_autorelease)],
                        "@@:");
        
        class_addMethod(newcls,
                        @selector(class),
                        [NSObject instanceMethodForSelector:@selector(xlc_class)],
                        "@@:");
        
        class_addMethod(newcls,
                        @selector(dealloc),
                        [NSObject instanceMethodForSelector:@selector(xlc_dealloc)],
                        "v@:");
    }
    
    object_setClass(self, newcls);
    return self;
}

- (void)xlc_restoreRetainRelease {
    Class oldcls = objc_getAssociatedObject(self, originalIsaKey);
    if (!oldcls) {  // not swizzled
        return;
    }
    
    object_setClass(self, oldcls);
}

- (NSUInteger)xlc_autoreleaseCount {
    return [objc_getAssociatedObject(self, autoreleaseCountKey) unsignedIntegerValue];
}

- (id)xlc_retain
{
    struct objc_super superstruct = { self, objc_getAssociatedObject(self, originalIsaKey) };
    return objc_msgSendSuper(&superstruct, @selector(retain));
}

- (void)xlc_release
{
    struct objc_super superstruct = { self, objc_getAssociatedObject(self, originalIsaKey) };
    objc_msgSendSuper(&superstruct, @selector(release));
}

- (id)xlc_autorelease
{
    @synchronized(self) {
        NSUInteger count = [objc_getAssociatedObject(self, autoreleaseCountKey) unsignedIntegerValue] + 1;
        objc_setAssociatedObject(self, autoreleaseCountKey, @(count), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    struct objc_super superstruct = { self, [NSObject class] };
    return objc_msgSendSuper(&superstruct, @selector(autorelease));
}

- (Class)xlc_class
{
    return objc_getAssociatedObject(self, originalClassKey);
}

- (void)xlc_dealloc
{
    struct objc_super superstruct = { self, objc_getAssociatedObject(self, originalIsaKey) };
    objc_msgSendSuper(&superstruct, @selector(release));
}

- (NSUInteger)xlc_retainCount
{
    return [self retainCount];
}

@end