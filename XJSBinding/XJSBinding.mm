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

void XJSBindingInit(NSString *name, JSContext *cx, JSObject *globalObject)
{
    if ([name length] == 0)
    {
        name = @"objc";
    }
    
    JSObject *rootobj = JS_NewObject(cx, XJSRuntimeEntry, NULL, NULL);
    JS::RootedValue rootval(cx, JS::ObjectOrNullValue(rootobj));
    JS_SetProperty(cx, globalObject, [name UTF8String], rootval);
}