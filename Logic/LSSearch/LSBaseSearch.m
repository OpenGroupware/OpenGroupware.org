/*
  Copyright (C) 2000-2005 SKYRIX Software AG

  This file is part of OpenGroupware.org.

  OGo is free software; you can redistribute it and/or modify it under
  the terms of the GNU Lesser General Public License as published by the
  Free Software Foundation; either version 2, or (at your option) any
  later version.

  OGo is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
  License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with OGo; see the file COPYING.  If not, write to the
  Free Software Foundation, 59 Temple Place - Suite 330, Boston, MA
  02111-1307, USA.
*/

#include "LSBaseSearch.h"
#include "common.h"

@interface LSBaseSearch(PrivateMethodes)
- (void)_appendComparatorAndString:(NSString *)_value
  withAttribute:(EOAttribute *)_attr
  isTextValue:(BOOL)_isTextValue
  toFormat:(NSMutableString *)_format;
@end

@implementation LSBaseSearch

+ (int)version {
  return 1;
}

- (void)dealloc {
  [self->dbAdaptor  release];
  [self->comparator release];
  [super dealloc];
}

/* operation */

- (NSString *)_formatForStringValue:(id)_value {
  return [_value lowercaseString];
}

- (NSString *)_formatForNumberValue:(id)_value {
  NSString *val = [_value stringValue];
  /*
   * remove quotes, since number values, cannot contain quotes
   * mh: this prevents core dumps, if thinks like "'quote'" are
   *     searched in a full search
   *
   */
  if ([val rangeOfString:@"'"].length > 0) {
#if LIB_FOUNDATION_LIBRARY || GNUSTEP_BASE_LIBRARY
    val = [val stringByReplacingString:@"'" withString:@""];
#else
#  warning FIXME: incorrect implementation for this Foundation library!
#endif
  }
  return val;
}

- (NSString *)_formatForTextAttribute:(EOAttribute *)_attr
  andValue:(id)_value
{
  return [self _formatForTextAttribute:_attr andValue:_value entity:nil];
}

- (NSString *)_formatForTextAttribute:(EOAttribute *)_attr
  andValue:(id)_value entity:(EOEntity *)_entity
{
  NSMutableString *attrName;
  NSMutableString *format;

  format   = [NSMutableString stringWithCapacity:32];
  attrName = [NSMutableString stringWithCapacity:64];
  
  if (![[[_attr entity] name] isEqualToString:[[self entity] name]]) {
    if (_entity) {
      [attrName appendString:@"to"];
      [attrName appendString:[_entity name]];
      [attrName appendString:@"."];
    }
    [attrName appendString:@"to"];
    [attrName appendString:[[_attr entity] name]];
    [attrName appendString:@"."];  
  }
  [attrName appendString:[_attr name]];

  if (attrName == nil) {
    NSLog(@"WARNING(%s:%i): missing name for attribute %@",
          __PRETTY_FUNCTION__, __LINE__, _attr);
  }
  
  [format appendString:[[self dbAdaptor]
                              lowerExpressionForTextAttributeNamed:attrName]];

  [self _appendComparatorAndString:_value
        withAttribute:_attr
        isTextValue:YES
        toFormat:format];

  return format;
}

- (NSString *)_formatForStringAttribute:(EOAttribute *)_attr andValue:(id)_v {
  return [self _formatForStringAttribute:_attr andValue:_v entity:nil];
}

- (NSString *)_formatForStringAttribute:(EOAttribute *)_attr
  andValue:(id)_value entity:(EOEntity *)_entity 
{
  NSMutableString *format;

  format = [NSMutableString stringWithCapacity:32];
  
  [format appendString:@"LOWER("];
  
  if (![[[_attr entity] name] isEqualToString:[[self entity] name]]) {
    if (_entity) {
      [format appendString:@"to"];
      [format appendString:[_entity name]];
      [format appendString:@"."];
    }
    [format appendString:@"to"];
    [format appendString:[[_attr entity] name]];
    [format appendString:@"."];  
  }
  [format appendString:[_attr name]];
  [format appendString:@")"];

  [self _appendComparatorAndString:_value
        withAttribute:_attr
        isTextValue:NO
        toFormat:format];
  
  return format;
}

- (NSString *)_formatForNumberAttribute:(EOAttribute *)_attr andValue:(id)_v {
  return [self _formatForNumberAttribute:_attr andValue:_v entity:nil];
}

- (NSString *)_formatForNumberAttribute:(EOAttribute *)_attr
  andValue:(id)_value
  entity:(EOEntity *)_entity
{
  NSMutableString *format = nil;

  format = [NSMutableString stringWithCapacity:32];

  if (![[[_attr entity] name] isEqualToString:[[self entity] name]]) {
    NSMutableString *attrName = nil;

    attrName = [NSMutableString stringWithCapacity:64];
    
    if (_entity) {
      [attrName appendString:@"to"];
      [attrName appendString:[_entity name]];
      [attrName appendString:@"."];
    }
    [attrName appendString:@"to"];
    [attrName appendString:[[_attr entity] name]];
    [attrName appendString:@"."];
    [attrName appendString:[_attr name]];
    
    if (attrName == nil) {
      NSLog(@"WARNING(%s:%i): missing name for attribute %@",
            __PRETTY_FUNCTION__, __LINE__, _attr);
    }
    
    [format appendString:
              [[self dbAdaptor]
                     charConvertExpressionForAttributeNamed:attrName]];
  }
  else {
    if ([_attr name] == nil) {
      NSLog(@"WARNING(%s:%i): missing name for attribute %@",
            __PRETTY_FUNCTION__, __LINE__, _attr);
    }
    
    [format appendString:
              [[self dbAdaptor]
                     charConvertExpressionForAttributeNamed:[_attr name]]];
  }
  
  [format appendString:@" LIKE '%%"];
  [format appendString:[self _formatForNumberValue:_value]];
  [format appendString:@"%%' "];

  return format;
}

- (void)setDbAdaptor:(EOAdaptor *)_adaptor {
  ASSIGN(self->dbAdaptor, _adaptor);
}
- (EOAdaptor *)dbAdaptor {
  return self->dbAdaptor;
}

- (void)setComparator:(NSString *)_comparator {
  ASSIGNCOPY(self->comparator, _comparator);
}
- (NSString *)comparator {
  return self->comparator;
}

@end /* LSBaseSearch */

@implementation LSBaseSearch(PrivateMethodes)

- (void)_appendComparatorAndString:(NSString *)_value
  withAttribute:(EOAttribute *)_attr
  isTextValue:(BOOL)_isTextValue
  toFormat:(NSMutableString *)_format
{
  BOOL     hasPrefix = YES;
  BOOL     hasSuffix = YES;
  NSString *val      = nil;

  val = [[_value copy] autorelease];
  
  [_format appendString:@" "];

  if ([self->comparator isEqualToString:@"LIKE"]) {
    int cnt = 0;
    
    hasPrefix = [val hasPrefix:@"*"];
    hasSuffix = [val hasSuffix:@"*"];

    if (hasPrefix) cnt++;
    if (hasSuffix) cnt++;

    if ([val length] < cnt) {
      val = @"";
      if (hasSuffix || hasPrefix) {
        hasPrefix = YES;
        hasSuffix = NO;
      }
    }
    if (hasPrefix && [val length] > 1)
      val = [val substringWithRange:NSMakeRange(1, [val length]-1)];
    if (hasSuffix && [val length] > 1)
      val = [val substringWithRange:NSMakeRange(0,  [val length]-1)];

    [_format appendString:@"LIKE"];
  }
  else if ([self->comparator isEqualToString:@"EQUAL"]) {
    hasPrefix = NO;
    [_format appendString:@"="];
    hasSuffix = NO;
  }
  else
    [_format appendString:@"LIKE"];

  [_format appendString:@" "];

#if LIB_FOUNDATION_LIBRARY || GNUSTEP_BASE_LIBRARY
  if ([val rangeOfString:@"*"].length > 0)
    val = [val stringByReplacingString:@"*" withString:@"%%"];
#else
#  warning FIXME: incorrect implementation for this Foundation library!
#endif

  if (hasPrefix)
    val = [@"%%" stringByAppendingString:val];
  
  if (hasSuffix)
    val = [val stringByAppendingString:@"%%"];

#if 0  
  [_format appendString:(_isTextValue)
           ? [[self dbAdaptor] expressionForTextValue:val]
           : [self->dbAdaptor formatValue:[self _formatForStringValue:val]
                  forAttribute:_attr]];                  
#else
  [_format appendString:[self->dbAdaptor formatValue:
                             [self _formatForStringValue:val]
                             forAttribute:_attr]];
#endif
                  

  [_format appendString:@" "];
}

@end /* LSBaseSearch(PrivateMethodes) */
