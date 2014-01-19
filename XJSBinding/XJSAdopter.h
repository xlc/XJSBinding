//
//  XJSAdopter.h
//  XJSBinding
//
//  Created by Xiliang Chen on 14-1-6.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XJSValue;

@interface XJSAdopter : NSProxy

+ (id)adopterForProtocol:(Protocol *)protocol withValue:(XJSValue *)value;
+ (id)adopterForClass:(Class)cls withValue:(XJSValue *)value;

@end