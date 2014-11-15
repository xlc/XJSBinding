//
//  XJSModuleManager+XJSModules.mm
//  XJSBinding
//
//  Created by Xiliang Chen on 13-12-21.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSModuleManager+XJSModules.h"

#import "jsapi.h"

#import "XJSLogger.hh"
#import "XJSContext_Private.hh"
#import "XJSValue_Private.hh"

@implementation XJSModuleManager (XJSModules)

+ (void)load
{
    [XJSModuleManager provideBlock:^BOOL(XJSValue *require, XJSValue *exports, XJSValue *module) {
        XJSContext *cx = require.context;
        [cx createObjCRuntimeWithNamespace:nil];
        
        XJSValue *val = [[XJSValue alloc] initWithContext:cx value:JS::ObjectOrNullValue(cx.runtimeEntryObject)];
        module[@"exports"] = val;
        
        return YES;
    } forModuleId:@"xjs/objc"];
    
    [XJSModuleManager provideBlock:^BOOL(XJSValue *require, XJSValue *exports, XJSValue *module) {
        XJSContext *cx = require.context;
        JSObject *obj = XJSCreateLogger(cx.context);
        XJSValue *val = [[XJSValue alloc] initWithContext:cx value:JS::ObjectOrNullValue(obj)];
        module[@"exports"] = val;
        
        return YES;
    } forModuleId:@"xjs/log"];
    
    [XJSModuleManager provideBlock:^BOOL(XJSValue *require, XJSValue *exports, XJSValue *module) {
        XJSContext *cx = require.context;
        JSObject *obj = JS_NewObject(cx.context, NULL, NULL, NULL);
        
        JSObject *reflect = JS_InitReflect(cx.context, obj);
        XJSValue *val = [[XJSValue alloc] initWithContext:cx value:JS::ObjectOrNullValue(reflect)];
        module[@"exports"] = val;
        
        return YES;
    } forModuleId:@"xjs/reflect"];
}

@end
