//
//  XJSConvert.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-10.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "jsapi.h"

NSString *XJSConvertJSValueToString(JSContext *cx, jsval val);
NSString *XJSConvertJSValueToSource(JSContext *cx, jsval val);

jsval XJSConvertStringToJSValue(JSContext *cx, NSString *string);