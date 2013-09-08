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

__END_DECLS