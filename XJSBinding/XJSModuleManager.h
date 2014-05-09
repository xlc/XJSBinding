//
//  XJSModuleManager.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-12-12.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XJSValue;
@class XJSContext;

// aim to implement CommonJS module system version 1.1.1: http://wiki.commonjs.org/wiki/Modules/1.1.1
@interface XJSModuleManager : NSObject

@property (weak, readonly) XJSContext *context; // context should hold strong ref to this
@property (readonly) XJSValue *require; // the require function

//@property (readonly) NSString *main; // TODO how to implement?
@property (copy) NSArray *paths;

- (id)initWithContext:(XJSContext *)context scriptProvider:(NSString *(^)(NSString *path))scriptProvider;

- (XJSValue *)requireModule:(NSString *)moduleId;

- (void)provideValue:(XJSValue *)exports forModuleId:(NSString *)moduleId;
- (void)provideScript:(NSString *)script forModuleId:(NSString *)moduleId;
- (void)provideBlock:(BOOL(^)(XJSValue *require, XJSValue *exports, XJSValue *module))block forModuleId:(NSString *)moduleId;

+ (void)provideValue:(XJSValue *)exports forModuleId:(NSString *)moduleId;
+ (void)provideScript:(NSString *)script forModuleId:(NSString *)moduleId;
+ (void)provideBlock:(BOOL(^)(XJSValue *require, XJSValue *exports, XJSValue *module))block forModuleId:(NSString *)moduleId;

- (void)reloadAll;
- (XJSValue *)reloadModule:(NSString *)moduleId;

@end
