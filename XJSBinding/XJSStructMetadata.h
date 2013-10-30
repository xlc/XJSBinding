//
//  XJSStructMetadata.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-10-26.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

#define XJS_CREATE_FIELD(type, field) [[XJSStructField alloc] initWithOffset:offsetof(type, field) name:@#field]

@interface XJSStructField: NSObject

@property (readonly) size_t offset;
@property (readonly) NSString *name;
@property (readonly) NSString *encoding;
@property (readonly) NSUInteger size;

- (id)initWithOffset:(size_t)offset name:(NSString *)name;

@end

@interface XJSStructMetadata : NSObject

@property (readonly) NSString *name;
@property (readonly) NSArray *fields;
@property (readonly) NSString *encoding;

- (id)initWithEncoding:(NSString *)encoding fields:(NSArray *)fields;

+ (void)addMetadataWithEncoding:(NSString *)encoding fields:(NSArray *)fields;
+ (XJSStructMetadata *)metadataForEncoding:(NSString *)encoding;

@end
