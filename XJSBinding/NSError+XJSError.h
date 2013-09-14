//
//  NSError+XJSError.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-14.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const XJSErrorDomain;

extern NSString * const XJSDetailedErrorsKey;
extern NSString * const XJSErrorLineNumberKey;
extern NSString * const XJSErrorFileNameKey;
extern NSString * const XJSErrorMessageKey;

@interface NSError (XJSError)

+ (NSError *)errorWithXJSDomainAndUserInfo:(NSDictionary *)dict;
+ (NSError *)errorWithXJSDomainAndFileName:(NSString *)filename lineNumber:(NSUInteger)lineno message:(NSString *)message;
+ (NSError *)errorWithXJSDomainAndDetailedErrors:(NSArray *)errors;

@end
