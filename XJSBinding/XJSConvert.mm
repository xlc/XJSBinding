//
//  XJSConvert.m
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-10.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSConvert.hh"

#import <objc/runtime.h>

#import "XLCAssertion.h"

#import "NSObject+XJSValueConvert.h"
#import "XJSValue_Private.hh"
#import "XJSContext_Private.hh"
#import "XJSClass.hh"
#import "XJSStructMetadata.h"

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


static NSValue * XJSValueToStruct(JSContext *cx, jsval val, const char *encode)
{
    if (val.isPrimitive()) {
        return nil;
    }
    
    JSObject *obj = val.toObjectOrNull();
    if (!obj) {
        return nil;
    }
    
    auto data = [XJSStructMetadata metadataForEncoding:@(encode)];
    if (!data) {
        return nil;
    }
    
    NSUInteger size;
    auto encode2 = NSGetSizeAndAlignment(encode, &size, NULL);
    XASSERT(encode2[0] == '\0', @"encode should only contain one type");
    
    alignas(sizeof(NSInteger)) char buff[size];
    bzero(buff, size);
    
    for (XJSStructField *field in data.fields) {
        JSBool success;
        JS::RootedValue outval(cx);
        
        success = JS_GetProperty(cx, obj, [field.name UTF8String], &outval);
        if (!success) {
            return nil;
        }
        
        void *ptr = buff + field.offset;
        auto fieldval = XJSValueToType(cx, outval, [field.encoding UTF8String]);
        if (fieldval.second) {
            *(__unsafe_unretained id *)ptr = fieldval.second;
        } else if (fieldval.first) {
            [fieldval.first getValue:ptr];
        } else {
            return nil;
        }
    }
    
    return [NSValue valueWithBytes:buff objCType:encode];
}

static JSBool XJSValueFromStruct(JSContext *cx, const char *encode, void *value, JS::MutableHandleValue outval)
{
    auto data = [XJSStructMetadata metadataForEncoding:@(encode)];
    if (!data) {
        return nil;
    }
    
    JSObject *obj = JS_NewObject(cx, NULL, NULL, NULL);
    
    for (XJSStructField *field in data.fields) {
        JSBool success;
        JS::RootedValue fieldval(cx);
        
        success = XJSValueFromType(cx, [field.encoding UTF8String], (char *)value + field.offset, &fieldval);
        if (!success) {
            return JS_FALSE;
        }
        
        success = JS_SetProperty(cx, obj, [field.name UTF8String], fieldval);
        if (!success) {
            return JS_FALSE;
        }
    }
    
    outval.set(JS::ObjectOrNullValue(obj));
    
    return JS_TRUE;
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
            if (encode[1] == _C_CHARPTR) {  // const char *
                return MakePair(encode, size, [XJSConvertJSValueToString(cx, val) UTF8String]);
            }
            XWLOG(@"ignore encode modifier 'r' (const) for type %s", encode);
            return XJSValueToType(cx, val, encode+1);
            
        case _C_STRUCT_B:  // '{'
            return { XJSValueToStruct(cx, val, encode), nil };
            
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

JSBool XJSValueFromType(JSContext *cx, const char *encode, void *value, JS::MutableHandleValue outval)
{
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
            outval.set(XJSToValue([XJSContext contextForJSContext:cx], obj).value);
            return JS_TRUE;
        }
            
        case _C_SEL:  //      ':'
            outval.set(JS::StringValue(JS_NewStringCopyZ(cx, sel_getName(*(SEL *)value))));
            return JS_TRUE;
            
        case _C_CHARPTR:  //  '*'
            outval.set(JS::StringValue(JS_NewStringCopyZ(cx, *(const char **)value)));
            return JS_TRUE;
            
        case _C_BOOL:  //     'B'
            outval.set(JS::BooleanValue(*(bool *)value));
            return JS_TRUE;
            
        case _C_CHR:  //      'c'
        {
            char val = *(char *)value;
            if (val == YES) {
                outval.set(JSVAL_TRUE);
                return JS_TRUE;
            } else if (val == NO) {
                outval.set(JSVAL_FALSE);
                return JS_TRUE;
            } else {
                outval.set(JS::NumberValue(*(unsigned char *)value));
                return JS_TRUE;
            }
        }
            
        case _C_UCHR:  //     'C'
            outval.set(JS::Int32Value(*(char *)value));
            return JS_TRUE;
            
        case _C_SHT:  //      's'
            outval.set(JS::NumberValue(*(unsigned short *)value));
            return JS_TRUE;
            
        case _C_USHT:  //     'S'
            outval.set(JS::NumberValue(*(short *)value));
            return JS_TRUE;
            
        case _C_INT:  //      'i'
            outval.set(JS::NumberValue(*(int *)value));
            return JS_TRUE;
            
        case _C_UINT:  //     'I'
            outval.set(JS::NumberValue(*(unsigned int *)value));
            return JS_TRUE;
            
        case _C_LNG:  //      'l'
            outval.set(JS::detail::MakeNumberValue<true>::create(*(long *)value));
            return JS_TRUE;
            
        case _C_ULNG:  //     'L'
            outval.set(JS::detail::MakeNumberValue<false>::create(*(unsigned long *)value));
            return JS_TRUE;
            
        case _C_LNG_LNG:  //  'q'
            outval.set(JS::detail::MakeNumberValue<true>::create(*(long long *)value));
            return JS_TRUE;
            
        case _C_ULNG_LNG:  // 'Q'
            outval.set(JS::detail::MakeNumberValue<false>::create(*(unsigned long long *)value));
            return JS_TRUE;
            
        case _C_FLT:  //      'f'
            outval.set(JS::NumberValue(*(float *)value));
            return JS_TRUE;
            
        case _C_DBL:  //      'd'
            outval.set(JS::NumberValue(*(double *)value));
            return JS_TRUE;
            
        case _C_CONST:  //    'r'
            if (encode[1] == _C_CHARPTR) {  // const char *
                outval.set(JS::StringValue(JS_NewStringCopyZ(cx, *(const char **)value)));
                return JS_TRUE;
            }
            XWLOG(@"ignore encode modifier 'r' (const) for type %s", encode);
            return XJSValueFromType(cx, encode+1, value, outval);
            
        case _C_STRUCT_B:  // '{'
            return XJSValueFromStruct(cx, encode, value, outval);
            
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