//
//  XJSConvert.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-10.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSConvert.h"

#import <objc/runtime.h>

#import "XLCAssertion.h"

#import "NSObject+XJSValueConvert.h"
#import "XJSValue_Private.h"
#import "XJSContext_Private.h"
#import "XJSClass.h"

NSString *XJSConvertJSValueToString(JSContext *cx, jsval val)
{
    JSAutoByteString str;
    return @(str.encodeUtf8(cx, JS_ValueToString(cx, val)));
}

NSString *XJSConvertJSValueToSource(JSContext *cx, jsval val)
{
    JSAutoByteString str;
    JSString *jsstr = JS_ValueToSource(cx, val);
    return @(str.encodeUtf8(cx, jsstr));
}

jsval XJSConvertStringToJSValue(JSContext *cx, NSString *string)
{
    return STRING_TO_JSVAL(JS_NewStringCopyN(cx, [string UTF8String], [string length]));
}

template <typename T>
static std::pair<NSValue *, id> MakePair(const char *encode, NSUInteger size, T val)
{
    XASSERT(size == sizeof(val), @"expected type with size %lu but return type with size %lu", (unsigned long)size, (unsigned long)sizeof(val));
    return { [NSValue valueWithBytes:&val objCType:encode], (id)nil };
}

std::pair<NSValue *, id> XJSValueToType(JSContext *cx, jsval val, const char *encode)
{
    NSUInteger size;
    auto encode2 = NSGetSizeAndAlignment(encode, &size, NULL);
    XASSERT(encode2[0] == '\0', @"encode should only contain one type");
    XJSValue *xval = [[XJSValue alloc] initWithContext:[XJSContext contextForJSContext:cx] value:val];
    
    switch (encode[0]) {
        case _C_CLASS:  //    '#'
        case _C_ID:  //       '@'
            XASSERT(size == sizeof(id), @"expected type with size %lu but return type with size %lu", (unsigned long)size, (unsigned long)sizeof(id));
            return { (NSValue *)nil, xval.toObject };

        case _C_SEL:  //      ':'
            return MakePair(encode, size, sel_getUid([XJSConvertJSValueToString(cx, val) UTF8String]));
            
        case _C_CHARPTR:  //  '*'
            return MakePair(encode, size, [XJSConvertJSValueToString(cx, val) UTF8String]);
            
        case _C_BOOL:  //     'B'
            return MakePair(encode, size, (bool)xval.toBool);
            
        case _C_CHR:  //      'c'
        case _C_UCHR:  //     'C'
            return MakePair(encode, size, (char)xval.toInt32);
            
        case _C_SHT:  //      's'
        case _C_USHT:  //     'S'
            return MakePair(encode, size, (short)xval.toInt32);
            
        case _C_INT:  //      'i'
            return MakePair(encode, size, (int)xval.toInt32);
            
        case _C_UINT:  //     'I'
            return MakePair(encode, size, (unsigned int)xval.toInt64);
            
        case _C_LNG:  //      'l'
        case _C_ULNG:  //     'L'
            return MakePair(encode, size, (long)xval.toInt64);
            
        case _C_LNG_LNG:  //  'q'
        case _C_ULNG_LNG:  // 'Q'
            return MakePair(encode, size, (long long)xval.toInt64);
            
        case _C_FLT:  //      'f'
            return MakePair(encode, size, (float)xval.toDouble);
            
        case _C_DBL:  //      'd'
            return MakePair(encode, size, (double)xval.toDouble);
            
        case _C_CONST:  //    'r'
            XWLOG(@"ignore encode modifier 'r' (const) for type %s", encode);
            return XJSValueToType(cx, val, encode+1);
            
        case _C_STRUCT_B:  // '{'
            // TODO support struct

            
            // unsuportted type
        case _C_UNION_B:  //  '('   support union??
        case _C_ARY_B:  //    '['   support array??
        case _C_PTR:  //      '^'   support pointer??
            
            // WTF
        case _C_BFLD:  //     'b'
        case _C_VECTOR:  //   '!'
        case _C_ATOM:  //     '%'
        case _C_VOID:  //     'v'
        case _C_UNDEF:  //    '?'
        case _C_STRUCT_E:  // '}'
        case _C_UNION_E:  //  ')'
        case _C_ARY_E:  //    ']'
        default:
            XWLOG(@"unsouportted type %s", encode);
            return {};
    }
}

JSBool XJSValueFromType(JSContext *cx, const char *encode, void *value, jsval *outval)
{
    XASSERT_NOTNULL(outval);
    XASSERT_NOTNULL(value);
    
    NSUInteger size;
    auto encode2 = NSGetSizeAndAlignment(encode, &size, NULL);
    XASSERT(encode2[0] == '\0', @"encode should only contain one type");
    
    switch (encode[0]) {
        case _C_CLASS:  //    '#'
        case _C_ID:  //       '@'
        {
            XASSERT(size == sizeof(id), @"expected type with size %lu but return type with size %lu", (unsigned long)size, sizeof(id));
            id obj = *(id __autoreleasing *)value;
            *outval = [obj xjs_toValueInContext:[XJSContext contextForJSContext:cx]].value;
            return JS_TRUE;
        }
            
        case _C_SEL:  //      ':'
            *outval = JS::StringValue(JS_NewStringCopyZ(cx, sel_getName(*(SEL *)value)));
            return JS_TRUE;
            
        case _C_CHARPTR:  //  '*'
            *outval = JS::StringValue(JS_NewStringCopyZ(cx, *(const char **)value));
            return JS_TRUE;
            
        case _C_BOOL:  //     'B'
            *outval = JS::BooleanValue(*(bool *)value);
            return JS_TRUE;
            
        case _C_CHR:  //      'c'
        {
            BOOL val = *(BOOL *)value;
            if (val == YES) {
                *outval = JSVAL_TRUE;
                return JS_TRUE;
            } else if (val == NO) {
                *outval = JSVAL_FALSE;
                return JS_TRUE;
            } else {
                *outval = JS::NumberValue(*(unsigned char *)value);
                return JS_TRUE;
            }
        }
            
        case _C_UCHR:  //     'C'
            *outval = JS::NumberValue(*(char *)value);
            return JS_TRUE;
            
        case _C_SHT:  //      's'
            *outval = JS::NumberValue(*(unsigned short *)value);
            return JS_TRUE;
            
        case _C_USHT:  //     'S'
            *outval = JS::NumberValue(*(short *)value);
            return JS_TRUE;
            
        case _C_INT:  //      'i'
            *outval = JS::NumberValue(*(int *)value);
            return JS_TRUE;
            
        case _C_UINT:  //     'I'
            *outval = JS::NumberValue(*(unsigned int *)value);
            return JS_TRUE;
            
        case _C_LNG:  //      'l'
            *outval = JS::detail::MakeNumberValue<true>::create(*(long *)value);
            return JS_TRUE;
            
        case _C_ULNG:  //     'L'
            *outval = JS::detail::MakeNumberValue<false>::create(*(unsigned long *)value);
            return JS_TRUE;
            
        case _C_LNG_LNG:  //  'q'
            *outval = JS::detail::MakeNumberValue<true>::create(*(long long *)value);
            return JS_TRUE;
            
        case _C_ULNG_LNG:  // 'Q'
            *outval = JS::detail::MakeNumberValue<false>::create(*(unsigned long long *)value);
            return JS_TRUE;
            
        case _C_FLT:  //      'f'
            *outval = JS::NumberValue(*(float *)value);
            return JS_TRUE;
            
        case _C_DBL:  //      'd'
            *outval = JS::NumberValue(*(double *)value);
            return JS_TRUE;
            
        case _C_CONST:  //    'r'
            XWLOG(@"ignore encode modifier 'r' (const) for type %s", encode);
            return XJSValueFromType(cx, encode+1, value, outval);
            
        case _C_STRUCT_B:  // '{'
            // TODO support struct
            
            
            // unsuportted type
        case _C_UNION_B:  //  '('   support union??
        case _C_ARY_B:  //    '['   support array??
        case _C_PTR:  //      '^'   support pointer??
            
            // WTF
        case _C_BFLD:  //     'b'
        case _C_VECTOR:  //   '!'
        case _C_ATOM:  //     '%'
        case _C_VOID:  //     'v'
        case _C_UNDEF:  //    '?'
        case _C_STRUCT_E:  // '}'
        case _C_UNION_E:  //  ')'
        case _C_ARY_E:  //    ']'
        default:
            XWLOG(@"unsouportted type %s", encode);
            return JS_FALSE;
    }
}