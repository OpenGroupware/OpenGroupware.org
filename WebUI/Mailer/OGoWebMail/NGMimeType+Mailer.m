// $Id$

#include <NGMime/NGMimeType.h>
#include "common.h"

@implementation NGMimeType(OGoWebMail)

- (BOOL)isTextType {
  return [[self type] isEqualToString:@"text"] ? YES : NO;
}

- (BOOL)isTextPlainType {
  if (![[self subType] isEqualToString:@"plain"])
    return NO;
  if (![self isTextType])
    return NO;
  
  return YES;
}

- (BOOL)isTextHtmlType {
  if (![[self subType] isEqualToString:@"html"])
    return NO;
  if (![self isTextType])
    return NO;
  
  return YES;
}

@end /* NGMimeType(OGoWebMail) */
