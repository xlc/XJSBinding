//
//  XJSFunction.h
//  XJSBinding
//
//  Created by Xiliang Chen on 14-3-15.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XJSValue;
@class XJSContext;

@protocol XJSCallable <NSObject>

- (id)callWithArguments:(NSArray *)args;

@end

@interface XJSFunction : NSObject <XJSCallable>

+ (instancetype)functionWithBlock:(id(^)(NSArray *args))block;
+ (instancetype)functionWithXJSValue:(XJSValue *)value;

- (id)call;
- (id)callWithArguments:(NSArray *)args;

@end

@interface XJSFunction (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context;

@end