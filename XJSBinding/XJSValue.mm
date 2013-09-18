//
//  XJSValue.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-7.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSValue_Private.h"

#import "jsapi.h"

#import "XLCLogging.h"
#import "NSError+XJSError.h"

#import "XJSConvert.h"
#import "XJSContext_Private.h"
#import "XJSRuntime.h"

@implementation XJSValue

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
    __block jsval val;
    [context.runtime performBlockAndWait:^{
        val = XJSConvertStringToJSValue(context.context, value);
    }];
    return [[self alloc] initWithContext:context value:val];
}

+ (XJSValue *)valueWithNullInContext:(XJSContext *)context
{
    return [[self alloc] initWithContext:context value:JS::NullValue()];
}

+ (XJSValue *)valueWithUndefinedInContext:(XJSContext *)context
{
    return [[self alloc] initWithContext:context value:JS::UndefinedValue()];
}

#pragma mark -

- (id)initWithContext:(XJSContext *)context JSObject:(JSObject *)object
{
    return [self initWithContext:context value:OBJECT_TO_JSVAL(object)];
}

- (id)initWithContext:(XJSContext *)context value:(jsval)val
{
    self = [super init];
    if (self) {
        _context = context;
        _value = val;
        
        JSAutoRequest request(_context.context);
        JS_AddValueRoot(_context.context, &_value);
        
        if (!JSVAL_IS_PRIMITIVE(_value)) {
            _object = JSVAL_TO_OBJECT(_value);
        }
    }
    return self;
}

- (void)dealloc
{
    JSAutoRequest request(_context.context);
    JS_RemoveValueRoot(_context.context, &_value);
}

#pragma mark -

- (NSString *)description
{
    return XJSConvertJSValueToSource(self.context.context, _value);
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
    if (JS_StrictlyEqual(_context.context, _value, object.value, &equal)) {
        return equal;
    }
    return NO;
}

- (BOOL)isLooselyEqualToValue:(XJSValue *)object
{
    if (object == self) return true;
    
    JSBool equal;
    if (JS_LooselyEqual(_context.context, _value, object.value, &equal)) {
        return equal;
    }
    return NO;
}

- (BOOL)isSameValue:(XJSValue *)object
{
    if (object == self) return true;
    
    JSBool equal;
    if (JS_SameValue(_context.context, _value, object.value, &equal)) {
        return equal;
    }
    return NO;
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
    if (_value.isString()) {
        return XJSConvertJSValueToString(self.context.context, _value);
    } else {
        [self reportErrorWithSelector:_cmd];
        return nil;
    }
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
    return _value.isObject();
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

@end
