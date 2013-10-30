//
//  XJSStructMetadata+XJSLoadCommonStructure.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-10-30.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSStructMetadata+XJSLoadCommonStructure.h"

#import <CoreGraphics/CoreGraphics.h>

@implementation XJSStructMetadata (XJSLoadCommonStructure)

+ (void)load
{
    [self addMetadataWithEncoding:@(@encode(NSRange)) fields:@[XJS_CREATE_FIELD(NSRange, location),
                                                               XJS_CREATE_FIELD(NSRange, length),
                                                               ]];
    
    [self addMetadataWithEncoding:@(@encode(CGPoint)) fields:@[XJS_CREATE_FIELD(CGPoint, x),
                                                               XJS_CREATE_FIELD(CGPoint, y),
                                                               ]];
    
    [self addMetadataWithEncoding:@(@encode(CGSize)) fields:@[XJS_CREATE_FIELD(CGSize, width),
                                                              XJS_CREATE_FIELD(CGSize, height),
                                                               ]];
    
    [self addMetadataWithEncoding:@(@encode(CGRect)) fields:@[XJS_CREATE_FIELD(CGRect, origin),
                                                              XJS_CREATE_FIELD(CGRect, size),
                                                               ]];
    
    [self addMetadataWithEncoding:@(@encode(CGAffineTransform)) fields:@[XJS_CREATE_FIELD(CGAffineTransform, a),
                                                                         XJS_CREATE_FIELD(CGAffineTransform, b),
                                                                         XJS_CREATE_FIELD(CGAffineTransform, c),
                                                                         XJS_CREATE_FIELD(CGAffineTransform, d),
                                                                         XJS_CREATE_FIELD(CGAffineTransform, tx),
                                                                         XJS_CREATE_FIELD(CGAffineTransform, ty),
                                                                         ]];
}

@end
