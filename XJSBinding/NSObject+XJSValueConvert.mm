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

#import "XJSValue_Private.h"
#import "XJSContext.h"

@implementation NSObject (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context
{
    return nil; // TODO wrap objc object
}

@end

@implementation XJSValue (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context
{
    if (self.context == context) {
        return self;
    }
    
    XLCASSERT(self.isPrimitive || context.runtime == self.context.runtime, @"Move object from one runtime to another runtime is not supported yet");
    
    return [[XJSValue alloc] initWithContext:context value:self.value];
}

@end

@implementation NSNumber (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context
{
    switch ([self objCType][0]) {
        case _C_CHR:
        case _C_UCHR:
        case _C_SHT:
        case _C_USHT:
        case _C_INT:
            return [XJSValue valueWithInt32:[self intValue] inContext:context];
            
        case _C_LNG:
        case _C_LNG_LNG:
        {
            long long value = [self longLongValue];
            
            if (value < INT32_MAX && value > INT32_MIN) { // fit in int32
                return [XJSValue valueWithInt32:(int32_t)value inContext:context];
            } else {
                return [XJSValue valueWithDouble:(double)value inContext:context];
            }
        }
            
        case _C_UINT:
        case _C_ULNG:
        case _C_ULNG_LNG:
        {
            unsigned long long value = [self unsignedLongLongValue];
            
            if (value < INT32_MAX) { // fit in int32
                return [XJSValue valueWithInt32:(int32_t)value inContext:context];
            } else {
                return [XJSValue valueWithDouble:(double)value inContext:context];
            }
        }
            
        case _C_BOOL:
            return [XJSValue valueWithBool:[self boolValue] inContext:context];
            
        case _C_FLT:    // float
        case _C_DBL:    // double
        default:        // unkown type... using double
            return [XJSValue valueWithDouble:[self doubleValue] inContext:context];
    }
    
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