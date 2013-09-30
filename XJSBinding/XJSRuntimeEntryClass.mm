//
//  XJSRuntimeEntryClass.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-29.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSRuntimeEntryClass.h"

#import <objc/runtime.h>
#import "jsapi.h"
#import "XLCAssertion.h"

#import "XJSInternalOperation.h"

static JSBool XJSPropertyImpl(JSContext *cx, JSHandleObject obj, JSHandleId jid, JSMutableHandleValue vp) {
    if (XJSInternalOperation::IsInternalOepration(cx)) {
        return JS_PropertyStub(cx, obj, jid, vp);
    }
    JSAutoByteString str;
    XLCILOG(@"invalid add property: %s", str.encodeUtf8(cx, JSID_TO_STRING(jid)));
    return JS_FALSE;
}

static JSBool XJSDeletePropertyImpl(JSContext *cx, JSHandleObject obj, JSHandleId jid, JSBool *succeeded)
{
    if (XJSInternalOperation::IsInternalOepration(cx)) {
        return JS_DeletePropertyStub(cx, obj, jid, succeeded);
    }
    XLCILOG(@"invalid delete property: %s", JSAutoByteString().encodeUtf8(cx, JSID_TO_STRING(jid)));
    *succeeded = JS_FALSE;  // cannot delete
    return JS_TRUE; // no error
}

static JSBool XJSSetPropertyImpl(JSContext *cx, JSHandleObject obj, JSHandleId jid, JSBool strict, JSMutableHandleValue vp)
{
    if (XJSInternalOperation::IsInternalOepration(cx)) {
        return JS_StrictPropertyStub(cx, obj, jid, strict, vp);
    }
    JSAutoByteString str;
    XLCILOG(@"invalid set property: %s", str.encodeUtf8(cx, JSID_TO_STRING(jid)));
    return JS_FALSE;
}

static JSBool XJSResolveImpl(JSContext *cx, JSHandleObject obj, JSHandleId jid)
{
    XJSInternalOperation op(cx);
    JSAutoByteString str;
    const char *clsname = str.encodeUtf8(cx, JSID_TO_STRING(jid));
    Class cls = objc_getClass(clsname);
    if (cls) {
#warning TODO create JSClass and constructor
        
        JSObject *clsobj = JS_NewObject(cx, NULL, NULL, NULL);
        jsval clsval = JS::ObjectOrNullValue(clsobj);
        return JS_SetProperty(cx, obj, clsname, &clsval);
    }
    return JS_TRUE;
}

static JSClass _XJSRuntimeEntryClass = {
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
    JSCLASS_NO_OPTIONAL_MEMBERS
};

JSClass *XJSRuntimeEntryClass = &_XJSRuntimeEntryClass;