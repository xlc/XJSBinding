//
//  XJSTestUtils.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-11.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#define XJSAssertEqualValue(cx, a1, a2, format...) \
({ \
    JSContext *cxvalue = (cx); \
    jsval a1value = (a1); \
    jsval a2value = (a2); \
    JSBool equal = JS_FALSE;\
    JSBool success = JS_StrictlyEqual(cxvalue, a1value, a2value, &equal);\
    if (!success || !equal) { \
        _XCTRegisterFailure(_XCTFailureDescription(_XCTAssertion_Equal, 0, @#a1, @#a2, XJSConvertJSValueToSource(cxvalue, a1value), XJSConvertJSValueToSource(cxvalue, a2value)),format); \
    } \
})