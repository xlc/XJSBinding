//
//  XJSAdopter.m
//  XJSBinding
//
//  Created by Xiliang Chen on 14-1-6.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import "XJSAdopter.h"

#import <objc/runtime.h>
#import <XLCUtils/XLCUtils.h>

#import "XJSValue_Private.hh"
#import "XJSContext_Private.hh"
#import "XJSHelperFunctions.hh"
#import "XJSConvert.hh"

static void forwardInvocationImpl(id self, XJSValue *value, NSInvocation *invocation)
{
    SEL sel = [invocation selector];
    
    JSContext *cx = value.context.context;
    
    NSString *prop = XJSSearchProperty(cx, value.value.toObjectOrNull(), sel);
    
    if (prop) {
        
        NSMutableArray *args = [NSMutableArray array];
        
        NSMethodSignature *signature = [invocation methodSignature];
        
        // skip self and _cmd
        for (int i = 2; i < [signature numberOfArguments]; ++i) {
            const char *type = [signature getArgumentTypeAtIndex:i];
            NSUInteger size;
            NSGetSizeAndAlignment(type, &size, NULL);
            alignas(sizeof(NSInteger)) unsigned char buff[size];
            [invocation getArgument:buff atIndex:i];
            JS::RootedValue val(cx);
            if (!XJSValueFromType(cx, type, buff, &val))
            {
                [NSException raise:NSInvalidArgumentException format:@"Unable to invoke method (%@)  on object (%@). Failed to convert paramaeter of type (%s)", prop, value, type];
            }
            
            [args addObject:[[XJSValue alloc] initWithContext:value.context value:val]];
        }
        
        XJSValue *retval = [value invokeMethod:prop withArguments:args];
        
        if (!retval) {
            [NSException raise:NSInvalidArgumentException format:@"Unable to invoke method (%@) with arguments (%@) on object (%@)", prop, args, value];
        }
        
        NSUInteger retsize = [signature methodReturnLength];
        if (retsize) {  // not void
            const char *type = [signature methodReturnType];
            
            auto ret = XJSValueToType(cx, retval.value, type);
            if (ret.first) {    // NSValue
                alignas(sizeof(NSInteger)) unsigned char buff[retsize];
                [ret.first getValue:buff];
                [invocation setReturnValue:buff];
            } else if (ret.second) {
                [invocation setReturnValue:(void *)&ret.second];
            } else {
                if (type[0] == _C_ID || type[0] == _C_CLASS) {
                    if (retval.isNullOrUndefined) {
                        retval = nil;
                    }
                    // cannot convert to ObjC object, just return XJSValue
                    [invocation setReturnValue:&retval];
                } else {
                    [NSException raise:NSInvalidArgumentException format:@"Unable to invoke method (%@)  on object (%@). Failed to convert return value of type (%s)", prop, value, type];
                }
            }
        }
        
        
    } else {
        static void (*doesNotRecognizeSelector)(id, SEL, SEL);
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            doesNotRecognizeSelector = (void (*)(id, SEL, SEL))[NSObject instanceMethodForSelector:@selector(doesNotRecognizeSelector:)];
        });
        
        doesNotRecognizeSelector(self, @selector(doesNotRecognizeSelector:), sel);
    }
}

@interface XJSProtocolAdopter : NSObject

+ (id)adopterForProtocol:(Protocol *)protocol withValue:(XJSValue *)value;

@end

@implementation XJSAdopter
{
    XJSValue *_value;
    Class _class;
}

+ (id)adopterForProtocol:(Protocol *)protocol withValue:(XJSValue *)value
{
    return [XJSProtocolAdopter adopterForProtocol:protocol withValue:value];
}

+ (id)adopterForClass:(Class)cls withValue:(XJSValue *)value
{
    XLCAssertNotNullCritical(cls);
    
    if (!value || value.isPrimitive) {
        return nil;
    }
    
    XJSAdopter *adopter = [self alloc];
    adopter->_value = value;
    adopter->_class = cls;
    return adopter;
}

#pragma mark -

- (void)forwardInvocation:(NSInvocation *)invocation
{
    forwardInvocationImpl(self, _value, invocation);
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    return [_class instanceMethodSignatureForSelector:sel];
}

#pragma mark - NSObject

- (Class)class
{
    return _class;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    return class_conformsToProtocol(_class, aProtocol);
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if (!aSelector) return NO;
    
    return !!XJSSearchProperty(_value.context.context, _value.value.toObjectOrNull(), aSelector);
}

- (BOOL)isKindOfClass:(Class)aClass
{
    for (Class cls = _class; cls; cls = [cls superclass])
    {
        if (cls == aClass) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isMemberOfClass:(Class)aClass
{
    return _class == aClass;
}

#pragma mark - SubscriptSupport

- (XJSValue *)objectForKeyedSubscript:(id)key
{
    return [_value objectForKeyedSubscript:key];
}

- (XJSValue *)objectAtIndexedSubscript:(uint32_t)index
{
    return [_value objectAtIndexedSubscript:index];
}

- (void)setObject:(id)object forKeyedSubscript:(id)key
{
    [_value setObject:object forKeyedSubscript:key];
}

- (void)setObject:(id)object atIndexedSubscript:(uint32_t)index
{
    [_value setObject:object atIndexedSubscript:index];
}

#pragma mark -

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context
{
    return _value;
}

@end

#pragma mark - XJSProtocolAdopter

@implementation XJSProtocolAdopter
{
    XJSValue *_value;
    Protocol *_protocol;
}

+ (id)adopterForProtocol:(Protocol *)protocol withValue:(XJSValue *)value
{
    XLCAssertNotNullCritical(protocol);
    
    if (!value || value.isPrimitive) {
        return nil;
    }
    
    XJSProtocolAdopter *adopter = [[self alloc] init];
    adopter->_value = value;
    adopter->_protocol = protocol;
    return adopter;
}

#pragma mark -

- (void)forwardInvocation:(NSInvocation *)invocation
{
    forwardInvocationImpl(self, _value, invocation);
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    if (_protocol) {
        auto desc = protocol_getMethodDescription(_protocol, sel, YES, YES);
        if (!desc.types) {
            desc = protocol_getMethodDescription(_protocol, sel, NO, YES);
        }
        
        if (desc.types) {
            return [NSMethodSignature signatureWithObjCTypes:desc.types];
        }
    }
    
    return [super methodSignatureForSelector:sel];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    return protocol_conformsToProtocol(_protocol, aProtocol) || [super conformsToProtocol:aProtocol];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if (!aSelector) return NO;
    
    return !!XJSSearchProperty(_value.context.context, _value.value.toObjectOrNull(), aSelector)
    || [super respondsToSelector:aSelector];
}

#pragma mark - SubscriptSupport

- (XJSValue *)objectForKeyedSubscript:(id)key
{
    return [_value objectForKeyedSubscript:key];
}

- (XJSValue *)objectAtIndexedSubscript:(uint32_t)index
{
    return [_value objectAtIndexedSubscript:index];
}

- (void)setObject:(id)object forKeyedSubscript:(id)key
{
    [_value setObject:object forKeyedSubscript:key];
}

- (void)setObject:(id)object atIndexedSubscript:(uint32_t)index
{
    [_value setObject:object atIndexedSubscript:index];
}

#pragma mark -

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context
{
    return _value;
}

- (BOOL)isProxy
{
    return YES;
}

@end