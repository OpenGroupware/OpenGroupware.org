
#include "NSString+XML.h"
#include "common.h"

// e.g. self = "{http://my.server.com/namespace/uri}string"

@implementation NSString(XML)

- (NSString *)uriFromQName {
  NSUInteger idx;

  if (![self hasPrefix:@"{"])
    return nil;
  else if (((idx = [self indexOfString:@"}"]) == NSNotFound))
    return nil;
  else
    return [self substringWithRange:NSMakeRange(1,idx-1)];
}
- (NSString *)valueFromQName {
  NSUInteger idx;

  return (((idx = [self indexOfString:@"}"]) == NSNotFound))
    ? self
    : [self substringFromIndex:idx+1];
}

+ (NSString *)qNameWithUri:(NSString *)_uri andValue:(NSString *)_value {
  NSString *str;

  str = [NSString stringWithFormat:@"{%@}%@", _uri, _value];

  return str;
}

@end /* NSString(Xml) */
