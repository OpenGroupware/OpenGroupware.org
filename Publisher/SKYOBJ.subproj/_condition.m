/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#include "SkyPubSKYOBJ.h"
#include "common.h"
#include "PubKeyValueCoding.h"
#include <DOM/EDOM.h>

@interface SkyPubSKYOBJNodeRenderer(Unsupp)
- (void)addUnsupportedNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;
@end

@implementation SkyPubSKYOBJNodeRenderer(Condition)

- (BOOL)_isUnaryCondition:(NSString *)_type node:(id)_node
  inContext:(WOContext *)_ctx
{
  NSString *tmp;
  id       value;
  
  if ((tmp = [self stringFor:@"value" node:_node ctx:_ctx]))
    value = tmp;
  else if ((tmp = [self stringFor:@"name" node:_node ctx:_ctx]))
    value = [self contextValueWithName:tmp inContext:_ctx];
  else
    value = @"";
  
  value = [self npsStringifyValue:value inContext:_ctx];
  
  if ([_type isEqualToString:@"isEmpty"] || [_type isEqualToString:@"isNil"]) {
    return [value isEqualToString:@""];
  }
  else if ([_type isEqualToString:@"isNotEmpty"] ||
           [_type isEqualToString:@"isNotNil"]) {
    return ![value isEqualToString:@""];
  }
  else
    NSLog(@"%s: unsupported unary condition: '%@'", __PRETTY_FUNCTION__,_node);
  
  return NO;
}

- (BOOL)_isBinaryCondition:(NSString *)_type node:(id)_node
  inContext:(WOContext *)_ctx
{
  NSString *tmp;
  id       value1, value2;
  
  if ((tmp = [self stringFor:@"value1" node:_node ctx:_ctx]))
    value1 = tmp;
  else if ((tmp = [self stringFor:@"name1" node:_node ctx:_ctx]))
    value1 = [self contextValueWithName:tmp inContext:_ctx];
  else
    value1 = @"";
  
  
  if ((tmp = [self stringFor:@"value2" node:_node ctx:_ctx]))
    value2 = tmp;
  else if ((tmp = [self stringFor:@"name2" node:_node ctx:_ctx]))
    value2 = [self contextValueWithName:tmp inContext:_ctx];
  else
    value2 = @"";
  
  value1 = [self npsStringifyValue:value1 inContext:_ctx];
  value2 = [self npsStringifyValue:value2 inContext:_ctx];

  // NSLog(@"%@ on %@ and %@", _type, value1, value2);
  
  if ([_type isEqualToString:@"isEqual"])
    return [value1 isEqual:value2];
  else if ([_type isEqualToString:@"isNotEqual"])
    return ![value1 isEqual:value2];
  else if ([_type isEqualToString:@"hasPrefix"])
    return [(NSString *)value1 hasPrefix:value2];
  else if ([_type isEqualToString:@"hasSuffix"])
    return [value1 hasSuffix:value2];
  else if ([_type isEqualToString:@"isCaseEqual"]) {
    value1 = [value1 lowercaseString];
    value2 = [value2 lowercaseString];
    return [value1 hasSuffix:value2];
  }
  else {
    NSLog(@"%s: unsupported binary condition: '%@'",
          __PRETTY_FUNCTION__, _node);
  }
  
  return NO;
}

- (void)_appendConditionNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  static NSMutableSet *unary = nil;
  NSString *condType;
  BOOL     negate, ok;

  if (![_node hasChildNodes])
    return;
  
  ok     = NO;
  negate = [[_node attribute:@"negate"] isEqualToString:@"yes"];
  if (!negate) negate = [[_node attribute:@"negate"] boolValue];
  
  if (unary == nil) {
    unary = [[NSMutableSet alloc] initWithObjects:
                                    @"isEmpty", @"isNotEmpty",
                                    @"isNil", @"isNotNil",
                                    nil];
  }
  
  condType = [self stringFor:@"condition" node:_node ctx:_ctx];
  
  ok = ([unary containsObject:condType])
    ? [self _isUnaryCondition:condType  node:_node inContext:_ctx]
    : [self _isBinaryCondition:condType node:_node inContext:_ctx];
  
  if (negate) ok = !ok;
  
  if (ok) {
    [self appendChildNodes:[_node childNodes]
          toResponse:_response
          inContext:_ctx];
  }
}

@end /* SkyPubSKYOBJNodeRenderer(Condition) */

