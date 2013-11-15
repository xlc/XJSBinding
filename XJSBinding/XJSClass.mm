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
#import "XJSValueWeakRef.h"

static JSBool XJSAddPropertyImpl(JSContext *cx, JS::HandleObject obj, JS::HandleId jid, JS::MutableHandleValue vp)
{
    return JS_PropertyStub(cx, obj, jid, vp);
}

static JSBool XJSGetPropertyImpl(JSContext *cx, JS::HandleObject obj, JS::HandleId jid, JS::MutableHandleValue vp)
{
    return JS_PropertyStub(cx, obj, jid, vp);
}

static JSBool XJSDeletePropertyImpl(JSContext *cx, JS::HandleObject obj, JS::HandleId jid, JSBool *succeeded)
{
    return JS_DeletePropertyStub(cx, obj, jid, succeeded);
}

static JSBool XJSSetPropertyImpl(JSContext *cx, JS::HandleObject obj, JS::HandleId jid, JSBool strict, JS::MutableHandleValue vp)
{
    return JS_StrictPropertyStub(cx, obj, jid, strict, vp);
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
            jsval errval = XJSToValue([XJSContext contextForJSContext:cx], exception).value;
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
        JS::RootedValue retval(cx);
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

static JSBool XJSResolveImpl(JSContext *cx, JS::HandleObject obj, JS::HandleId jid)
{
    JS::RootedValue val(cx);
    JSBool success;
    
    success = JS_IdToValue(cx, jid, val.address());
    XASSERT(success, "fail to get id");
    
    if (val.isString()) {
        JS::RootedObject proto(cx);
        success = JS_GetPrototype(cx, obj, &proto);
        XASSERT(success && proto, "fail to get prototype");
        
        JSAutoByteString str(cx, JS_ValueToString(cx, val));
        const char *selname = str.ptr();
        if (strcmp(selname, "toString") == 0) {
            selname = "description";
        } else {
            JSBool hasProperty = JS_FALSE;
            JS_HasPropertyById(cx, proto, jid, &hasProperty);
            if (hasProperty) {  // we are not going to override property inherited from Object except toString
                return JS_TRUE;
            }
        }
        
        JSFunction *func = JS_NewFunction(cx, XJSCallMethod, 0, 0, NULL, selname);
        JS::RootedValue funcval(cx, JS::ObjectOrNullValue(JS_GetFunctionObject(func)));
        
        success = JS_SetProperty(cx, proto, str.ptr(), funcval);
        XASSERT(success, "fail to set property");
    }
    
    return JS_TRUE;
}

static JSBool XJSHasInstanceImpl(JSContext *cx, JS::HandleObject obj, JS::MutableHandleValue vp, JSBool *bp)
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
            jsval errval = XJSToValue([XJSContext contextForJSContext:cx], exception).value;
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
        args.rval().set(JS::ObjectOrNullValue(XJSGetOrCreateJSObject(cx, retobj)));
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
    XJSAddPropertyImpl,         // add
    XJSDeletePropertyImpl,      // delet
    XJSGetPropertyImpl,         // get
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

JSObject *XJSGetOrCreateJSObject(JSContext *cx, id obj)
{
    static const void *key = &key;
    
    // no need to lock, dict just used for cache, it is fine to lost some update
    NSMutableDictionary *dict = objc_getAssociatedObject(obj, key);
    if (!dict) {
        dict = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(obj, key, dict, OBJC_ASSOCIATION_RETAIN);
    }
    
    // per runtime
    NSValue *runtimeKey = [NSValue valueWithPointer:JS_GetRuntime(cx)];

    XJSValueWeakRef *ref;
    @synchronized(dict) {
        ref = dict[runtimeKey];
    }

    XJSValue *val = ref.value;
    if (val) {
        return val.value.toObjectOrNull();
    }
    
    JSObject *jsobj = XJSCreateJSObject(cx, obj);
    
    val = [[XJSValue alloc] initWithContext:[XJSContext contextForJSContext:cx] value:JS::ObjectOrNullValue(jsobj)];
    ref = [val weakReference];
    
    @synchronized(dict) {
        dict[runtimeKey] = ref;
    }
    
    return jsobj;
}

JSObject *XJSCreateJSObject(JSContext *cx, id obj)
{
    JSBool success;
    
    JSClass *jscls = XJSGetJSClassForNSClass(object_getClass(obj));
    JS::RootedObject jsobj(cx, JS_NewObject(cx, jscls, NULL, NULL));
    
    JS_SetPrivate(jsobj, (__bridge_retained void *)obj);
    
    JS::RootedObject proto(cx);
    success = JS_GetPrototype(cx, jsobj, &proto);
    XASSERT(success, @"fail to get prototype object");
    
    JS::RootedValue cstrval(cx);
    JS_GetProperty(cx, proto, "constructor", &cstrval); // JS_GetConstructor will report error if it cannot find a constructor, which is normal in our case
    JS::RootedObject cstrobj(cx);
    if (cstrval.isObjectOrNull()) {
        cstrobj = cstrval.toObjectOrNull();
    }
    if (!cstrobj || !XJSGetAssosicatedObject(cstrobj)) {    // constructor is default one
        
        if (obj == [NSObject class]) {
            cstrval = JS::ObjectOrNullValue(jsobj); // refer to self
        } else {
            XJSContext *context = [XJSContext contextForJSContext:cx];
            
            JSObject *runtime = context.runtimeEntryObject;
            
            Class cls = object_getClass(obj);
            if (class_isMetaClass(cls))
            {
                cls = [NSObject class];
            }
            
            success = JS_GetProperty(cx, runtime, class_getName(cls), &cstrval);
            XASSERT(success, "fail to get constructor object");
            XASSERT(cstrval.isObject(), "unable to get constructor object, class (%@) it not registered? ", cls);
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
    if (jscls->addProperty != XJSAddPropertyImpl) {    // check class type
        return nil;
    }
    
    return (__bridge id)JS_GetPrivate(jsobj);
}