//
//  XJSClass.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-10-2.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSClass.h"

#import <objc/runtime.h>

#import "jsapi.h"
#import "XLCAssertion.h"

#import "XJSConvert.h"

#import "XJSInternalOperation.h"

static JSBool XJSPropertyImpl(JSContext *cx, JSHandleObject obj, JSHandleId jid, JSMutableHandleValue vp)
{
    
    return JS_TRUE;
}

static JSBool XJSDeletePropertyImpl(JSContext *cx, JSHandleObject obj, JSHandleId jid, JSBool *succeeded)
{
    
    return JS_TRUE; // no error
}

static JSBool XJSSetPropertyImpl(JSContext *cx, JSHandleObject obj, JSHandleId jid, JSBool strict, JSMutableHandleValue vp)
{
    
    return JS_TRUE;
}

static JSBool XJSResolveImpl(JSContext *cx, JSHandleObject obj, JSHandleId jid)
{
    
    return JS_TRUE;
}

static JSBool XJSHasInstanceImpl(JSContext *cx, JSHandleObject obj, JSMutableHandleValue vp, JSBool *bp)
{

    
    return JS_TRUE;
}

static JSBool XJSConstructor(JSContext *cx, unsigned argc, jsval *vp)
{

    return JS_TRUE;
}

static void XJSFinalizeImpl(JSFreeOp *fop, JSObject *jsobj)
{
    id obj = (__bridge_transfer id)JS_GetPrivate(jsobj);    // release it
    JS_SetPrivate(jsobj, NULL);
    (void)obj;  // use it
}

static JSClass XJSClassTemplate = {
    "XJSClassTemplate",         // name
    JSCLASS_HAS_PRIVATE,        // flags
    XJSPropertyImpl,            // add
    XJSDeletePropertyImpl,      // delet
    JS_PropertyStub,            // get
    XJSSetPropertyImpl,         // set
    JS_EnumerateStub,           // enumerate
    XJSResolveImpl,             // resolve
    JS_ConvertStub,             // convert
    XJSFinalizeImpl,            // finalize
    NULL,                       // checkAccess
    NULL,                       // call
    XJSHasInstanceImpl,         // hasInstance
    XJSConstructor,             // construct
    NULL,                       // trace
    JSCLASS_NO_INTERNAL_MEMBERS
};

static void *XJSClassKey = &XJSClassKey;

static JSClass *XJSGetJSClassForNSClass(Class cls)
{
    NSMutableData *jsclsdata;
    
    jsclsdata = objc_getAssociatedObject(cls, XJSClassKey);
    
    if (jsclsdata) {
        return (JSClass *)[jsclsdata mutableBytes];
    }
    
    jsclsdata = [NSMutableData dataWithBytes:&XJSClassTemplate length:sizeof(XJSClassTemplate)];
    
    objc_setAssociatedObject(cls, XJSClassKey, jsclsdata, OBJC_ASSOCIATION_RETAIN);
    
    JSClass *jscls = (JSClass *)[jsclsdata mutableBytes];
    
    const char *clsname = class_getName(cls);
    [jsclsdata appendBytes:clsname length:strlen(clsname)];   // store name
    jscls->name = (const char *)(jscls + 1);    // end of JSClass
    
    return jscls;
}

JSObject *XJSCreateJSObject(JSContext *cx, id obj)
{
    JSClass *jscls = XJSGetJSClassForNSClass(object_getClass(obj));
    JSObject *jsobj = JS_NewObject(cx, jscls, NULL, NULL);
    
    JS_SetPrivate(jsobj, (__bridge_retained void *)obj);
    
    return jsobj;
}

id XJSGetAssosicatedObject(JSObject *jsobj)
{
    JSClass *jscls = JS_GetClass(jsobj);
    if (jscls->addProperty != XJSPropertyImpl) {    // check class type
        return nil;
    }
    
    return (__bridge id)JS_GetPrivate(jsobj);
}