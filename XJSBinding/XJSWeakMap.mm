//
//  XJSWeakMap.mm
//  XJSBinding
//
//  Created by Xiliang Chen on 13-10-19.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSWeakMap.h"

#import "jsfriendapi.h"
#import "XLCAssertion.h"

#import "XJSValue_Private.h"
#import "XJSContext_Private.h"

@implementation XJSWeakMap
{
    XJSValue *_value;
}

- (id)initWithContext:(XJSContext *)context
{
    XASSERT_NOTNULL(context);
    self = [super init];
    if (self) {
        _context = context;
        
        JSObject *obj;
        @synchronized(_context.runtime) {
            jsval mapval;
            JS_GetProperty(_context.context, _context.globalObject, "WeakMap", &mapval);
            obj = JS_New(_context.context, mapval.toObjectOrNull(), 0, NULL);
        }
        XASSERT_NOTNULL(obj);
        _value = [[XJSValue alloc] initWithContext:_context value:JS::ObjectOrNullValue(obj)];
    }
    return self;
}

- (XJSValue *)objectForKey:(XJSValue *)key
{
    XASSERT_NOTNULL(key);
    XASSERT(!key.isPrimitive, "key must be js object");
    return [_value invokeMethod:@"get" withArguments:@[key]];
}

- (void)setObject:(XJSValue *)object forKey:(XJSValue *)key
{
    XASSERT_NOTNULL(key);
    XASSERT(!key.isPrimitive, "key must be js object");
    if (object) {
        [_value invokeMethod:@"set" withArguments:@[key, object]];
    } else {
        [self removeObjectForKey:key];
    }
}

- (void)removeObjectForKey:(XJSValue *)key
{
    XASSERT(!key.isPrimitive, "key must be js object");
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