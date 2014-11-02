//
//  XJSLoggerTests.mm
//  XJSBinding
//
//  Created by Xiliang Chen on 13-12-10.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <vector>

#include <XLCUtils/XLCUtils.h>

#include "XJSLogger.hh"
#include "XJSContext_Private.hh"
#include "XJSValue_Private.hh"

@interface XJSLoggerTests : XCTestCase <DDLogger>

@end

struct LoggerItem {
    NSUInteger level;
    NSString *func;
    NSString *file;
    int lineno;
    NSString *message;
};

@implementation XJSLoggerTests
{
    XJSValue *_logger;
    XJSContext *_context;
    
    std::vector<LoggerItem> _logs;
}

- (void)setUp
{
    [super setUp];
    
    _context = [[XJSContext alloc] init];
    
    _logger = [[XJSValue alloc] initWithContext:_context
                                          value:JS::ObjectOrNullValue(XJSCreateLogger(_context.context))];
    
    _context[@"log"] = _logger;
    
    
    [DDLog addLogger:self];
}

- (void)tearDown
{
    [DDLog removeLogger:self];
    
    [super tearDown];
}

- (void)logMessage:(DDLogMessage *)logMessage
{
    _logs.push_back({logMessage->logFlag,
        logMessage->function ? @(logMessage->function) : nil,
        @(logMessage->file),
        logMessage->lineNumber,
        logMessage->logMsg});
}

- (id <DDLogFormatter>)logFormatter { return nil; }
- (void)setLogFormatter:(id <DDLogFormatter>)formatter {}

- (void)testCreate
{
    XCTAssertTrue(_logger.isCallable);
    XCTAssertTrue(_logger[@"debug"].isCallable);
    XCTAssertTrue(_logger[@"info"].isCallable);
    XCTAssertTrue(_logger[@"warn"].isCallable);
    XCTAssertTrue(_logger[@"error"].isCallable);
}

- (void)testCallLog
{
    [_context evaluateString:@"\n\na=function(){log(1)};b={c:function(){a()}};b.c();"
                    fileName:@"test"
                  lineNumber:1
                       error:NULL];
    
    XCTAssertEqual(_logs.size(), 1u);
    
    auto item = _logs[0];
    XCTAssertEqual(item.level, LOG_FLAG_INFO);
    XCTAssertEqualObjects(item.func, @"a");
    XCTAssertEqual(item.lineno, 3);
    XCTAssertEqualObjects(item.message, @"1");
}

- (void)testCallLogDebug
{
    [_context evaluateString:@"\n\na=function(){log.debug(1)};b={c:function(){a()}};b.c();"
                    fileName:@"test"
                  lineNumber:1
                       error:NULL];
    
    XCTAssertEqual(_logs.size(), (size_t)1);
    
    auto item = _logs[0];
    XCTAssertEqual(item.level, LOG_FLAG_DEBUG);
    XCTAssertEqualObjects(item.func, @"a");
    XCTAssertEqual(item.lineno, 3);
    XCTAssertEqualObjects(item.message, @"1");
}

- (void)testCallLogInfo
{
    [_context evaluateString:@"\n\na=function(){log.info(1)};b={c:function(){a()}};b.c();"
                    fileName:@"test"
                  lineNumber:1
                       error:NULL];
    
    XCTAssertEqual(_logs.size(), (size_t)1);
    
    auto item = _logs[0];
    XCTAssertEqual(item.level, LOG_FLAG_INFO);
    XCTAssertEqualObjects(item.func, @"a");
    XCTAssertEqual(item.lineno, 3);
    XCTAssertEqualObjects(item.message, @"1");
}

- (void)testCallLogWarn
{
    [_context evaluateString:@"\n\na=function(){log.warn(1)};b={c:function(){a()}};b.c();"
                    fileName:@"test"
                  lineNumber:1
                       error:NULL];
    
    XCTAssertEqual(_logs.size(), (size_t)1);
    
    auto item = _logs[0];
    XCTAssertEqual(item.level, LOG_FLAG_WARN);
    XCTAssertEqualObjects(item.func, @"a");
    XCTAssertEqual(item.lineno, 3);
    XCTAssertEqualObjects(item.message, @"1");
}

- (void)testCallLogError
{
    [_context evaluateString:@"\n\na=function(){log.error(1)};b={c:function(){a()}};b.c();"
                    fileName:@"test"
                  lineNumber:1
                       error:NULL];
    
    XCTAssertEqual(_logs.size(), (size_t)1);
    
    auto item = _logs[0];
    XCTAssertEqual(item.level, LOG_FLAG_ERROR);
    XCTAssertEqualObjects(item.func, @"a");
    XCTAssertEqual(item.lineno, 3);
    XCTAssertEqualObjects(item.message, @"1");
}

- (void)testLogMultipleItems
{
    [_context evaluateString:@"\n\na=function(){log(1, 2, 'test')};b={c:function(){a()}};b.c();"
                    fileName:@"test"
                  lineNumber:1
                       error:NULL];
    
    [_context evaluateString:@"\n\nfunction test(){log(1, 2, 'test')};test();"
                    fileName:@"test2"
                  lineNumber:1
                       error:NULL];
    
    XCTAssertEqual(_logs.size(), (size_t)2);
    
    auto item = _logs[0];
    XCTAssertEqual(item.level, LOG_FLAG_INFO);
    XCTAssertEqualObjects(item.func, @"a");
    XCTAssertEqualObjects(item.file, @"test");
    XCTAssertEqual(item.lineno, 3);
    XCTAssertEqualObjects(item.message, @"1 2 test");
    
    item = _logs[1];
    XCTAssertEqual(item.level, LOG_FLAG_INFO);
    XCTAssertEqualObjects(item.func, @"test");
    XCTAssertEqualObjects(item.file, @"test2");
    XCTAssertEqual(item.lineno, 3);
    XCTAssertEqualObjects(item.message, @"1 2 test");
}

- (void)testLogNoFunction
{
    [_context evaluateString:@"log(1)"
                    fileName:@"test"
                  lineNumber:1
                       error:NULL];
    
    XCTAssertEqual(_logs.size(), (size_t)1);
    
    auto item = _logs[0];
    XCTAssertEqual(item.level, LOG_FLAG_INFO);
    XCTAssertEqualObjects(item.func, @"(unknown)");
    XCTAssertEqualObjects(item.file, @"test");
    XCTAssertEqual(item.lineno, 1);
    XCTAssertEqualObjects(item.message, @"1");
}

- (void)testLogNoFunctionNoFile
{
    [_context evaluateString:@"log(1)"
                       error:NULL];
    
    XCTAssertEqual(_logs.size(), (size_t)1);
    
    auto item = _logs[0];
    XCTAssertEqual(item.level, LOG_FLAG_INFO);
    XCTAssertEqualObjects(item.func, @"(unknown)");
    XCTAssertEqual(item.lineno, 0);
    XCTAssertEqualObjects(item.message, @"1");
}

@end
