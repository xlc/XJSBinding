//
//  XJSValueWeakRef.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-10-18.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XJSValue.h"

@interface XJSValueWeakRef : NSObject

@property (weak) XJSValue *value;

- (id)initWithValue:(XJSValue *)value;

@end

@interface XJSValue (XJSValueWeakRef)

- (XJSValueWeakRef *)weakReference;

@end