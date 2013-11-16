//
//  XJSInternalOperation.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-29.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

struct JSContext;

class XJSInternalOperation
{
    static NSCountedSet *set;
    
    NSValue *_val;
    
public:
    static bool IsInternalOepration(JSContext *cx)
    {
        if (!set) {
            return false;
        }
        @synchronized(set) {
            return [set countForObject:[NSValue valueWithPointer:cx]];
        }
    }
    
    XJSInternalOperation(JSContext *cx)
    :_val([NSValue valueWithPointer:cx])
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            set = [NSCountedSet set];
        });
        
        @synchronized(set) {
            [set addObject:_val];
        }
    }
    
    ~XJSInternalOperation()
    {
        @synchronized(set) {
            [set removeObject:_val];
        }
    }
};

