
#ifndef __XSchema_NSString_XML_H__
#define __XSchema_NSString_XML_H__

#import <Foundation/NSString.h>

// e.g. self = "{http://my.server.com/namespace/uri}string"

@interface NSString(XML)

- (NSString *)uriFromQName;
- (NSString *)valueFromQName;
+ (NSString *)qNameWithUri:(NSString *)_uri andValue:(NSString *)_value;

@end /* NSString(XML) */

#endif /* __XSchema_NSString_XML_H__ */
