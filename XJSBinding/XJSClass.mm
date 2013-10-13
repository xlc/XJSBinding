//
//  XJSClass.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-10-2.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSClass.h"

#include <type_traits>
#include <exception>

#import <objc/runtime.h>

#import "jsapi.h"
#import "XLCAssertion.h"

#import "XJSConvert.h"
#import "XJSHelperFunctions.h"
#import "XJSInternalOperation.h"
#import "NSObject+XJSValueConvert.h"
#import "XJSContext_Private.h"
#import "XJSValue_Private.h"

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

static JSBool XJSCallMethod(JSContext *cx, unsigned argc, JS::Value *vp)
{
    auto args = JS::CallArgsFromVp(argc, vp);
    
    JSFunction *func = JS_ValueToFunction(cx, JS::ObjectValue(args.callee()));
    JSAutoByteString str(cx, JS_GetFunctionId(func));
    const char *selname = str.ptr();
    XASSERT_NOTNULL(selname);
    
    auto thisobj = args.thisv();
    id obj = XJSGetAssosicatedObject(thisobj.toObjectOrNull());
    
    SEL sel = XJSSearchSelector(obj, selname, args.length());
    if (sel == NULL) {
        JS_ReportError(cx, "Unable to find selector '%s' on object '%s' of class '%s'",
                       selname,
                       [[obj description] UTF8String],
                       class_getName([obj class])
                       );
        return JS_FALSE;
    }
    
    NSMethodSignature *signature = [obj methodSignatureForSelector:sel];
    XASSERT_NOTNULL(signature);
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:obj];
    [invocation setSelector:sel];
    
    // set arguments
    for (int i = 0; i < args.length(); i++) {
        const char *type = [signature getArgumentTypeAtIndex:i+2];
        auto ret = XJSValueToType(cx, args.get(i), type);
        if (ret.first) { // NSValue
            NSValue *nsval = ret.first;
            NSUInteger size;
            NSGetSizeAndAlignment(type, &size, NULL);
            alignas(sizeof(NSInteger)) unsigned char buff[size];   // not sure alignas is required
            [nsval getValue:&buff];
            [invocation setArgument:buff atIndex:i+2];
        } else if (ret.second) {    // id
            [invocation setArgument:&ret.second atIndex:i+2];
        } else {
            JS_ReportError(cx, "Invalid argument. Method %c[%s %s] argument no. %d expected type %s get %s",
                           [obj class] == obj ? '+' : '-',
                           class_getName([obj class]),
                           sel_getName(sel),
                           i,
                           type,
                           [XJSConvertJSValueToSource(cx, args.get(i)) UTF8String]
                           );
            return JS_FALSE;
        }
    }

    try {
        @try {
            [invocation invoke];
        }
        @catch (id exception) { // objc exception
            jsval errval = [exception xjs_toValueInContext:[XJSContext contextForJSContext:cx]].value;
            JS_SetPendingException(cx, errval);
            return JS_FALSE;
        }
    } catch (std::exception &e) {   // c++ exception
        JS_ReportError(cx, e.what());
        return JS_FALSE;
    } catch (...) { // some random exception
        JS_ReportError(cx, "Unknown exception");
        return JS_FALSE;
    }
    
    NSUInteger retsize = [signature methodReturnLength];
    if (retsize > 0) {
        alignas(sizeof(NSInteger)) unsigned char buff[retsize];    // not sure alignas is required
        [invocation getReturnValue:buff];
        jsval retval;
        JSBool success = XJSValueFromType(cx, [signature methodReturnType], buff, &retval);
        if (!success) {
            retval = JS::UndefinedValue();
            XELOG(@"Method %c[%s %s] invoked successful but unable to convert returned value (%s) to jsval.",
                  [obj class] == obj ? '+' : '-',
                  class_getName([obj class]),
                  sel_getName(sel),
                  [signature methodReturnType]
                  );
        }
        // TODO autorelease if selector return with +1 retain count?? i.e. init, new, alloc, copy, mutableCopy
        
        args.rval().set(retval);
    } else {
        args.rval().set(JS::UndefinedValue());
    }
    return JS_TRUE;
}

static JSBool XJSResolveImpl(JSContext *cx, JSHandleObject obj, JSHandleId jid)
{
    jsval val;
    if (!JS_IdToValue(cx, jid, &val)) return JS_FALSE;
    
    if (val.isString()) {
        JSAutoByteString str(cx, JS_ValueToString(cx, val));
        const char *selname = str.ptr();
        if (strcmp(selname, "toString") == 0) {
            selname = "description";
        }
        JSFunction *func = JS_NewFunction(cx, XJSCallMethod, 0, 0, NULL, selname);
        jsval funcval = JS::ObjectOrNullValue(JS_GetFunctionObject(func));
        // TODO set it on prototype so it is shared by all instance
        if (!JS_SetProperty(cx, obj, str.ptr(), &funcval)) return JS_FALSE;
    }
    
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
    XASSERT_NOTNULL(jsobj);
    JSClass *jscls = JS_GetClass(jsobj);
    if (jscls->addProperty != XJSPropertyImpl) {    // check class type
        return nil;
    }
    
    return (__bridge id)JS_GetPrivate(jsobj);
}