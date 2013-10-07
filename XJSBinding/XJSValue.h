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

// Create a wrapper of Objective-C object
+ (XJSValue *)valueWithObject:(id)value inContext:(XJSContext *)context;

+ (XJSValue *)valueWithString:(NSString *)value inContext:(XJSContext *)context;
+ (XJSValue *)valueWithDate:(NSDate *)date inContext:(XJSContext *)context;

+ (XJSValue *)valueWithBool:(BOOL)value inContext:(XJSContext *)context;
+ (XJSValue *)valueWithDouble:(double)value inContext:(XJSContext *)context;
+ (XJSValue *)valueWithInt32:(int32_t)value inContext:(XJSContext *)context;

+ (XJSValue *)valueWithNewObjectInContext:(XJSContext *)context;
+ (XJSValue *)valueWithNewArrayInContext:(XJSContext *)context;

+ (XJSValue *)valueWithNullInContext:(XJSContext *)context;
+ (XJSValue *)valueWithUndefinedInContext:(XJSContext *)context;

- (int32_t)toInt32;
- (uint32_t)toUInt32;
- (int64_t)toInt64;
- (uint64_t)toUInt64;
- (double)toDouble;
- (BOOL)toBool;
- (NSString *)toString;
- (NSDate *)toDate;
- (id)toObject;

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
- (BOOL)isNullOrUndefined;

- (BOOL)isBoolean;
- (BOOL)isNumber;
- (BOOL)isInt32;
- (BOOL)isDouble;

- (BOOL)isPrimitive;

- (BOOL)isString;
- (BOOL)isDate;
- (BOOL)isCallable;

- (BOOL)isObject;   // is Objective-C object

- (BOOL)isEqual:(id)object; // lossely equal
- (BOOL)isStrictlyEqualToValue:(XJSValue *)object; // ===
- (BOOL)isLooselyEqualToValue:(XJSValue *)object;  // ==
- (BOOL)isSameValue:(XJSValue *)object; // NaN is same as NaN and -0 is not same as +0

- (BOOL)isInstanceOf:(XJSValue *)value;

// Call this value as a function passing the specified arguments. Return nil on error.
- (XJSValue *)callWithArguments:(NSArray *)arguments;
// Call this value as a constructor passing the specified arguments.
- (XJSValue *)constructWithArguments:(NSArray *)arguments;
// Access the property named "method" from this value; call the value resulting
// from the property access as a function, passing this value as the "this"
// value, and the specified arguments.
- (XJSValue *)invokeMethod:(NSString *)method withArguments:(NSArray *)arguments;

@end

@interface XJSValue(SubscriptSupport)

- (XJSValue *)objectForKeyedSubscript:(id)key;
- (XJSValue *)objectAtIndexedSubscript:(uint32_t)index;
- (void)setObject:(id)object forKeyedSubscript:(id)key;
- (void)setObject:(id)object atIndexedSubscript:(uint32_t)index;

@end