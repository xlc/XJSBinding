//
//  XJSValue.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-7.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSValue_Private.h"

#import "jsapi.h"

#import "XJSContext_Private.h"

@implementation XJSValue

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

@end
