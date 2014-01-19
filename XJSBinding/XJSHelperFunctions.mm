//
//  XJSHelperFunctions.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-30.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSHelperFunctions.hh"

#import <objc/runtime.h>
#include <algorithm>

#import "XLCAssertion.h"

static SEL _XJSSearchSelector(id obj, const char *selname, unsigned argc)
{
    size_t len = strlen(selname);
    
    auto count = std::count(selname, selname+len, ':');
    
    if (count != 0) {   // already contain colon, must be complete selector name
        if (count != argc) {    // does not match
            return NULL;
        }
        return sel_getUid(selname);
    }

    if (argc == 0) {
        return sel_getUid(selname);
    }
    // argc > 0
    
    size_t maxlen = len + argc + 1;
    char cstr[maxlen];
    strncpy(cstr, selname, maxlen);
    
    bool endWithUnderscore;
    
    // must end with ':'
    if (cstr[len-1] == '_') {
        cstr[len-1] = ':';
        endWithUnderscore = true;
    } else {
        cstr[len] = ':';
        cstr[++len] = '\0';
        endWithUnderscore = false;
    }
    
    bool startCount = false;
    auto matchNonLeadingUnderscore = [&startCount](char c) {
        if (c == '_') {
            return startCount;
        }
        startCount = true;
        return false;
    };
    
    count = std::count_if(cstr+1, cstr+len, matchNonLeadingUnderscore) + 1; // count number of underscores exclude the leading oncs. plus colon just appened
    
    if (count >= argc) { // more underscores than colons
        if (count != 1) {
            // start place underscores to colon backwards
            char *ptr = cstr + len - 2; // last one is already replaced
            for (int i = 1; i < argc; ptr--) {
                if (*ptr == '_') {
                    *ptr = ':';
                    i++;
                }
            }
        }
        return sel_getUid(cstr);
    }
    // count < argc
    
    if (endWithUnderscore) { // not allow to append colon at end
        return NULL;
    }
    
    // need append colon at end
    
    // replace all underscore to colon except the leading ones
    startCount = false;
    std::replace_if(cstr+1, cstr+len, matchNonLeadingUnderscore, ':');
    
    // append colon at end of selector to match numebr of arugments
    for (int i = 0; i < argc - count; i++) {
        cstr[len++] = ':';
    }
    cstr[len] = '\0';
    
    return sel_getUid(cstr);
}

SEL XJSSearchSelector(id obj, const char *selname, unsigned argc)
{
    XASSERT_NOTNULL(obj);
    XASSERT_NOTNULL(selname);
    SEL result = _XJSSearchSelector(obj, selname, argc);
    return (result && [obj respondsToSelector:result]) ? result : NULL;
}

NSString *XJSSearchProperty(JSContext *cx, JSObject *obj, SEL sel)
{
    XASSERT_NOTNULL(obj);
    XASSERT_NOTNULL(sel);
    
    NSString *name = NSStringFromSelector(sel);
    JSBool found;
    
    if (JS_HasProperty(cx, obj, [name UTF8String], &found) && found) {
        return name;
    }
    
    name = [name stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    
    if (JS_HasProperty(cx, obj, [name UTF8String], &found) && found) {
        return name;
    }
    
    int count = 0;
    for (NSInteger i = name.length - 1; i >= 0 && [name characterAtIndex:i] == '_'; --i) {
        ++count;
    }
    
    if (count) {
        name = [name substringToIndex:name.length - count];
        
        if (JS_HasProperty(cx, obj, [name UTF8String], &found) && found) {
            return name;
        }
    }
    
    return nil;
}