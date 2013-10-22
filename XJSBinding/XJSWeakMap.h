//
//  XJSWeakMap.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-10-19.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XJSContext;
@class XJSValue;

@interface XJSWeakMap : NSObject

@property (readonly) XJSContext *context;

- (id)initWithContext:(XJSContext *)context;

- (XJSValue *)objectForKey:(XJSValue *)key;
- (void)setObject:(XJSValue *)object forKey:(XJSValue *)key;

- (void)removeObjectForKey:(XJSValue *)key;
- (void)removeAllObjects;

- (XJSValue *)allKeys;  // js array of keys

@end

@interface XJSWeakMap (SubscriptSupport)

- (XJSValue *)objectForKeyedSubscript:(XJSValue *)key;
- (void)setObject:(XJSValue *)object forKeyedSubscript:(XJSValue *)key;

@end
