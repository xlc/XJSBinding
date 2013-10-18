//
//  XJSValue_Private.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-11.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSValue.h"

#import "jsapi.h"

@interface XJSValue ()

@property (assign, readonly) jsval value;

- (id)initWithContext:(XJSContext *)context value:(jsval)val;

- (void)reportErrorWithSelector:(SEL)sel;

@end
