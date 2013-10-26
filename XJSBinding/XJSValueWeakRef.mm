//
//  XJSValueWeakRef.mm
//  XJSBinding
//
//  Created by Xiliang Chen on 13-10-18.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSValueWeakRef.h"

#import "XLCAssertion.h"
#import "NSObject+XJSValueConvert.h"

#import "XJSWeakMap.h"

@implementation XJSValueWeakRef
{
    __weak XJSValue *_value;
    XJSWeakMap *_map;
}

- (id)initWithValue:(XJSValue *)value
{
    XASSERT_NOTNULL(value);
    self = [super init];
    if (self) {
        _map = [[XJSWeakMap alloc] initWithContext:value.context];
        self.value = value;
    }
    return self;
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
    
    XJSValue *allKeys = [_map allKeys];
    
    if (allKeys[@"length"].toInt32 == 0)
    {
        _map = nil; // no use anymore
        return nil;
    }
    
    _value = allKeys[0];
    return _value;
}

- (void)setValue:(XJSValue *)value
{
    _value = value;
    
    @synchronized(_map) {
        [_map removeAllObjects];
        if (!value.isPrimitive) {   // map key cannot be primitive type and no much reason to hold weak ref to primitive type
            _map[value] = [XJSValue valueWithNullInContext:value.context];
        }
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