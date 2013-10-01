//
//  XJSHelperFunctions.h
//  XJSBinding
//
//  Created by Xiliang Chen on 13-9-30.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

/** 
 * Try to match selector with given name and number of arguments that colons in selector are replaced by underscores.
 * Ending underscore are optional. But when end with underscores make sure number of ending underscores matches to number of ending colons.
 * obj always response to returned selector.
 *
 * Will not work with
 *      1. a selector contain underscore after first colon. e.g. "method_with_argument" with 2 arguments only match to match @selector(method_with:argument:) not @selector(method:with_argument:). OR
 *      2. need replace leading underscore to colon. e.g. "_test" with 2 arguments only match to @selector(_test::) not @selector(:test:). OR
 *      3. contain underscore and more than one ending colon. e.g. "my_method" with 2 arguments only match to @selector(my:method:) not @selector(my_method::). OR
 *      4. many other nonsense but compilable selector name. e.g. You want match "method__with__many__underscores" with 4 arguments to @selector(method:_with:_many:_underscores:) ? Sorry about that.
 * Read code for detail rules. But as long as standard Objective-C selector naming conversion is used it should be good.
 */
SEL XJSSearchSelector(id obj, const char *selname, unsigned argc);