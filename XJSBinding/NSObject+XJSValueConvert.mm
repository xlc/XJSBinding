//
//  NSObject+XJSValueConvert.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-27.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "NSObject+XJSValueConvert.h"

#import <objc/runtime.h>

#import "XLCAssertion.h"

#import "XJSValue_Private.hh"
#import "XJSContext.h"

XJSValue *XJSToValue(XJSContext *context, id obj)
{
    XJSValue *ret = [obj xjs_toValueInContext:context];
    if (ret) {
        return ret;
    }
    return [XJSValue valueWithNullInContext:context];
}

@implementation NSObject (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context
{
    return [XJSValue valueWithObject:self inContext:context];
}

@end

@implementation XJSValue (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context
{
    if (self.context == context) {
        return self;
    }
    
    XASSERT(self.isPrimitive || context.runtime == self.context.runtime, @"Move object from one runtime to another runtime is not supported yet");
    
    return [[XJSValue alloc] initWithContext:context value:self.value];
}

@end

@implementation NSValue (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context
{
    return [XJSValue valueWithNSValue:self inContext:context];
}

@end

@implementation NSString (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context
{
    return [XJSValue valueWithString:self inContext:context];
}

@end

@implementation NSNull (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context
{
    return [XJSValue valueWithNullInContext:context];
}

@end

@implementation NSDate (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context
{
    return [XJSValue valueWithDate:self inContext:context];
}

@end

@implementation NSArray (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context
{
    return [XJSValue valueWithArray:self inContext:context];
}

@end