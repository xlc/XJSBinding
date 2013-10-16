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
        
        // balance retain count manually since ARC don't know which selector was performed
        const char *selname = sel_getName(sel);
        if (strncmp(selname, "alloc", 5) == 0 ||
            strncmp(selname, "copy", 4) == 0 ||
            strncmp(selname, "mutableCopy", 11) == 0 ||
            strncmp(selname, "new", 3) == 0) {
            if (strcmp([signature methodReturnType], @encode(id)) == 0) {
                id obj = *(id __autoreleasing *)(void *)buff;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [obj performSelector:sel_getUid("autorelease")];
#pragma clang diagnostic pop
            }
        }
        
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
    
    JSObject *proto = NULL;
    JS_GetPrototype(cx, obj, &proto);
    if (proto != NULL) {
        JSBool hasProperty = JS_FALSE;
        JS_HasPropertyById(cx, proto, jid, &hasProperty);
        if (hasProperty) {  // we are not going to override property inherited from Object
            return JS_TRUE;
        }
    }
    
    
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
    if (vp.isPrimitive()) {
        *bp = JS_FALSE;
        return JS_TRUE;
    }
    id cls = XJSGetAssosicatedObject(obj);
    id nsobj = XJSGetAssosicatedObject(vp.toObjectOrNull());
    if (!nsobj || ! cls) {
        *bp = JS_FALSE;
        return JS_TRUE;
    }
    
    *bp = [nsobj isKindOfClass:cls];
    
    return JS_TRUE;
}

static JSBool XJSConstructor(JSContext *cx, unsigned argc, jsval *vp)
{
    auto args = JS::CallArgsFromVp(argc, vp);
    
    id cls = XJSGetAssosicatedObject(&args.callee());
    XASSERT_NOTNULL(cls);
    
    if (![cls respondsToSelector:@selector(alloc)]) {
        JS_ReportError(cx, "'%s'(%s) is not a constructor", [[cls description] UTF8String], [XJSConvertJSValueToSource(cx, args.calleev()) UTF8String]);
        return JS_FALSE;
    }
    
    id retobj = nil;
    
    try {
        @try {
            retobj = [[cls alloc] init];
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
    
    if (retobj) {
        args.rval().set(JS::ObjectOrNullValue(XJSCreateJSObject(cx, retobj)));
    } else {
        args.rval().set(JS::NullValue());
    }
    
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
    
    JSClass *jscls = (JSClass *)[jsclsdata mutableBytes];
    
    const char *clsname = class_getName(cls);
    [jsclsdata appendBytes:clsname length:strlen(clsname)];   // store name
    jscls->name = (const char *)(jscls + 1);    // end of JSClass
    
    objc_setAssociatedObject(cls, XJSClassKey, jsclsdata, OBJC_ASSOCIATION_RETAIN);
    
    return jscls;
}

JSObject *XJSCreateJSObject(JSContext *cx, id obj)
{
    JSBool success;
    
    JSClass *jscls = XJSGetJSClassForNSClass(object_getClass(obj));
    JSObject *jsobj = JS_NewObject(cx, jscls, NULL, NULL);
    
    JS_SetPrivate(jsobj, (__bridge_retained void *)obj);
    
    JSObject *proto;
    success = JS_GetPrototype(cx, jsobj, &proto);
    XASSERT(success, @"fail to get prototype object");
    
    JSObject *cstrobj = JS_GetConstructor(cx, proto);
    if (!XJSGetAssosicatedObject(cstrobj)) {    // constructor is default one
        jsval cstrval;
        if (obj == [NSObject class]) {
            cstrval = JS::ObjectOrNullValue(jsobj); // refer to self
        } else {
            const char *runtimename = [[XJSContext contextForJSContext:cx].globalNamespace UTF8String];
            jsval runtimeval;
            success = JS_GetProperty(cx, JS_GetGlobalObject(cx), runtimename, &runtimeval);
            XASSERT(success, "fail to get objc runtime entry");
            
            JSObject *runtime = &runtimeval.toObject();
            
            Class cls = object_getClass(obj);
            if (class_isMetaClass(cls))
            {
                cls = [NSObject class];
            }
            
            success = JS_GetProperty(cx, runtime, class_getName(cls), &cstrval);
            XASSERT(success, "fail to get constructor object");
        }
        
        success = JS_LinkConstructorAndPrototype(cx, cstrval.toObjectOrNull(), proto);
        XASSERT(success, "fail to link constructor and prototype");
    }
    
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