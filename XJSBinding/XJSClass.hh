//
//  XJSClass.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-10-2.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "jsapi.h"

JSObject *XJSGetOrCreateJSObject(JSContext *cx, id obj);
JSObject *XJSCreateJSObject(JSContext *cx, id obj);
id XJSGetAssosicatedObject(JSObject *jsobj);