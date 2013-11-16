//
//  NSError_XJSError_Private.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-11-16.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NSError_XJSErrorConstants.h"

@interface NSError (XJSError)

+ (NSError *)errorWithXJSDomainAndUserInfo:(NSDictionary *)dict;
+ (NSError *)errorWithXJSDomainAndFileName:(NSString *)filename lineNumber:(NSUInteger)lineno message:(NSString *)message;
+ (NSError *)errorWithXJSDomainAndDetailedErrors:(NSArray *)errors;

@end