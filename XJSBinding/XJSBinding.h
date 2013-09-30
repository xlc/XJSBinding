//
//  XJSBinding.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-29.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "jsapi.h"

void XJSBindingInit(NSString *name, JSContext *cx, JSObject *globalObject);
