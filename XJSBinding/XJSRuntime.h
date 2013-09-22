//
//  XJSRuntime.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-7.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XJSRuntime : NSObject

- (id)init;

- (void)performBlock:(void (^)(void))block;

- (void)gc;

@end
