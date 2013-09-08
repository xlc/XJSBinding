//
//  XJSRuntimeThread.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-7.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XJSRuntime;

@interface XJSRuntimeThread : NSThread

- (id)initWithRuntime:(XJSRuntime *)runtime;

- (void)stop;

@end
