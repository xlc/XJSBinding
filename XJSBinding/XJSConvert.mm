//
//  XJSConvert.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-10.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSConvert.h"

#import "XLCAssertion.h"

NSString *XJSConvertJSValueToString(JSContext *cx, jsval val)
{
    JSAutoByteString str;
    return @(str.encodeUtf8(cx, JSVAL_TO_STRING(val)));
}

NSString *XJSConvertJSValueToSource(JSContext *cx, jsval val)
{
    JSAutoByteString str;
    JSString *jsstr = JS_ValueToSource(cx, val);
    return @(str.encodeUtf8(cx, jsstr));
}

jsval XJSConvertStringToJSValue(JSContext *cx, NSString *string)
{
    JSAutoRequest request(cx);
    return STRING_TO_JSVAL(JS_NewStringCopyN(cx, [string UTF8String], [string length]));
}