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

#include "ODR_sky_selectpopup.h"
#include "common.h"

@implementation ODR_sky_selectpopup

- (BOOL)requiresFormForNode:(id)_domNode inContext:(WOContext *)_ctx {
  return YES;
}

- (id)_objectsForNode:(id)_node inContext:(WOContext *)_ctx {
  return [self subclassResponsibility:_cmd];
}
- (NSString *)_urlForObject:(id)_object {
  return [self subclassResponsibility:_cmd];
}
- (NSString *)_labelForObject:(id)_object forNode:(id)_node
  inContext:(WOContext *)_ctx
{
  return [self subclassResponsibility:_cmd];
}

- (void)takeValuesForNode:(id)_node
  fromRequest:(WORequest *)_req
  inContext:(WOContext *)_ctx
{
  NSString *formValue;
  NSString *name;
  
  name = [self stringFor:@"name" node:_node ctx:_ctx];
  name = (name) ? name : [_ctx elementID];
  
  formValue = [_req formValueForKey:name];
  if ([formValue length] == 0)
    formValue = nil;
  if ([formValue isEqualToString:@"$"])
    formValue = nil;
  
  if ([self isSettable:@"url" node:_node ctx:_ctx])
    [self setValue:formValue for:@"url" node:_node ctx:_ctx];
}

- (void)_appendDisabledNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  /* default implementation: print label of selection ... */
  NSArray  *objs;
  unsigned i, count;
  NSString *selectedurl;
  
  selectedurl = [self stringFor:@"url" node:_node ctx:_ctx];

  if ([selectedurl length] == 0) {
    /* nothing is selected */
    [_response appendContentString:@"&nbsp;"];
    return;
  }
  
  objs  = [self _objectsForNode:_node inContext:_ctx];
  
  for (i = 0, count = [objs count]; i < count; i++) {
    id       object;
    NSString *url;
      
    object = [objs objectAtIndex:i];
      
    if ((url = [self _urlForObject:object]) == nil)
      continue;

    if ([url isEqualToString:selectedurl]) {
      /* found selection */
      NSString *label;
      
      label = [self _labelForObject:object forNode:_node inContext:_ctx];
      if (label == nil)
        label = [url lastPathComponent];
      
      [_response appendContentHTMLString:label];
      return;
    }
  }
  /* found no object matching selected URL .. */
  [_response appendContentString:@"&nbsp;"];
  return;
}

- (void)appendNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString *name;
  NSString *nilStr;
  
  if ([self boolFor:@"disabled" node:_node ctx:_ctx]) {
    [self _appendDisabledNode:_node toResponse:_response inContext:_ctx];
    return;
  }
  
  name = [self stringFor:@"name" node:_node ctx:_ctx];
  name = (name) ? name : [_ctx elementID];
  
  [_response appendContentString:@"<select name=\""];
  [_response appendContentHTMLAttributeValue:name];
  [_response appendContentString:@"\">\n"];
  
  if ((nilStr = [self stringFor:@"noselectionstring" node:_node ctx:_ctx])) {
    [_response appendContentString:@"  <option value=\"$\">"];
    [_response appendContentHTMLString:nilStr];
    [_response appendContentString:@"\n"];
  }
  
  /* fetch objects */
  {
    NSArray    *objs;
    unsigned   i, count;
    NSString   *selectedurl;
    
    selectedurl = [self stringFor:@"url" node:_node ctx:_ctx];
    
    objs  = [self _objectsForNode:_node inContext:_ctx];
    
    for (i = 0, count = [objs count]; i < count; i++) {
      id       object;
      NSString *url;
      NSString *label;
      
      object = [objs objectAtIndex:i];
      
      if ((url = [self _urlForObject:object]) == nil)
        continue;
      
      label = [self _labelForObject:object forNode:_node inContext:_ctx];
      if (label == nil) {
#if DEBUG
        [[_ctx component]
               debugWithFormat:@"got no label for object '%@'",
                 object];
#endif
        label = [url lastPathComponent];
      }
      
      [_response appendContentString:@"<option value=\""];
      [_response appendContentString:url];
      [_response appendContentString:@"\""];
      
      if ([url isEqualToString:selectedurl])
        [_response appendContentString:@" selected>"];
      else
        [_response appendContentString:@">"];
      
      [_response appendContentHTMLString:label];
      [_response appendContentString:@"\n"];
    }
  }
  
  [_response appendContentString:@"</select>"];
}

@end /* ODR_sky_selectpopup */
