//
//  XJSContext_Private.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-7.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSContext.h"

#import "jsapi.h"

@interface XJSContext ()

@property (assign, readonly) JSContext *context;
@property (strong) NSString *errorMessage;

+ (XJSContext *)contextForJSContext:(JSContext *)jscontext;

@end
