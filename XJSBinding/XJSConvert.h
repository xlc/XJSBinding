//
//  XJSConvert.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-10.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <utility>

#import "jsapi.h"

NSString *XJSConvertJSValueToString(JSContext *cx, jsval val);
NSString *XJSConvertJSValueToSource(JSContext *cx, jsval val);

jsval XJSConvertStringToJSValue(JSContext *cx, NSString *string);

std::pair<NSValue *, id> XJSValueToType(JSContext *cx, jsval val, const char *encode);
JSBool XJSValueFromType(JSContext *cx, const char *encode, void *value, jsval *outval);