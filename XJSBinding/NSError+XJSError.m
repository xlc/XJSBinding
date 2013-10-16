//
//  NSError+XJSError.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-14.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "NSError+XJSError.h"

NSString * const XJSErrorDomain = @"XJSErrorDomain";

NSString * const XJSDetailedErrorsKey = @"XJSDetailedErrorsKey";
NSString * const XJSErrorLineNumberKey = @"XJSErrorLineNumberKey";
NSString * const XJSErrorFileNameKey = @"XJSErrorFileNameKey";
NSString * const XJSErrorMessageKey = @"XJSErrorMessageKey";

@implementation NSError (XJSError)

+ (NSError *)errorWithXJSDomainAndUserInfo:(NSDictionary *)dict
{
    return [self errorWithDomain:XJSErrorDomain code:0 userInfo:dict];
}

+ (NSError *)errorWithXJSDomainAndFileName:(NSString *)filename lineNumber:(NSUInteger)lineno message:(NSString *)message
{
    return [self errorWithXJSDomainAndUserInfo:@{
                                                 XJSErrorFileNameKey: filename ?: @"",
                                                 XJSErrorLineNumberKey: @(lineno),
                                                 XJSErrorMessageKey: message ?: @"",
                                                 }];
}

+ (NSError *)errorWithXJSDomainAndDetailedErrors:(NSArray *)errors
{
    return [self errorWithXJSDomainAndUserInfo:@{ XJSDetailedErrorsKey: [errors copy] }];
}

@end
