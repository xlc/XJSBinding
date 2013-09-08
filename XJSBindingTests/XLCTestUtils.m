//
//  XLCTestUtils.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-8.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XLCTestUtils.h"

#import <mach/mach_time.h>

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
