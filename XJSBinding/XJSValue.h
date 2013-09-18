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

@property (strong, readonly) XJSContext *context;

//// Create a JSValue by converting an Objective-C object.
//+ (XJSValue *)valueWithObject:(id)value inContext:(XJSContext *)context;

+ (XJSValue *)valueWithString:(NSString *)value inContext:(XJSContext *)context;

+ (XJSValue *)valueWithBool:(BOOL)value inContext:(XJSContext *)context;
+ (XJSValue *)valueWithDouble:(double)value inContext:(XJSContext *)context;
+ (XJSValue *)valueWithInt32:(int32_t)value inContext:(XJSContext *)context;

+ (XJSValue *)valueWithNullInContext:(XJSContext *)context;
+ (XJSValue *)valueWithUndefinedInContext:(XJSContext *)context;

- (int32_t)toInt32;
- (uint32_t)toUInt32;
- (int64_t)toInt64;
- (uint64_t)toUInt64;
- (double)toDouble;
- (BOOL)toBool;
- (NSString *)toString;

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

- (BOOL)isUndefined;
- (BOOL)isNull;
- (BOOL)isBoolean;
- (BOOL)isNumber;
- (BOOL)isString;
- (BOOL)isObject;

- (BOOL)isNullOrUndefined;
- (BOOL)isInt32;
- (BOOL)isDouble;
- (BOOL)isPrimitive;

- (BOOL)isEqual:(id)object; // lossely equal
- (BOOL)isStrictlyEqualToValue:(XJSValue *)object; // ===
- (BOOL)isLooselyEqualToValue:(XJSValue *)object;  // ==
- (BOOL)isSameValue:(XJSValue *)object; // NaN is same as NaN and -0 is not same as +0

@end

@interface XJSValue(SubscriptSupport)

//- (XJSValue *)objectForKeyedSubscript:(id)key;
//- (XJSValue *)objectAtIndexedSubscript:(NSUInteger)index;
//- (void)setObject:(id)object forKeyedSubscript:(id)key;
//- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index;

@end