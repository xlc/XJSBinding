//
//  XJSRuntime_Private.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-7.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSRuntime.h"

#import "jsapi.h"

@class XJSRuntimeThread;

@interface XJSRuntime ()

@property (assign) JSRuntime *runtime;
@property (strong, readonly) XJSRuntimeThread *thread;

@end
