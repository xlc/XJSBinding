//
//  XJSValue.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-7.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XJSContext;

@interface XJSValue : NSObject

//// Create a JSValue by converting an Objective-C object.
//+ (XJSValue *)valueWithObject:(id)value inContext:(XJSContext *)context;
//// Create a JavaScript value from an Objective-C primitive type.
//+ (XJSValue *)valueWithBool:(BOOL)value inContext:(XJSContext *)context;
//+ (XJSValue *)valueWithDouble:(double)value inContext:(XJSContext *)context;
//+ (XJSValue *)valueWithInt32:(int32_t)value inContext:(XJSContext *)context;
//+ (XJSValue *)valueWithUInt32:(uint32_t)value inContext:(XJSContext *)context;
//// Create a JavaScript value in this context.
//+ (XJSValue *)valueWithNewObjectInContext:(XJSContext *)context;
//+ (XJSValue *)valueWithNewArrayInContext:(XJSContext *)context;
//+ (XJSValue *)valueWithNewRegularExpressionFromPattern:(NSString *)pattern flags:(NSString *)flags inContext:(XJSContext *)context;
//+ (XJSValue *)valueWithNewErrorFromMessage:(NSString *)message inContext:(XJSContext *)context;
//+ (XJSValue *)valueWithNullInContext:(XJSContext *)context;
//+ (XJSValue *)valueWithUndefinedInContext:(XJSContext *)context;
//
//// Convert this value to a corresponding Objective-C object, according to the
//// conversion specified above.
//- (id)toObject;
//// Convert this value to a corresponding Objective-C object, if the result is
//// not of the specified class then nil will be returned.
//- (id)toObjectOfClass:(Class)expectedClass;
//// The value is copied to a boolean according to the conversion specified by the
//// JavaScript language.
//- (BOOL)toBool;
//// The value is copied to a number according to the conversion specified by the
//// JavaScript language.
//- (double)toDouble;
//// The value is copied to an integer according to the conversion specified by
//// the JavaScript language.
//- (int32_t)toInt32;
//// The value is copied to an integer according to the conversion specified by
//// the JavaScript language.
//- (uint32_t)toUInt32;
//// If the value is a boolean, a NSNumber value of @YES or @NO will be returned.
//// For all other types the value will be copied to a number according to the
//// conversion specified by the JavaScript language.
//- (NSNumber *)toNumber;
//// The value is copied to a string according to the conversion specified by the
//// JavaScript language.
//- (NSString *)toString;
//// The value is converted to a number representing a time interval since 1970,
//// and a new NSDate instance is returned.
//- (NSDate *)toDate;
//// If the value is null or undefined then nil is returned.
//// If the value is not an object then a JavaScript TypeError will be thrown.
//// The property "length" is read from the object, converted to an unsigned
//// integer, and an NSArray of this size is allocated. Properties corresponding
//// to indicies within the array bounds will be copied to the array, with
//// Objective-C objects converted to equivalent JSValues as specified.
//- (NSArray *)toArray;
//// If the value is null or undefined then nil is returned.
//// If the value is not an object then a JavaScript TypeError will be thrown.
//// All enumerable properties of the object are copied to the dictionary, with
//// Objective-C objects converted to equivalent JSValues as specified.
//- (NSDictionary *)toDictionary;
//
//// All JavaScript values are precisely one of these types.
//- (BOOL)isUndefined;
//- (BOOL)isNull;
//- (BOOL)isBoolean;
//- (BOOL)isNumber;
//- (BOOL)isString;
//- (BOOL)isObject;
//
//// The JSContext that this value originates from.
//@property(readonly, strong) XJSContext *context;

@end

@interface XJSValue(SubscriptSupport)

//- (XJSValue *)objectForKeyedSubscript:(id)key;
//- (XJSValue *)objectAtIndexedSubscript:(NSUInteger)index;
//- (void)setObject:(id)object forKeyedSubscript:(id)key;
//- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index;

@end