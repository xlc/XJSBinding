//
//  XLCTestUtils.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-8.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

__BEGIN_DECLS

BOOL XLCRunloopRunUntil(CFTimeInterval timeout, BOOL (^condition)(void));

#define XLCAssertTrueBeforeTimeout(expr, timeout, format...) \
XCTAssertTrue( (XLCRunloopRunUntil(timeout, ^BOOL{ return expr; })) , ## format )


static inline void XLCRunloopRunOnce()
{
    while (CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.001, YES) == kCFRunLoopRunHandledSource ||
           CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, YES) == kCFRunLoopRunHandledSource);
}

static inline void XLCRunloopRun(CFTimeInterval timeout)
{
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, timeout, NO);
    XLCRunloopRunOnce();
}

@interface NSObject (XLCTestUtilsMemoryDebug)

/**
 * Perform isa-swizzle to override retain / release / autorelease.
 */
- (id)xlc_swizzleRetainRelease;

/**
 * Restore isa.
 */
- (void)xlc_restoreRetainRelease;

/**
 * Count of autorelease called.
 * This is can be useful to calculate "real" retain count given no
 * autorelease pool was drain (which is the typical case when unit testing).
 */
- (NSUInteger)xlc_autoreleaseCount;

// stub methods
- (id)xlc_retain;
- (void)xlc_release;
- (id)xlc_autorelease;
- (Class)xlc_class;
- (void)xlc_dealloc;

// not swizzled, just call original retainCount
- (NSUInteger)xlc_retainCount;

@end

__END_DECLS