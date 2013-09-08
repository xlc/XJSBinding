//
//  XJSRuntime.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-7.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * A JS runtime is assosicaed to a workder thread and every JS related operation will be executed in the worker thread.
 */

@interface XJSRuntime : NSObject

/**
 * This will create and start the worker thread.
 */
- (id)init;

/**
 * Perform block on the worker thread.
 */
- (void)performBlock:(void (^)(void))block;
- (void)performBlockAndWait:(void (^)(void))block;

@end
