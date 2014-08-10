//
//  XJSLogger.mm
//  XJSBinding
//
//  Created by Xiliang Chen on 13-12-10.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSLogger.hh"

#import <memory>
#import <functional>

#import <XLCUtils/XLCUtils.h>
#import "jsdbgapi.h"

#import "XJSConvert.hh"

static JSBool XJSLog(JSContext *cx, unsigned argc, JS::Value *vp, int level)
{
    auto args = JS::CallArgsFromVp(argc, vp);
    
    NSMutableString *str = [NSMutableString string];
    
    for (int i = 0; i < args.length(); ++i) {
        if (i != 0) {
            [str appendString:@" "];
        }
        [str appendString:XJSConvertJSValueToString(cx, args[i])];
    }
    
    auto del = std::bind(JS::FreeStackDescription, cx, std::placeholders::_1);
    std::unique_ptr<JS::StackDescription, decltype(del)> stacks(JS::DescribeStack(cx, 1), del);
    
    auto frame = stacks->frames; // & stacks->frames[0]
    auto jsfunname = frame->fun ? JS_GetFunctionDisplayId(frame->fun) : NULL;
    JSAutoByteString bytestr;
    auto funname = jsfunname ? bytestr.encodeUtf8(cx, jsfunname) : "(unknown)";
    auto filename = JS_GetScriptFilename(cx, frame->script) ?: "(unknown)";
    
    [DDLog log:NO level:XLCLogLevel flag:level context:0 file:filename function:funname line:frame->lineno tag:nil format:@"%@", str];
    
    args.rval().set(XJSConvertStringToJSValue(cx, str));
    
    return JS_TRUE;
}

static JSBool XJSLogDebug(JSContext *cx, unsigned argc, JS::Value *vp)
{
    return XJSLog(cx, argc, vp, LOG_FLAG_DEBUG);
}

static JSBool XJSLogInfo(JSContext *cx, unsigned argc, JS::Value *vp)
{
    return XJSLog(cx, argc, vp, LOG_FLAG_INFO);
}

static JSBool XJSLogWarn(JSContext *cx, unsigned argc, JS::Value *vp)
{
    return XJSLog(cx, argc, vp, LOG_FLAG_WARN);
}

static JSBool XJSLogError(JSContext *cx, unsigned argc, JS::Value *vp)
{
    return XJSLog(cx, argc, vp, LOG_FLAG_ERROR);
}

JSObject *XJSCreateLogger(JSContext *cx)
{
    JS::RootedObject obj(cx);
    
    obj.set(JS_GetFunctionObject(JS_NewFunction(cx, XJSLogInfo, 1, 0, NULL, "log")));
    
    static JSFunctionSpec methods[] = {
        JS_FS("debug", XJSLogDebug, 1, 0),
        JS_FS("info", XJSLogInfo, 1, 0),
        JS_FS("warn", XJSLogWarn, 1, 0),
        JS_FS("error", XJSLogError, 1, 0),
        JS_FS_END,
    };
    
    JS_DefineFunctions(cx, obj, methods);
    
    return obj;
}
