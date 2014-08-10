//
//  XJSWeakMap.mm
//  XJSBinding
//
//  Created by Xiliang Chen on 13-10-19.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSWeakMap.h"

#import <XLCUtils/XLCUtils.h>

#import "jsfriendapi.h"

#import "XJSValue_Private.hh"
#import "XJSContext_Private.hh"

@implementation XJSWeakMap
{
    XJSValue *_value;
}

- (id)initWithContext:(XJSContext *)context
{
    XLCAssertNotNullCritical(context);
    self = [super init];
    if (self) {
        _context = context;
        
        JSObject *obj;
        @synchronized(_context.runtime) {
            JS::RootedValue mapval(context.context);
            JS_GetProperty(_context.context, _context.globalObject, "WeakMap", &mapval);
            XLCAssertCritical(mapval.isObject(), "WeakMap not avaiable");
            obj = JS_New(_context.context, mapval.toObjectOrNull(), 0, NULL);
        }
        XLCAssertNotNullCritical(obj);
        _value = [[XJSValue alloc] initWithContext:_context value:JS::ObjectOrNullValue(obj)];
    }
    return self;
}

- (XJSValue *)objectForKey:(XJSValue *)key
{
    if (!key) {
        XLCFail("key must not be null");
        return nil;
    }
    if (key.isPrimitive) {
        XLCFail(@"key must be js object. key = %@", key);
        return nil;
    }
    return [_value invokeMethod:@"get" withArguments:@[key]];
}

- (void)setObject:(XJSValue *)object forKey:(XJSValue *)key
{
    if (!key) {
        XLCFail("key must not be null");
        return;
    }
    if (key.isPrimitive) {
        XLCFail(@"key must be js object. key = %@", key);
        return;
    }
    if (object) {
        [_value invokeMethod:@"set" withArguments:@[key, object]];
    } else {
        [self removeObjectForKey:key];
    }
}

- (void)removeObjectForKey:(XJSValue *)key
{
    if (!key) {
        XLCFail("key must not be null");
        return;
    }
    if (key.isPrimitive) {
        XLCFail(@"key must be js object. key = %@", key);
        return;
    }
    [_value invokeMethod:@"delete" withArguments:@[key]];
}

- (void)removeAllObjects
{
    [_value invokeMethod:@"clear" withArguments:nil];
}

- (XJSValue *)allKeys
{
    JSObject *object;
    
    @synchronized(_context.runtime) {
        if (!JS_NondeterministicGetWeakMapKeys(_context.context, _value.value.toObjectOrNull(), &object))
            return nil;
    }
    
    return [[XJSValue alloc] initWithContext:_context value:JS::ObjectOrNullValue(object)];
}

@end

@implementation XJSWeakMap (SubscriptSupport)

- (XJSValue *)objectForKeyedSubscript:(XJSValue *)key
{
    return [self objectForKey:key];
}

- (void)setObject:(XJSValue *)object forKeyedSubscript:(XJSValue *)key
{
    [self setObject:object forKey:key];
}

@end