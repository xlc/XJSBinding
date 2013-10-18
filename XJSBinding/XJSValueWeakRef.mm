//
//  XJSValueWeakRef.mm
//  XJSBinding
//
//  Created by Xiliang Chen on 13-10-18.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSValueWeakRef.h"

@implementation XJSValueWeakRef
{
    __weak XJSValue *_value;
}

- (id)initWithValue:(XJSValue *)value
{
    self = [super init];
    if (self) {
        _value = value;
    }
    return self;
}

- (XJSValue *)value
{
    return _value;
}

- (void)setValue:(XJSValue *)value
{
    _value = value;
}

@end

@implementation XJSValue (XJSValueWeakRef)

- (XJSValueWeakRef *)weakReference
{
    return [[XJSValueWeakRef alloc] initWithValue:self];
}

@end