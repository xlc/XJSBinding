//
//  XJSClass.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-10-2.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSClass.hh"

#include <type_traits>
#include <exception>

#import <objc/runtime.h>

#import <XLCUtils/XLCUtils.h>
#import "jsapi.h"

#import "XJSLogging_Private.h"

#import "XJSConvert.hh"
#import "XJSHelperFunctions.hh"
#import "XJSInternalOperation.hh"
#import "NSObject+XJSValueConvert.h"
#import "XJSContext_Private.hh"
#import "XJSValue_Private.hh"
#import "XJSValueWeakRef.h"
#import "XJSFunction.h"


static JSBool XJSGetPropertyImpl(JSContext *cx, JS::HandleObject obj, JS::HandleId jid, JS::MutableHandleValue vp)
{
    jsval val;
    JS_IdToValue(cx, jid, &val);
    NSString *propname = XJSConvertJSValueToString(cx, val);
    id nsobj = XJSGetAssosicatedObject(obj);
    SEL sel = XJSObjectGetPropertyGetter(nsobj, [propname UTF8String]);
    if (sel && [nsobj respondsToSelector:sel]) {
        
        NSMethodSignature *signature = [nsobj methodSignatureForSelector:sel];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:nsobj];
        [invocation setSelector:sel];
        NSUInteger retsize = [signature methodReturnLength];
        alignas(sizeof(NSInteger)) unsigned char buff[retsize];
        
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
        
        [invocation getReturnValue:buff];
        return XJSValueFromType(cx, [signature methodReturnType], buff, vp);
        
    } else {
        JS_ReportError(cx, "Unable to get property '%s' from object '%s'",
                       [propname UTF8String],
                       XJSConvertJSValueToString(cx, JS::ObjectOrNullValue(obj)));
        return JS_FALSE;
    }
}

static JSBool XJSSetPropertyImpl(JSContext *cx, JS::HandleObject obj, JS::HandleId jid, JSBool strict, JS::MutableHandleValue vp)
{
    jsval val;
    JS_IdToValue(cx, jid, &val);
    NSString *propname = XJSConvertJSValueToString(cx, val);
    id nsobj = XJSGetAssosicatedObject(obj);
    SEL sel = XJSObjectGetPropertySetter(nsobj, [propname UTF8String]);
    if (sel && [nsobj respondsToSelector:sel]) {
        
        NSMethodSignature *signature = [nsobj methodSignatureForSelector:sel];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:nsobj];
        [invocation setSelector:sel];
        const char *type = [signature getArgumentTypeAtIndex:2];
        auto ret = XJSValueToType(cx, vp, type);
        if (ret.first) { // NSValue
            NSValue *nsval = ret.first;
            NSUInteger size;
            NSGetSizeAndAlignment(type, &size, NULL);
            alignas(sizeof(NSInteger)) unsigned char buff[size];   // not sure alignas is required
            [nsval getValue:&buff];
            [invocation setArgument:buff atIndex:2];
        } else if (ret.second) {    // id
            [invocation setArgument:&ret.second atIndex:2];
        } else {
            if (type[0] == _C_ID || type[0] == _C_CLASS) {
                id nilobj = nil;
                [invocation setArgument:&nilobj atIndex:2];
            } else {
                JS_ReportError(cx, "Unable to set property '%s' to value '%s' for object '%s'",
                               [propname UTF8String],
                               XJSConvertJSValueToString(cx, vp),
                               XJSConvertJSValueToString(cx, JS::ObjectOrNullValue(obj)));
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
        
        return JS_TRUE;
        
    } else {
        JS_ReportError(cx, "Unable to set property '%s' to value '%s' for object '%s'",
                       [propname UTF8String],
                       XJSConvertJSValueToString(cx, vp),
                       XJSConvertJSValueToString(cx, JS::ObjectOrNullValue(obj)));
        return JS_FALSE;
    }
}

static JSBool XJSCallMethod(JSContext *cx, unsigned argc, JS::Value *vp)
{
    auto args = JS::CallArgsFromVp(argc, vp);
    
    JSFunction *func = JS_ValueToFunction(cx, JS::ObjectValue(args.callee()));
    JSAutoByteString str(cx, JS_GetFunctionId(func));
    const char *selname = str.ptr();
    XLCAssert(selname);
    
    auto thisobj = args.thisv().toObjectOrNull();
    id obj = thisobj ? XJSGetAssosicatedObject(thisobj) : nil;
    if (!obj) {
        XJSLogInfo(@"Unable to call selector %s on %@. undefine returned.", selname, XJSConvertJSValueToSource(cx, args.thisv()));
        args.rval().set(JS::UndefinedValue());
        return JS_TRUE;
    }
    
    SEL sel = XJSSearchSelector(obj, selname, args.length());
    if (sel == NULL) {
        if (args.length() == 0 && strcmp(selname, "toString") == 0) {
            sel = @selector(description);
        } else {
            JS_ReportError(cx, "Unable to find selector '%s' on object '%s' of class '%s'",
                           selname,
                           [[obj description] UTF8String],
                           class_getName([obj class])
                           );
            return JS_FALSE;
        }
    }
    
    NSMethodSignature *signature = [obj methodSignatureForSelector:sel];
    XLCAssert(signature);
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
            if (type[0] == _C_ID || type[0] == _C_CLASS) {
                id nilobj = nil;
                [invocation setArgument:&nilobj atIndex:i+2];
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
            XJSLogWarn(@"Method %c[%s %s] invoked successful but unable to convert returned value (%s) to jsval.",
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
    XLCAssert(success, "fail to get id");
    
    if (val.isString()) {
        JS::RootedObject proto(cx);
        success = JS_GetPrototype(cx, obj, &proto);
        XLCAssert(success && proto, "fail to get prototype");
        
        JSAutoByteString str(cx, JS_ValueToString(cx, val));
        const char *selname = str.ptr();
        
        JSBool hasProperty = JS_FALSE;
        JS_HasPropertyById(cx, proto, jid, &hasProperty);
        if (hasProperty) {
            return JS_TRUE;
        }
        
        XJSContext *context = [XJSContext contextForJSContext:cx];
        if (!context.treatePropertyAsMethod) {
            id nsobj = XJSGetAssosicatedObject(obj);
            if (XJSObjectHasProperty(nsobj, selname)) {
                
                BOOL isReadonly = !XJSObjectGetPropertySetter(nsobj, selname);
                unsigned flags = JSPROP_ENUMERATE | JSPROP_PERMANENT | JSPROP_SHARED;
                if (isReadonly) {
                    flags |= JSPROP_READONLY;
                }
                JS_DefineProperty(cx, obj, selname, JS::UndefinedValue(), XJSGetPropertyImpl, XJSSetPropertyImpl, flags);
                
                return YES;
            }
        }
        
        JSFunction *func = JS_NewFunction(cx, XJSCallMethod, 0, 0, NULL, selname);
        JS::RootedValue funcval(cx, JS::ObjectOrNullValue(JS_GetFunctionObject(func)));
        
        success = JS_SetProperty(cx, proto, selname, funcval);
        XLCAssert(success, "fail to set property");
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
    XLCAssertNotNull(cls);
    
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

static JSBool XJSCallImpl(JSContext *cx, unsigned argc, JS::Value *vp)
{
    auto args = JS::CallArgsFromVp(argc, vp);
    auto thisobj = args.calleev();
    
    id<XJSCallable> obj = XJSGetAssosicatedObject(thisobj.toObjectOrNull());
    
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:args.length()];
    XJSContext *xjscx = [XJSContext contextForJSContext:cx];
    for (int i = 0; i < args.length(); ++i) {
        [arr addObject:[[XJSValue alloc] initWithContext:xjscx value:args.get(i)]];
    }
    
    id ret = nil;
    
    try {
        @try {
            ret = [obj callWithArguments:arr];
        }
        @catch (id exception) { // objc exception
            jsval errval = XJSToValue(xjscx, exception).value;
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
    
    args.rval().set(XJSToValue(xjscx, ret).value);
    
    return JS_TRUE;
}


static JSClass XJSClassTemplate = {
    "XJSClassTemplate",         // name
    JSCLASS_HAS_PRIVATE,        // flags
    JS_PropertyStub,            // add
    JS_DeletePropertyStub,      // delet
    JS_PropertyStub,            // get
    JS_StrictPropertyStub,      // set
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
    
    if ([cls conformsToProtocol:@protocol(XJSCallable)]) {
        jscls->call = XJSCallImpl;
    }
    
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
    
    // create object
    JSClass *jscls = XJSGetJSClassForNSClass(object_getClass(obj));
    JS::RootedObject jsobj(cx, JS_NewObject(cx, jscls, NULL, NULL));
    
    JS_SetPrivate(jsobj, (__bridge_retained void *)obj);
    
    // get constructor
    JS::RootedValue cstrval(cx);
    if (obj == [NSObject class]) {
        cstrval = JS::ObjectOrNullValue(jsobj); // refer to self
    } else {
        XJSContext *context = [XJSContext contextForJSContext:cx];
        
        JSObject *runtime = context.runtimeEntryObject;
        if (!runtime) {
            XLCFail("Failed to get runtime entry object. Did you forget to call -[XJSContext createObjCRuntimeWithNamespace:]? context = %@", context);
            return NULL;
        }
        
        Class cls = object_getClass(obj);
        if (class_isMetaClass(cls))
        {
            cls = [NSObject class];
        }
        
        success = JS_GetProperty(cx, runtime, class_getName(cls), &cstrval);
        if (!success) {
            XLCFail("fail to get constructor object");
            return NULL;
        }
        if (!cstrval.isObject()) {
            XLCFail("unable to get constructor object, class (%@) it not registered? ", cls);
            return NULL;
        }
    }
    
    // get or create prototype
    JS::RootedObject proto(cx);
    JS::RootedValue protoval(cx);

    JSBool hasproto;
    success = JS_AlreadyHasOwnProperty(cx, cstrval.toObjectOrNull(), "prototype", &hasproto);
    XLCAssert(success, "fail to call JS_AlreadyHasOwnProperty");
    
    if (hasproto) {
        JS_GetProperty(cx, cstrval.toObjectOrNull(), "prototype", &protoval);
        proto = protoval.toObjectOrNull();
    } else {
        proto = JS_NewObject(cx, NULL, NULL, NULL);
        
        success = JS_LinkConstructorAndPrototype(cx, cstrval.toObjectOrNull(), proto);
        XLCAssert(success, "fail to link constructor and prototype");
        
        // override toString
        JSFunction *func = JS_NewFunction(cx, XJSCallMethod, 0, 0, NULL, "toString");
        JS::RootedValue funcval(cx, JS::ObjectOrNullValue(JS_GetFunctionObject(func)));
        success = JS_SetProperty(cx, proto, "toString", funcval);
        XLCAssert(success, "fail to set toString");
    }
    
    JS_SetPrototype(cx, jsobj, proto);
    
    return jsobj;
}

id XJSGetAssosicatedObject(JSObject *jsobj)
{
    if (!jsobj) {
        XLCFail("Invalid argument. jsobj is null");
        return nil;
    }
    JSClass *jscls = JS_GetClass(jsobj);
    if (jscls->resolve != XJSResolveImpl) {    // check class type
        return nil;
    }
    
    return (__bridge id)JS_GetPrivate(jsobj);
}