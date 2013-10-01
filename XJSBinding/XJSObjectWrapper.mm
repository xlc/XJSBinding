//
//  XJSObjectWrapper.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-30.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSObjectWrapper.h"

#import "jsapi.h"

#import "XJSInternalOperation.h"

static JSBool XJSPropertyImpl(JSContext *cx, JSHandleObject obj, JSHandleId jid, JSMutableHandleValue vp)
{

    return JS_FALSE;
}

static JSBool XJSDeletePropertyImpl(JSContext *cx, JSHandleObject obj, JSHandleId jid, JSBool *succeeded)
{

    return JS_TRUE; // no error
}

static JSBool XJSSetPropertyImpl(JSContext *cx, JSHandleObject obj, JSHandleId jid, JSBool strict, JSMutableHandleValue vp)
{

    return JS_FALSE;
}

static JSBool XJSResolveImpl(JSContext *cx, JSHandleObject obj, JSHandleId jid)
{

    return JS_TRUE;
}

static JSClass XJSObjectWrapperClass = {
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

JSClass *XJSObjectWrapper = &XJSObjectWrapperClass;