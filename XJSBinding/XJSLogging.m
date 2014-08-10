//
//  XJSLogging.m
//  XJSBinding
//
//  Created by Xiliang Chen on 14/8/10.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import "XJSLogging_Private.h"

XLCLogger *XJSGetLogger() {
    static XLCLogger *logger;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [XLCLogger loggerWithName:@"XJSBinding"];
    });
    return logger;
}