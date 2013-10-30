//
//  XJSStructMetadata.mm
//  XJSBinding
//
//  Created by Xiliang Chen on 13-10-26.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSStructMetadata.h"

#import <algorithm>
#import <atomic>
#import <objc/runtime.h>

#import "XLCAssertion.h"

@interface XJSStructField ()

@property (strong, readwrite) NSString *encoding;
@property (readwrite) NSUInteger size;

@end

@implementation XJSStructField

- (id)initWithOffset:(size_t)offset name:(NSString *)name
{
    self = [super init];
    if (self) {
        _offset = offset;
        _name = [name copy];
    }
    return self;
}

@end

@interface XJSStructMetadata ()

- (void)parseEncoding;
- (const char *)input:(const char *)input expect:(char )c;

@end

static NSMutableDictionary *metadataDict;

@implementation XJSStructMetadata

+ (void)initialize
{
    if (self == [XJSStructMetadata class]) {
        metadataDict = [NSMutableDictionary dictionary];
    }
}

+ (void)addMetadataWithEncoding:(NSString *)encoding fields:(NSArray *)fields
{
    XJSStructMetadata *metadata = [[self alloc] initWithEncoding:encoding fields:fields];
    @synchronized(metadataDict) {
        metadataDict[encoding] = metadata;
    }
}

+ (XJSStructMetadata *)metadataForEncoding:(NSString *)encoding
{
    @synchronized(metadataDict) {
        return metadataDict[encoding];
    }
}

#pragma mark -

- (id)initWithEncoding:(NSString *)encoding fields:(NSArray *)fields
{
    XASSERT_NOTNULL(encoding);
    XASSERT_NOTNULL(fields);
    self = [super init];
    if (self) {
        _encoding = encoding;
        _fields = [fields sortedArrayUsingComparator:^NSComparisonResult(XJSStructField *obj1, XJSStructField *obj2) {
            if (obj1.offset == obj2.offset) {
                return NSOrderedSame;
            }
            if (obj1.offset < obj2.offset) {
                return NSOrderedAscending;
            }
            return NSOrderedDescending;
        }];
        [self parseEncoding];
    }
    return self;
}

- (const char *)input:(const char *)input expect:(char )c
{
    if (input[0] == c) {
        return input+1;
    }
    
    XFAIL("Invalid encoding: %@, expect: %c got: %c", _encoding, c, input[0]);
    @throw [NSException exceptionWithName:@"EncodingParsingError" reason:@"Invalid or unsupported encoding" userInfo:@{@"Encoding" : _encoding}];

}

- (void)parseEncoding
{
    const char *encoding = [_encoding UTF8String];
    const char *end = encoding + strlen(encoding);
    encoding = [self input:encoding expect:_C_STRUCT_B];
    
    const char *findresult = std::find(encoding, end, '=');
    if (findresult == end) {
        XFAIL("Invalid encoding: %@, cannot find '='", _encoding);
        @throw [NSException exceptionWithName:@"EncodingParsingError" reason:@"Invalid or unsupported encoding" userInfo:@{@"Encoding" : _encoding}];
    }
    if (encoding[0] == _C_UNDEF) { // anonymous struct
        static std::atomic_uint count;
        _name = [NSString stringWithFormat:@"__AnonymousStruct_%u", count.fetch_add(1)];
    } else {
        _name = [[NSString alloc] initWithBytes:encoding length:findresult - encoding encoding:NSUTF8StringEncoding];
    }
    
    
    encoding = [self input:findresult expect:'='];
    if (encoding != end - 1) {  // not empty struct
        NSUInteger size;
        const char *next = NSGetSizeAndAlignment(encoding, &size, NULL);
        NSUInteger i = 0;
        while (encoding != end - 1) {
            if (_fields.count > i) {
                XJSStructField *field = _fields[i];
                field.encoding = [[NSString alloc] initWithBytes:encoding length:next - encoding encoding:NSUTF8StringEncoding];
                field.size = size;
            }
            
            ++i;
            encoding = next;
            if (encoding != end - 1) {
                next = NSGetSizeAndAlignment(encoding, &size, NULL);
            }
        }
    }
    
    encoding = [self input:encoding expect:_C_STRUCT_E];
}

@end
