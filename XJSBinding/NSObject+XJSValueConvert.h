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

__BEGIN_DECLS

// call xjs_toValueInContext on obj or return [XJSValue valueWithNullInContext:context] if obj is nil
// never return nil
XJSValue *XJSToValue(XJSContext *context, id obj);

__END_DECLS

@interface NSObject (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context;

@end

@interface NSValue (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context;

@end

@interface NSString (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context;

@end

@interface NSNull (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context;

@end

@interface NSDate (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context;

@end

@interface NSArray (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context;

@end

@interface NSDictionary (XJSValueConvert)

- (XJSValue *)xjs_toValueInContext:(XJSContext *)context;

@end