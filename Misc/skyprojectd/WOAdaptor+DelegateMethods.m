// $Id$

#include "common.h"

@implementation WOAdaptor(DelegateMethods)

- (BOOL)parser:(id)_parser parseRawBodyData:(NSData *)_data ofPart:_part {
  if ([[_part contentType] isCompositeType])
    return NO;
  
  [_part setBody:_data];
  return YES;
}

@end /* WOAdaptor(DelegateMethods) */
