//
//  XJSValueWeakRef.mm
//  XJSBinding
//
//  Created by Xiliang Chen on 13-10-18.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSValueWeakRef.h"

#import <XLCUtils/XLCUtils.h>

#import "jsapi.h"
#import "jsfriendapi.h"

#import "NSObject+XJSValueConvert.h"
#import "XJSContext_Private.hh"
#import "XJSValue_Private.hh"

@implementation XJSValueWeakRef
{
    __weak XJSValue *_value;
    __weak XJSContext *_context;
    JSObject *_map;
}

- (id)initWithValue:(XJSValue *)value
{
    self = [super init];
    if (self) {
        self.value = value;
    }
    return self;
}

- (void)dealloc
{
    self.value = nil; // also remove rooted map
}

- (XJSValue *)value
{
    XJSValue *val = _value; // strong ref
    if (val) {
        return val;
    }
    
    if (!_map) {
        return nil;
    }
    
    XJSContext *cx = _context;
    if (!cx) {
        return nil;
    }
    
    JSObject *object;
    
    @synchronized(cx.runtime) {
        if (!JS_NondeterministicGetWeakMapKeys(cx.context, _map, &object))
            return nil;
        
        jsval outval;
        JS_GetElement(cx.context, object, 0, &outval);
        if (outval.isObject()) {
            return [[XJSValue alloc] initWithContext:cx value:outval];
        }
    }
    
    return nil;
}

- (void)setValue:(XJSValue *)value
{
    _value = value;
    
    XJSContext *oldcx = _context;
    XJSContext *cx = value.context;
    _context = cx;
    
    // remove old map
    if (oldcx && _map) {
        @synchronized(oldcx.runtime) {
            JS_RemoveObjectRoot(oldcx.context, &_map);
        }
    }
    
    // map key cannot be primitive type and no much reason to hold weak ref to primitive type
    if (!value || value.isPrimitive) {
        return;
    }
    
    // create new map
    @synchronized(cx.runtime) {
        JS::RootedValue mapval(_context.context);
        JS_GetProperty(_context.context, _context.globalObject, "WeakMap", &mapval);
        XLCAssertCritical(mapval.isObject(), "WeakMap not avaiable");
        _map = JS_New(_context.context, mapval.toObjectOrNull(), 0, NULL);
        JS_AddObjectRoot(_context.context, &_map);
        
        jsval argv[2] = { value.value, JS::ObjectOrNullValue(JS_NewObject(cx.context, NULL, NULL, NULL)) };
        jsval rval;
        JS_CallFunctionName(cx.context, _map, "set", 2, argv, &rval);
    }
}

@end

@implementation XJSValueWeakRef (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context
{
    return XJSToValue(context, self.value);
}

@end

@implementation XJSValue (XJSValueWeakRef)

- (XJSValueWeakRef *)weakReference
{
    return [[XJSValueWeakRef alloc] initWithValue:self];
}

@end