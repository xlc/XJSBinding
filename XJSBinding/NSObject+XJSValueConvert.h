//
//  NSObject+XJSValueConvert.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-27.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XJSValue;
@class XJSContext;

@interface NSObject (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context;

@end

@interface NSNumber (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context;

@end

@interface NSString (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context;

@end

@interface NSNull (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context;

@end

// TODO NSArray NSDictionary NSValue NSDate