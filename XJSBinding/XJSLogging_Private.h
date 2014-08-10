//
//  XJSLogging.h
//  XJSBinding
//
//  Created by Xiliang Chen on 14/8/10.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <XLCUtils/XLCLogging.h>

__BEGIN_DECLS

XLCLogger *XJSGetLogger();

__END_DECLS

#define XJSLogError(format...) XLCLogError2(XJSGetLogger(), format)
#define XJSLogWarn(format...)  XLCLogWarn2(XJSGetLogger(), format)
#define XJSLogInfo(format...)  XLCLogInfo2(XJSGetLogger(), format)
#define XJSLogDebug(format...) XLCLogDebug2(XJSGetLogger(), format)