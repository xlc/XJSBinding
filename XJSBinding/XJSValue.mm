//
//  XJSValue.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-7.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSValue_Private.h"

#import "jsapi.h"

#import "XLCAssertion.h"
#import "NSError+XJSError.h"
#import "NSObject+XJSValueConvert.h"

#import "XJSConvert.h"
#import "XJSContext_Private.h"
#import "XJSRuntime.h"
#import "XJSClass.h"

@implementation XJSValue

+ (XJSValue *)valueWithObject:(id)value inContext:(XJSContext *)context
{
    if (!value) {
        return [self valueWithNullInContext:context];
    }
    
    @synchronized(context.runtime) {
        JSObject *obj = XJSGetOrCreateJSObject(context.context, value);
        return [[self alloc] initWithContext:context value:JS::ObjectOrNullValue(obj)];
    }
}

+ (XJSValue *)valueWithArray:(NSArray *)value inContext:(XJSContext *)context
{
    if (!value) {
        return [self valueWithNullInContext:context];
    }
    
    @synchronized(context.runtime) {
        jsval valarr[value.count];
        int i = 0;
        for (id obj in value) {
            valarr[i++] = XJSToValue(context, obj).value;
        }
        
        JSObject *jsarr = JS_NewArrayObject(context.context, (int)value.count, valarr);
        return [[self alloc] initWithContext:context value:JS::ObjectOrNullValue(jsarr)];
    }
}

+ (XJSValue *)valueWithBool:(BOOL)value inContext:(XJSContext *)context
{
    return [[self alloc] initWithContext:context value:JS::BooleanValue(value)];
}

+ (XJSValue *)valueWithDouble:(double)value inContext:(XJSContext *)context
{
    return [[self alloc] initWithContext:context value:JS::DoubleValue(value)];
}

+(XJSValue *)valueWithInt32:(int32_t)value inContext:(XJSContext *)context
{
    return [[self alloc] initWithContext:context value:JS::Int32Value(value)];
}

+ (XJSValue *)valueWithString:(NSString *)value inContext:(XJSContext *)context
{
    @synchronized(context.runtime) {
        jsval val = XJSConvertStringToJSValue(context.context, value);
        return [[self alloc] initWithContext:context value:val];
    }
}

+ (XJSValue *)valueWithDate:(NSDate *)date inContext:(XJSContext *)context
{
    @synchronized(context.runtime) {
        JSObject *obj = JS_NewDateObjectMsec(context.context, date.timeIntervalSince1970);
        return [[self alloc] initWithContext:context value:JS::ObjectOrNullValue(obj)];
    }
}

+ (XJSValue *)valueWithNewObjectInContext:(XJSContext *)context
{
    @synchronized(context.runtime) {
        JSObject *obj = JS_NewObject(context.context, NULL, NULL, NULL);
        return [[self alloc] initWithContext:context value:JS::ObjectOrNullValue(obj)];
    }
}

+ (XJSValue *)valueWithNewArrayInContext:(XJSContext *)context
{
    @synchronized(context.runtime) {
        JSObject *obj = JS_NewArrayObject(context.context, 0, NULL);
        return [[self alloc] initWithContext:context value:JS::ObjectOrNullValue(obj)];
    }
}

+ (XJSValue *)valueWithNullInContext:(XJSContext *)context
{
    return [[self alloc] initWithContext:context value:JS::NullValue()];
}

+ (XJSValue *)valueWithUndefinedInContext:(XJSContext *)context
{
    return [[self alloc] initWithContext:context value:JS::UndefinedValue()];
}

+ (XJSValue *)valueWithNSValue:(NSValue *)value inContext:(XJSContext *)context
{
    const char *encode = value.objCType;
    NSUInteger size;
    NSGetSizeAndAlignment(encode, &size, NULL);
    alignas(NSUInteger) char buff[size];
    [value getValue:buff];
    @synchronized(context.runtime) {
        jsval val;
        if (XJSValueFromType(context.context, encode, buff, &val))
        {
            return [[XJSValue alloc] initWithContext:context value:val];
        }
        return nil;
    }
}

#pragma mark -

- (id)initWithContext:(XJSContext *)context value:(jsval)val
{
    XASSERT_NOTNULL(context);
    
    self = [super init];
    if (self) {
        _context = context;
        _value = val;
        
        @synchronized(_context.runtime) {
            JS_AddValueRoot(_context.context, &_value);
        }
    }
    return self;
}

- (void)dealloc
{
    @synchronized(_context.runtime) {
        JS_RemoveValueRoot(_context.context, &_value);
    }
}

#pragma mark -

- (NSString *)description
{
    @synchronized(_context.runtime) {
        return XJSConvertJSValueToSource(_context.context, _value);
    }
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p; context = %@; value = %@>", [self class], self, self.context, [self description]];
}

- (BOOL)isEqual:(id)object
{
    if (object == self) return true;
    
    if ([object isKindOfClass:[XJSValue class]]) {
        return [self isLooselyEqualToValue:object];
    }
    return NO;
}

- (BOOL)isStrictlyEqualToValue:(XJSValue *)object
{
    if (object == self) return true;
    
    JSBool equal;
    JSBool success;
    @synchronized(_context.runtime) {
        success = JS_StrictlyEqual(_context.context, _value, object.value, &equal);
    }
    return success && equal;
}

- (BOOL)isLooselyEqualToValue:(XJSValue *)object
{
    if (object == self) return true;
    
    JSBool equal;
    JSBool success;
    @synchronized(_context.runtime) {
        success = JS_LooselyEqual(_context.context, _value, object.value, &equal);
    }
    return success && equal;
}

- (BOOL)isSameValue:(XJSValue *)object
{
    if (object == self) return true;
    
    JSBool equal;
    JSBool success;
    @synchronized(_context.runtime) {
        success = JS_SameValue(_context.context, _value, object.value, &equal);
    }
    return success && equal;
}

#pragma mark -

- (void)reportErrorWithSelector:(SEL)sel
{
    NSString *message = [NSString stringWithFormat:@"Invalid selector (-[XJSValue %@]) called on value (%@)", NSStringFromSelector(sel),  self];
    NSError *error = [NSError errorWithXJSDomainAndUserInfo:@{XJSErrorMessageKey: message}];
    XILOG(@"%@", message);
    [self.context addError:error];
}

#pragma mark -

#define TO_PRIMITIVE_METHOD_IMPL2(type, objcmethod, convertmethod) \
- (type)objcmethod \
{ \
    type ret = 0; \
    if (!convertmethod) \
    { \
        [self reportErrorWithSelector:_cmd]; \
    } \
    return ret; \
}

#define TO_PRIMITIVE_METHOD_IMPL(type, objcmethod, jsmethod) TO_PRIMITIVE_METHOD_IMPL2(type, objcmethod, JS::jsmethod(self.context.context, _value, &ret))

TO_PRIMITIVE_METHOD_IMPL(int32_t, toInt32, ToInt32)
TO_PRIMITIVE_METHOD_IMPL(uint32_t, toUInt32, ToUint32)
TO_PRIMITIVE_METHOD_IMPL(int64_t, toInt64, ToInt64)
TO_PRIMITIVE_METHOD_IMPL(uint64_t, toUInt64, ToUint64)
TO_PRIMITIVE_METHOD_IMPL(double, toDouble, ToNumber)
TO_PRIMITIVE_METHOD_IMPL2(BOOL, toBool, (ret = JS::ToBoolean(_value), true))

- (NSString *)toString
{
    @synchronized(_context.runtime) {
        return XJSConvertJSValueToString(_context.context, _value);
    }
}

- (NSDate *)toDate
{
    if (self.isDate) {
        jsval val;
        JSBool success;
        @synchronized(_context.runtime) {
            success = JS_CallFunctionName(_context.context, _value.toObjectOrNull(), "getTime", 0, NULL, &val);
        }
        if (success) {
            XASSERT(val.isNumber(), @"date.getTime() did not return a number");
            return [NSDate dateWithTimeIntervalSince1970:val.toNumber()];
        }
    }
    return nil;
}

- (NSArray *)toArray
{
    if (_value.isPrimitive()) {
        return nil;
    }
    
    JSObject *object = _value.toObjectOrNull();
    
    @synchronized(_context.runtime) {
        uint32_t len;
        JSBool hasLength;
        if (!JS_HasProperty(_context.context, object, "length", &hasLength) || !hasLength) return nil;
        if (!JS_GetArrayLength(_context.context, object, &len)) return nil;
        
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:len];
        
        for (uint32_t i = 0; i < len; i++) {
            jsval val;
            id obj;
            if (JS_GetElement(_context.context, object, i, &val)) {
                obj = [[XJSValue alloc] initWithContext:_context value:val].toObject;
            }
            [arr addObject:obj ?: [NSNull null]];
        }
        return arr;
    }
}

- (id)toObject
{
    switch (JS_TypeOfValue(_context.context, _value)) {
        case JSTYPE_LIMIT:  // this is not valid type but need it to make compiler happy
            
        case JSTYPE_VOID:
        case JSTYPE_NULL:
            return nil;
        case JSTYPE_BOOLEAN:
            return @(self.toBool);
        case JSTYPE_NUMBER:
            if (self.isInt32) {
                return @(self.toInt32);
            }
            return @(self.toDouble);
        case JSTYPE_STRING:
            return self.toString;
        case JSTYPE_OBJECT:
        {
            JSObject *jsobj = _value.toObjectOrNull();
            if (!jsobj) {
                return nil;
            }
            id obj = XJSGetAssosicatedObject(_value.toObjectOrNull());
            if (obj) {
                return obj;
            }
            
            if (self.isDate) {
                return self.toDate;
            }
            
            if (self.isArray) {
                return self.toArray;
            }
            
            // TODO normal object to NSDictionary,
            
            return nil;
        }
        case JSTYPE_FUNCTION:
            // TODO XJSBlock?
            return nil;
    }
}

- (NSValue *)toValueOfType:(const char *)type
{
    return XJSValueToType(_context.context, _value, type).first;
}

#pragma mark -

- (BOOL)isUndefined
{
    return _value.isUndefined();
}

- (BOOL)isNull
{
    return _value.isNull();
}

- (BOOL)isBoolean
{
    return _value.isBoolean();
}

- (BOOL)isNumber
{
    return _value.isNumber();
}

- (BOOL)isString
{
    return _value.isString();
}

- (BOOL)isObject
{
    if (_value.isPrimitive()) {
        return NO;
    }
    JSObject *jsobj = _value.toObjectOrNull();
    return XJSGetAssosicatedObject(jsobj) != nil;
}

- (BOOL)isNullOrUndefined
{
    return _value.isNullOrUndefined();
}

- (BOOL)isInt32
{
    return _value.isInt32();
}

- (BOOL)isDouble
{
    return _value.isDouble();
}

- (BOOL)isPrimitive
{
    return _value.isPrimitive();
}

- (BOOL)isDate
{
    if (_value.isPrimitive()) {
        return NO;
    }
    @synchronized(_context.runtime) {
        return JS_ObjectIsDate(_context.context, _value.toObjectOrNull());
    }
}

- (BOOL)isCallable
{
    if (_value.isPrimitive()) {
        return NO;
    }
    @synchronized(_context.runtime) {
        return JS_ObjectIsCallable(_context.context, _value.toObjectOrNull());
    }
}

- (BOOL)isArray
{
    if (_value.isPrimitive()) {
        return NO;
    }
    @synchronized(_context.runtime) {
        return JS_IsArrayObject(_context.context, _value.toObjectOrNull());
    }
}

- (BOOL)isInstanceOf:(XJSValue *)value
{
    if (value.value.isPrimitive()) {
        return NO;
    }
    JSBool success;
    JSBool result;
    @synchronized(_context.runtime) {
        success = JS_HasInstance(_context.context, value.value.toObjectOrNull(), _value, &result);
    }
    return success && result;
}

#pragma mark - invoke function

- (XJSValue *)callWithArguments:(NSArray *)arguments
{   
    jsval args[arguments.count];
    
    for (int i = 0; i < arguments.count; i++) {
        // the temporary XJSValue is autoreleased so jsval will be rooted before method returned
        args[i] = XJSToValue(_context, arguments[i]).value;
    }
    
    jsval outval;
    JSBool success;
    @synchronized(_context.runtime) {
        success = JS_CallFunctionValue(_context.context, NULL, _value, (unsigned)arguments.count, args, &outval);
    }
    if (success) {
        return [[XJSValue alloc] initWithContext:_context value:outval];
    }
    return nil;
}

- (XJSValue *)constructWithArguments:(NSArray *)arguments
{
    if (_value.isPrimitive()) {
        return NO;
    }
    
    jsval args[arguments.count];
    
    for (int i = 0; i < arguments.count; i++) {
        // the temporary XJSValue is autoreleased so jsval will be rooted before method returned
        args[i] = XJSToValue(_context, arguments[i]).value;
    }
    
    JSObject *obj;
    @synchronized(_context.runtime) {
        obj = JS_New(_context.context, _value.toObjectOrNull(), (unsigned)arguments.count, args);
    }
    if (obj) {
        return [[XJSValue alloc] initWithContext:_context value:JS::ObjectOrNullValue(obj)];
    }
    return nil;
}

- (XJSValue *)invokeMethod:(NSString *)method withArguments:(NSArray *)arguments
{
    if (_value.isPrimitive()) {
        return NO;
    }
    
    jsval args[arguments.count];
    
    for (int i = 0; i < arguments.count; i++) {
        // the temporary XJSValue is autoreleased so jsval will be rooted before method returned
        args[i] = XJSToValue(_context, arguments[i]).value;
    }
    
    jsval outval;
    JSBool success;
    
    @synchronized(_context.runtime) {
        success = JS_CallFunctionName(_context.context, _value.toObjectOrNull(), [method UTF8String], (unsigned)arguments.count, args, &outval);
    }
    
    if (success) {
        return [[XJSValue alloc] initWithContext:_context value:outval];
    }
    
    return nil;
}

@end

#pragma mark - SubscriptSupport

@implementation XJSValue (SubscriptSupport)

- (XJSValue *)objectForKeyedSubscript:(id)key
{
    if (_value.isPrimitive()) {
        return nil;
    }
    
    NSString *stringKey;
    if ([key respondsToSelector:@selector(toString)]) {
        stringKey = [key toString];
    } else {
        stringKey = [key description];
    }
    
    jsval outval;
    
    @synchronized(_context.runtime) {
        if (JS_GetProperty(_context.context, _value.toObjectOrNull(), [stringKey UTF8String], &outval)) {
            return [[XJSValue alloc] initWithContext:_context value:outval];
        }
    }
    
    return nil;
}

- (XJSValue *)objectAtIndexedSubscript:(uint32_t)index
{
    if (_value.isPrimitive()) {
        return nil;
    }
    
    jsval outval;
    
    @synchronized(_context.runtime) {
        if (JS_GetElement(_context.context, _value.toObjectOrNull(), index, &outval)) {
            return [[XJSValue alloc] initWithContext:_context value:outval];
        }
    }
    
    return nil;
}

- (void)setObject:(id)object forKeyedSubscript:(id)key
{
    if (_value.isPrimitive()) {
        return;
    }
    
    NSString *stringKey;
    if ([key respondsToSelector:@selector(toString)]) {
        stringKey = [key toString];
    } else {
        stringKey = [key description];
    }
    
    jsval inval = XJSToValue(_context, object).value;
    
    @synchronized(_context.runtime) {
        JS_SetProperty(_context.context, _value.toObjectOrNull(), [stringKey UTF8String], &inval);
    }
}

- (void)setObject:(id)object atIndexedSubscript:(uint32_t)index
{
    if (_value.isPrimitive()) {
        return;
    }
    
    jsval inval = XJSToValue(_context, object).value;
    
    @synchronized(_context.runtime) {
        JS_SetElement(_context.context, _value.toObjectOrNull(), index, &inval);
    }
}

@end
