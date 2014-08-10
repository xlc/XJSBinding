//
//  XJSRuntimeEntry.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-29.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSRuntimeEntry.hh"

#import <objc/runtime.h>
#import <XLCUtils/XLCUtils.h>
#import "jsapi.h"
#import "XJSLogging_Private.h"

#import "XJSInternalOperation.hh"
#import "XJSClass.hh"

static JSBool XJSPropertyImpl(JSContext *cx, JS::HandleObject obj, JS::HandleId jid, JS::MutableHandleValue vp)
{
    if (XJSInternalOperation::IsInternalOepration(cx)) {
        return JS_PropertyStub(cx, obj, jid, vp);
    }
    JSAutoByteString str;
    XJSLogInfo(@"invalid add property: %s", str.encodeUtf8(cx, JSID_TO_STRING(jid)));
    return JS_FALSE;
}

static JSBool XJSDeletePropertyImpl(JSContext *cx, JS::HandleObject obj, JS::HandleId jid, JSBool *succeeded)
{
    if (XJSInternalOperation::IsInternalOepration(cx)) {
        return JS_DeletePropertyStub(cx, obj, jid, succeeded);
    }
    XJSLogInfo(@"invalid delete property: %s", JSAutoByteString().encodeUtf8(cx, JSID_TO_STRING(jid)));
    *succeeded = JS_FALSE;  // cannot delete
    return JS_TRUE; // no error
}

static JSBool XJSSetPropertyImpl(JSContext *cx, JS::HandleObject obj, JS::HandleId jid, JSBool strict, JS::MutableHandleValue vp)
{
    if (XJSInternalOperation::IsInternalOepration(cx)) {
        return JS_StrictPropertyStub(cx, obj, jid, strict, vp);
    }
    JSAutoByteString str;
    XJSLogInfo(@"invalid set property: %s", str.encodeUtf8(cx, JSID_TO_STRING(jid)));
    return JS_FALSE;
}

static JSBool XJSResolveImpl(JSContext *cx, JS::HandleObject obj, JS::HandleId jid)
{
    XJSInternalOperation op(cx);
    JSAutoByteString str;
    const char *clsname = str.encodeUtf8(cx, JSID_TO_STRING(jid));
    Class cls = objc_getClass(clsname);
    if (cls) {
        JSObject *clsobj = XJSGetOrCreateJSObject(cx, cls);
        JS::RootedValue clsval(cx, JS::ObjectOrNullValue(clsobj));
        return JS_SetProperty(cx, obj, clsname, clsval);
    }
    return JS_TRUE;
}

static JSClass XJSRuntimeEntryClass = {
    "XJSRuntimeEntry",          // name
    0,                          // flags
    XJSPropertyImpl,            // add
    XJSDeletePropertyImpl,      // delet
    JS_PropertyStub,            // get
    XJSSetPropertyImpl,         // set
    JS_EnumerateStub,           // enumerate
    XJSResolveImpl,             // resolve
    JS_ConvertStub,             // convert
    NULL,                       // finalize
};

JSObject * XJSCreateRuntimeEntry(JSContext *cx)
{
    return JS_NewObject(cx, &XJSRuntimeEntryClass, NULL, NULL);
}