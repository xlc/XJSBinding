//
//  XJSFunction.m
//  XJSBinding
//
//  Created by Xiliang Chen on 14-3-15.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import "XJSFunction.h"

#include "XJSValue.h"
#include "NSObject+XJSValueConvert.h"

@implementation XJSFunction
{
    id(^_block)(NSArray *);
    XJSValue *_value;
}

+ (instancetype)functionWithBlock:(id(^)(NSArray *))block
{
    XJSFunction *func = [[self alloc] init];
    func->_block = block;
    return func;
}

+ (instancetype)functionWithXJSValue:(XJSValue *)value
{
    XJSFunction *func = [[self alloc] init];
    func->_value = value;
    return func;
}

#pragma mark -

- (BOOL)isEqual:(id)object
{
    if (!object) {
        return NO;
    }
    
    if (object == self) {
        return YES;
    }
    
    if (![object isMemberOfClass:[self class]]) {
        return NO;
    }
    
    XJSFunction *func = object;
    
    return func->_block == _block && func->_value == _value;
}

#pragma mark -

- (id)call
{
    return [self callWithArguments:@[]];
}

- (id)callWithArguments:(NSArray *)args
{
    if (_block) {
        return _block(args);
    }
    return [_value callWithArguments:args].toObject;
}

@end

@implementation XJSFunction (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context
{
    if (_value) {
        return [_value xjs_toValueInContext:context];
    }
    return [XJSValue valueWithObject:self inContext:context];
}

@end