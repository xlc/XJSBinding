//
//  XJSBinding.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-29.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSBinding.h"

#import "XLCAssertion.h"

#import "XJSRuntimeEntry.h"

JSObject * XJSCreateRuntimeEntry(JSContext *cx)
{
    return JS_NewObject(cx, XJSRuntimeEntry, NULL, NULL);
}